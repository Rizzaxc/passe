import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../core/feature_flags.dart';
import '../core/model/enum.dart';
import '../core/state/selected_sport_state.dart';
import '../core/timeslot_picker.dart';
import '../core/user_preferences.dart';
import '../ui/district_select.dart';
import '../ui/search_field.dart';
import '../ui/sheet.dart';
import '../ui/sport_picker.dart';
import 'filter_controller.dart';

export 'filter_controller.dart'
    show FilterData, filterIsActiveProvider, filterStateProvider;

/// Persisted "has anyone ever seen the filter-fields coach mark" flag —
/// shown once, the very first time [FilterSheet] opens for a user,
/// regardless of which subtab/entry point triggered it.
class _FilterCoachMarkPrefs {
  _FilterCoachMarkPrefs._();

  static const _key = 'FILTER_FIELDS_COACH_SEEN';

  static Future<bool> hasSeen() async =>
      await UserPreferences.instance.getBool(_key) ?? false;

  static Future<void> markSeen() => UserPreferences.instance.setBool(_key, true);
}

/// Opens the shared [FilterSheet]. Discover renders this once, under its
/// category rail, instead of a filter icon on every subtab's header.
void showFilterSheet(BuildContext context, {bool showRoleFilter = false}) {
  showPSheet(
    context: context,
    builder: (_) => FilterSheet(showRoleFilter: showRoleFilter),
  );
}

/// The always-visible filter state for Discover: the sport and city being
/// browsed, with a dot once anything else (wards, timeslots, search) differs
/// from the profile seed. Tapping opens the sheet.
class FilterSummaryChip extends ConsumerWidget {
  final bool showRoleFilter;

