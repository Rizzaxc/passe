import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../core/model/enum.dart';
import '../core/model/timeslot.dart';
import '../ui/search_field.dart';
import '../ui/sheet.dart';
import 'filter_controller.dart';

export 'filter_controller.dart' show FilterData, filterStateProvider;

class FilterWidget extends ConsumerWidget {
  const FilterWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FButton.icon(
      variant: .ghost,
      onPress: () {
        showPSheet(
          context: context,
          builder: (_) => const FilterSheet(),
        );
      },
      child: Icon(FIcons.listFilter),
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
    final allDistricts = VietnamLocationData.instance.getDistrictsByCity(city);
    final groups = <VietnamDistrictType, List<District>>{};
    for (final d in allDistricts) {
      groups.putIfAbsent(d.type, () => []).add(d);
    }

    return FMultiSelect<District>.rich(
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
      children: [
        for (final entry in groups.entries)
          FSelectSection<District>.rich(
            label: Text(context.tr('district.${entry.key.name}')),
            children: (entry.value.toList()
                  ..sort((a, b) {
                    final aScore = selected.contains(a) ? 0 : 1;
                    final bScore = selected.contains(b) ? 0 : 1;
                    return aScore.compareTo(bScore);
                  }))
                .map(
                  (d) => FSelectItem<District>(
                    title: Text(d.getLocalizedFullName(context)),
                    value: d,
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class FilterSheet extends ConsumerStatefulWidget {
  const FilterSheet({super.key});

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  late TextEditingController _searchController;
  final ScrollController _scrollController = ScrollController();
  DayChunk _pendingDayChunk = DayChunk.night;
  DayOfWeek _pendingDayOfWeek = DayOfWeek.weekend;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(filterStateProvider).search,
    );
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
                  PSheetSectionLabel(
                    label: context.tr('homeTab.filter.location'),
                  ),
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
                  PSheetSectionLabel(
                    label: context.tr('homeTab.filter.schedule'),
                  ),
                  const SizedBox(height: 8),
                  Builder(builder: (context) {
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
                                  10, 0, 8, 0),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: fieldStyle.spacing,
                                  runSpacing: fieldStyle.runSpacing,
                                  children: [
                                    if (filter.schedule.isEmpty)
                                      Padding(
                                        padding: const EdgeInsetsDirectional
                                            .fromSTEB(4, 4, 0, 4),
                                        child: Text(
                                          context.tr('homeTab.filter.any'),
                                          style: context.theme.typography.sm
                                              .copyWith(
                                            color: context
                                                .theme.colors.mutedForeground,
                                          ),
                                        ),
                                      ),
                                      for (final timeslot in filter.schedule)
                                        GestureDetector(
                                          onTap: () {
                                            final updated = [
                                              ...filter.schedule
                                            ];
                                            updated.remove(timeslot);
                                            notifier.setSchedule(updated);
                                          },
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              borderRadius: context
                                                  .theme.style.borderRadius.md,
                                              color: context
                                                  .theme.colors.secondary,
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 4,
                                                      horizontal: 8),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                spacing: 4,
                                                children: [
                                                  Text(
                                                    '${timeslot.dayChunk.getShortName(context)} ${timeslot.dayOfWeek.getShortName(context)}',
                                                    style: context
                                                        .theme.typography.sm
                                                        .copyWith(
                                                      color: context.theme
                                                          .colors
                                                          .secondaryForeground,
                                                    ),
                                                  ),
                                                  IconTheme(
                                                    data: IconThemeData(
                                                      color: context.theme
                                                          .colors.mutedForeground,
                                                      size: 15,
                                                    ),
                                                    child:
                                                        const Icon(FIcons.x),
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
                  }),
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
                        child: const Icon(FIcons.plus),
                      ),
                    ],
                  ),
                ],
              ),
              FButton(
                onPress: () => Navigator.of(context).pop(),
                child: Icon(FIcons.check),
              ),
              const SizedBox(height: 8,)
            ],
          ),
    );
  }
}
