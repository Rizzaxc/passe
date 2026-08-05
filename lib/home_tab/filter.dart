import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../core/model/enum.dart';
import '../core/model/timeslot.dart';
import '../core/user_preferences.dart';
import '../ui/district_select.dart';
import '../ui/search_field.dart';
import '../ui/sheet.dart';
import 'filter_controller.dart';

export 'filter_controller.dart' show FilterData, filterStateProvider;

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

class FilterWidget extends ConsumerWidget {
  /// When true, the sheet also shows a coach/referee role toggle (professional
  /// subtab only). Other subtabs don't use the `role` filter field.
  final bool showRoleFilter;

  const FilterWidget({super.key, this.showRoleFilter = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FButton.icon(
      variant: .ghost,
      onPress: () {
        showPSheet(
          context: context,
          builder: (_) => FilterSheet(showRoleFilter: showRoleFilter),
        );
      },
      child: Icon(FLucideIcons.listFilter),
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
  DayChunk _pendingDayChunk = DayChunk.night;
  DayOfWeek _pendingDayOfWeek = DayOfWeek.weekend;

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
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(filterStateProvider);
    final notifier = ref.read(filterStateProvider.notifier);

    return SingleChildScrollView(
      controller: _scrollController,
      primary: false,
      child: Column(
        spacing: 20,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Role section (professional subtab only). Both checked by
          // default; each role is toggled independently.
          if (widget.showRoleFilter)
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

          // Search section
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PSheetSectionLabel(label: context.tr('homeTab.filter.search')),
              const SizedBox(height: 8),
              PSearchField(
                hint: context.tr('homeTab.filter.searchHint'),
                controller: _searchController,
                onChange: (value) => notifier.setFilter(value),
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
                onChanged: (districts) => notifier.setDistricts(districts),
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
              // and district fields, so the picker row visually
              // separates from the selected-timeslot chip strip
              // above it.
              const SizedBox(height: 8),
              Row(
                spacing: 8,
                // .center keeps the ghost add-button vertically
                // centred on the field row — `.end` anchored it to
                // the bottom, which both looked slightly off and let
                // the pressed-state highlight bleed below the row.
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: FSelect<DayChunk>.rich(
                      hint: _pendingDayChunk.getFullName(context),
                      format: (chunk) => chunk.getFullName(context),
                      autoHide: true,
                      // Default popover width matches the trigger's own
                      // width (`FAutoWidthPortalConstraints`), which is only
                      // half the row here — long labels like "Trưa
                      // (9h-14h)" got clipped when the dropdown opened.
                      // A bounded (not infinite — that crashes layout with
                      // "given an infinite size") maxWidth lets it show the
                      // full label instead of matching the trigger.
                      contentConstraints: const FPortalConstraints(
                        maxWidth: 130,
                        maxHeight: 300,
                      ),
                      control: FSelectControl.lifted(
                        value: _pendingDayChunk,
                        onChange: (chunk) {
                          if (chunk != null) {
                            setState(() => _pendingDayChunk = chunk);
                          }
                        },
                      ),
                      children: [
                        for (final chunk in DayChunk.values)
                          FSelectItem<DayChunk>(
                            title: Text(chunk.getFullName(context)),
                            value: chunk,
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: FSelect<DayOfWeek>.rich(
                      hint: _pendingDayOfWeek.getFullName(context),
                      format: (day) => day.getFullName(context),
                      autoHide: true,
                      contentConstraints: const FPortalConstraints(
                        maxWidth: 130,
                        maxHeight: 300,
                      ),
                      control: FSelectControl.lifted(
                        value: _pendingDayOfWeek,
                        onChange: (day) {
                          if (day != null) {
                            setState(() => _pendingDayOfWeek = day);
                          }
                        },
                      ),
                      children: [
                        for (final day in DayOfWeek.values)
                          FSelectItem<DayOfWeek>(
                            title: Text(day.getFullName(context)),
                            value: day,
                          ),
                      ],
                    ),
                  ),
                  FButton.icon(
                    variant: .ghost,
                    onPress: () {
                      final timeslot = Timeslot(
                        _pendingDayOfWeek,
                        _pendingDayChunk,
                      );
                      final updated = [...filter.schedule];
                      if (!updated.contains(timeslot)) {
                        updated.add(timeslot);
                        notifier.setSchedule(updated);
                      }
                    },
                    child: const Icon(FLucideIcons.plus),
                  ),
                ],
              ),
            ],
          ),
          FButton(
            key: _confirmKey,
            onPress: () => Navigator.of(context).pop(),
            child: Icon(FLucideIcons.check),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