  const FilterSummaryChip({super.key, this.showRoleFilter = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(filterStateProvider);
    final active = ref.watch(filterIsActiveProvider);
    final sport = ref.watch(selectedSportStateProvider).value;
    final colors = context.theme.colors;

    // Sport + city only. Wards, timeslots and search are behind the dot:
    // spelling them all out overflowed the chip into an unreadable "…".
    final summary = [
      if (sport != null && sport != Sport.others)
        sport.getLocalizedName(context),
      filter.city.getLocalizedName(context),
    ].join(' · ');

    return Semantics(
      button: true,
      label: 'homeTab.filter.title'.tr(),
      child: FTappable(
        onPress: () => showFilterSheet(context, showRoleFilter: showRoleFilter),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: colors.secondary,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            spacing: 8,
            children: [
              // Discover is the only sport-scoped surface left, so the sport
              // leads the summary rather than hiding in a corner selector.
              if (sport != null && sport != Sport.others)
                sport.getIcon(size: 9)
              else
                Icon(
                  FLucideIcons.slidersHorizontal,
                  size: 16,
                  color: colors.secondaryForeground,
                ),
              Expanded(
                child: Text(
                  summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.theme.typography.body.sm.copyWith(
                    color: colors.secondaryForeground,
                    height: 1.0,
                  ),
                ),
              ),
              if (active)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              Icon(
                FLucideIcons.chevronDown,
                size: 16,
                color: colors.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Resets the filter to the profile seed. Hidden while there is nothing to
/// reset, so it never reads as a dead control.
class FilterResetButton extends ConsumerWidget {
  const FilterResetButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(filterIsActiveProvider)) return const SizedBox.shrink();
    return FButton(
      size: .sm,
      variant: .ghost,
      onPress: ref.read(filterStateProvider.notifier).reset,
      child: Text('homeTab.filter.reset'.tr()),
    );
  }
}

class _DistrictSelect extends StatelessWidget {
  final City city;
  final Set<District> selected;
  final void Function(Set<District>) onChanged;

  const _DistrictSelect({
    required this.city,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // 102-126 flat wards per city is too long to scroll — .searchBuilder adds
    // a search field, still grouped by legacy quận/huyện via districtSections.
    return FMultiSelect<District>.searchBuilder(
      // No inline label — the section label "Địa Điểm" above the
      // city + district pair already groups them. The district name is
      // surfaced as the empty-state placeholder instead.
      hint: Text(context.tr('homeTab.filter.district')),
      format: (d) => Text(d.getLocalizedFullName(context)),
      keepHint: false,
      control: FMultiValueControl.managed(
        initial: selected,
        onChange: onChanged,
      ),
      searchFieldProperties: districtSearchFieldProperties(context),
      contentEmptyBuilder: (context, _) => districtEmptyBuilder(context),
      filter: (query) =>
          VietnamLocationData.instance.searchDistricts(city, query),
      contentBuilder: (context, query, values) => districtSections<District>(
        context: context,
        values: values,
        toDistrict: (d) => d,
        isSelected: selected.contains,
      ),
    );
  }
}

class FilterSheet extends ConsumerStatefulWidget {
  final bool showRoleFilter;

  const FilterSheet({super.key, this.showRoleFilter = false});

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  late TextEditingController _searchController;
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;

  final _confirmKey = GlobalKey(debugLabel: 'filter.confirm');

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(filterStateProvider).search,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowCoachMark());
  }

  // Single hint over the confirm button rather than one per field — a full
  // per-field tour was more coach-mark than this sheet's three fairly
  // self-explanatory sections warranted.
  Future<void> _maybeShowCoachMark() async {
    if (await _FilterCoachMarkPrefs.hasSeen()) return;
    if (!mounted) return;

    final targets = [
      TargetFocus(
        identify: 'filter_confirm',
        keyTarget: _confirmKey,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        // Default (10) made the highlight box visibly bigger than the
        // button itself, spilling past its bottom edge.
        paddingFocus: 4,
        // The confirm button isn't a field a user needs to interact with
        // mid-tour, so a tap anywhere just finishes the tour either way.
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => Text(
              'homeTab.filter.coach.body'.tr(),
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    ];

    TutorialCoachMark(
      targets: targets,
      // A single-target tour has nothing to skip *to* — any tap already
      // finishes it (enableOverlayTab above) — so a separate Skip button is
      // redundant chrome, not a real choice.
      hideSkip: true,
      onFinish: () => _FilterCoachMarkPrefs.markSeen(),
    ).show(context: context);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Every keystroke used to refetch the active feed; wait for a pause.
  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) ref.read(filterStateProvider.notifier).setFilter(value);
    });
  }

  void _toastCapped(String key) {
    showFToast(
      context: context,
      icon: const Icon(FLucideIcons.info),
      title: Text(key.tr()),
      alignment: .bottomCenter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(filterStateProvider);
    final notifier = ref.read(filterStateProvider.notifier);

    // "Đặt lại" resets the provider, not this sheet's text field — pull the
    // field back in line, and drop any keystroke still waiting to apply.
    ref.listen(filterStateProvider.select((f) => f.search), (_, search) {
      if (search == _searchController.text) return;
      if (_searchDebounce?.isActive ?? false) return;
      _searchController.text = search;
    });
    ref.listen(filterIsActiveProvider, (_, active) {
      if (!active) {
        _searchDebounce?.cancel();
        _searchController.text = ref.read(filterStateProvider).search;
      }
    });

    return SingleChildScrollView(
      controller: _scrollController,
      primary: false,
      child: Column(
        spacing: 20,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PSheetTitle(
            label: 'homeTab.filter.title'.tr(),
            trailing: const FilterResetButton(),
          ),
          // Role section (professional subtab only). Each role is toggled
          // independently. While refereeing is iced there is only one role to
          // choose from, so the whole section is pointless — hide it.
          if (widget.showRoleFilter && ClientFeatureFlags.refereeFlow)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                PSheetSectionLabel(
                  label: context.tr('homeTab.professional.filter.role'),
                ),
                for (final role in ProfessionalRole.values)
                  FCheckbox(
                    label: Text(
                      switch (role) {
                        ProfessionalRole.coach =>
                          'homeTab.professional.filter.coach',
                        ProfessionalRole.referee =>
                          'homeTab.professional.filter.referee',
                      }.tr(),
                    ),
                    value: filter.visibleRoles.contains(role),
                    onChange: (visible) =>
                        notifier.setRoleVisible(role, visible),
                  ),
              ],
            ),

          // Sport. Discover is the one sport-scoped surface in the app; the
          // rest of the app shows every sport, so this is the only picker.
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              PSheetSectionLabel(label: context.tr('homeTab.filter.sport')),
              const _SportChoice(),
            ],
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PSheetSectionLabel(label: context.tr('homeTab.filter.search')),
              const SizedBox(height: 8),
              PSearchField(
                hint: context.tr('homeTab.filter.searchHint'),
                controller: _searchController,
                onChange: _onSearchChanged,
              ),
            ],
          ),

          // Location section
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PSheetSectionLabel(label: context.tr('homeTab.filter.location')),
              const SizedBox(height: 8),
              FSelect<City>.rich(
                hint: context.tr('homeTab.filter.city'),
                format: (city) => city.getLocalizedName(context),
                autoHide: true,
                control: FSelectControl.lifted(
                  value: filter.city,
                  onChange: (city) {
                    if (city != null) notifier.setCity(city);
                  },
                ),
                children: [
                  FSelectItem<City>(
                    title: Text(City.hochiminh.getLocalizedName(context)),
                    value: City.hochiminh,
                  ),
                  FSelectItem<City>(
                    title: Text(City.hanoi.getLocalizedName(context)),
                    value: City.hanoi,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _DistrictSelect(
                key: ValueKey(filter.city),
                city: filter.city,
                selected: filter.districts,
                onChanged: (districts) {
                  if (notifier.setDistricts(districts)) {
                    _toastCapped('homeTab.filter.districtCapped');
                  }
                },
              ),
            ],
          ),

          // Schedule section
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PSheetSectionLabel(label: context.tr('homeTab.filter.schedule')),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final fieldStyle =
                      context.theme.multiSelectStyle.fieldStyles.md;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: context.theme.colors.card,
                          border: Border.all(
                            color: context.theme.colors.border,
                            width: context.theme.style.borderWidth,
                          ),
                          borderRadius: context.theme.style.borderRadius.md,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                              10,
                              0,
                              8,
                              0,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: fieldStyle.spacing,
                                runSpacing: fieldStyle.runSpacing,
                                children: [
                                  if (filter.schedule.isEmpty)
                                    Padding(
                                      padding:
                                          const EdgeInsetsDirectional.fromSTEB(
                                            4,
                                            4,
                                            0,
                                            4,
                                          ),
                                      child: Text(
                                        context.tr('homeTab.filter.any'),
                                        style: context.theme.typography.body.sm
                                            .copyWith(
                                              color: context
                                                  .theme
                                                  .colors
                                                  .mutedForeground,
                                            ),
                                      ),
                                    ),
                                  for (final timeslot in filter.schedule)
                                    GestureDetector(
                                      onTap: () {
                                        final updated = [...filter.schedule];
                                        updated.remove(timeslot);
                                        notifier.setSchedule(updated);
                                      },
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          borderRadius: context
                                              .theme
                                              .style
                                              .borderRadius
                                              .md,
                                          color: context.theme.colors.secondary,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                            horizontal: 8,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            spacing: 4,
                                            children: [
                                              Text(
                                                '${timeslot.dayChunk.getShortName(context)} ${timeslot.dayOfWeek.getShortName(context)}',
                                                style: context
                                                    .theme
                                                    .typography
                                                    .body
                                                    .sm
                                                    .copyWith(
                                                      color: context
                                                          .theme
                                                          .colors
                                                          .secondaryForeground,
                                                    ),
                                              ),
                                              IconTheme(
                                                data: IconThemeData(
                                                  color: context
                                                      .theme
                                                      .colors
                                                      .mutedForeground,
                                                  size: 15,
                                                ),
                                                child: const Icon(
                                                  FLucideIcons.x,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              // Same gap the Location section uses between its city
              // and district fields, so the add-button visually
              // separates from the selected-timeslot chip strip
              // above it.
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FButton(
                  variant: .outline,
                  onPress: () async {
                    final timeslot = await showTimeslotPicker(
                      context: context,
                    );
                    if (timeslot == null) return;
                    final updated = [...filter.schedule];
                    if (!updated.contains(timeslot)) {
                      updated.add(timeslot);
                      if (notifier.setSchedule(updated) && context.mounted) {
                        _toastCapped('homeTab.filter.scheduleCapped');
                      }
                    }
                  },
                  child: const Icon(FLucideIcons.plus),
                ),
              ),
            ],
          ),
          FButton(
            key: _confirmKey,
            onPress: () => Navigator.of(context).pop(),
            child: Text('homeTab.filter.done'.tr()),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Writing [selectedSportStateProvider] refetches every Discover feed. Not
/// part of "Đặt lại": the sport is which game you're browsing, not a
/// narrowing criterion.
class _SportChoice extends ConsumerWidget {
  const _SportChoice();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PSportPicker(
      value: ref.watch(selectedSportStateProvider).value,
      onChanged: (sport) =>
          ref.read(selectedSportStateProvider.notifier).change(sport),
    );
  }
}
