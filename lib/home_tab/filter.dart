import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../core/model/enum.dart';
import '../core/model/timeslot.dart';
import '../ui/theme.dart';
import 'filter_controller.dart';

export 'filter_controller.dart' show FilterData, filterStateProvider;

class FilterWidget extends ConsumerWidget {
  const FilterWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FButton.icon(
      style: FButtonStyle.ghost(),
      onPress: () {
        showFSheet(
          context: context,
          useRootNavigator: true,
          builder: (context) => const FilterSheet(),
          side: .btt,
        );
      },
      child: Icon(FIcons.listFilter),
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

    return FSheets(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        decoration: BoxDecoration(
          color: context.theme.colors.background,
          border: Border.symmetric(
            horizontal: BorderSide(color: context.theme.colors.border),
          ),
        ),
        child: SingleChildScrollView(
          controller: _scrollController,
          primary: false,
          child: Column(
            spacing: 32,
            children: [
              // Search section
              FTextField(
                hint: context.tr('homeTab.filter.searchHint'),
                prefixBuilder: (context, style, states) {
                  return Padding(
                    padding: EdgeInsets.fromLTRB(8, 4, 0, 4),
                    child: Icon(FIcons.search),
                  );
                },
                autocorrect: false,
                control: FTextFieldControl.managed(
                  controller: _searchController,
                  onChange: (value) => notifier.setFilter(value.text),
                ),
              ),

              // Location section
              Column(
                spacing: 8,
                children: [
                  FSelectMenuTile<City>.fromMap(
                    {
                      for (var city in City.values)
                        city.getLocalizedName(context): city,
                    },
                    label: Row(
                      spacing: 2,
                      crossAxisAlignment: .end,
                      children: [
                        const Icon(Icons.location_city),
                        Text(context.tr('homeTab.filter.location')),
                      ],
                    ),
                    title: Text(context.tr('homeTab.filter.city')),
                    selectControl: FMultiValueControl.lifted(
                      value: {filter.city},
                      onChange: (city) {
                        if (city.isEmpty) return;
                        notifier.setCity(city.last);
                      },
                    ),
                    detailsBuilder: (context, city, _) =>
                        Text(city.first.getLocalizedName(context)),
                  ),
                  FSelectMenuTile<District>.fromMap(
                    {
                      ...{
                        for (var d
                            in VietnamLocationData.instance.getDistrictsByCity(
                              filter.city,
                            ))
                          if (filter.districts.contains(d))
                            d.getLocalizedFullName(context): d,
                      },
                      ...{
                        for (var d
                            in VietnamLocationData.instance.getDistrictsByCity(
                              filter.city,
                            ))
                          if (!filter.districts.contains(d))
                            d.getLocalizedFullName(context): d,
                      },
                    },
                    maxHeight: 200,
                    label: null,
                    title: Text(context.tr('homeTab.filter.district')),
                    selectControl: FMultiValueControl.lifted(
                      value: filter.districts,
                      onChange: (districts) => notifier.setDistricts(districts),
                    ),
                    detailsBuilder: (context, districts, _) {
                      if (districts.isEmpty) {
                        return Text(context.tr('homeTab.filter.any'));
                      }
                      if (districts.length == 1) {
                        return Text(
                          districts.first.getLocalizedFullName(context),
                        );
                      }
                      return Text(
                        '${districts.last.getLocalizedFullName(context)}++',
                      );
                    },
                  ),
                ],
              ),

              // Schedule section
              Column(
                spacing: 8,
                children: [
                  Row(
                    spacing: 2,
                    crossAxisAlignment: .end,
                    children: [
                      const Icon(FIcons.calendarDays),
                      Text(
                        context.tr('homeTab.filter.schedule'),
                        style: context.theme.typography.base.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.theme.colors.primary,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 8,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final timeslot in filter.schedule)
                            GestureDetector(
                              onTap: () {
                                final updated = [...filter.schedule];
                                updated.remove(timeslot);
                                notifier.setSchedule(updated);
                              },
                              child: FBadge(
                                style: FBadgeStyle.secondary(),
                                child: Row(
                                  crossAxisAlignment: .center,
                                  spacing: 4,
                                  children: [
                                    Text(
                                      '${timeslot.dayChunk.getShortName(context)} ${timeslot.dayOfWeek.getShortName(context)}',
                                      style: context.theme.typography.base,
                                    ),
                                    Icon(
                                      FIcons.x,
                                      size: 12,
                                      color:
                                          context.theme.colors.mutedForeground,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      Row(
                        spacing: 8,
                        children: [
                          Expanded(
                            child: FSelectMenuTile<DayChunk>.fromMap(
                              {
                                for (var chunk in DayChunk.values)
                                  chunk.getFullName(context): chunk,
                              },
                              title: Text(
                                _pendingDayChunk.getFullName(context),
                              ),
                              selectControl: FMultiValueControl.lifted(
                                value: {_pendingDayChunk},
                                onChange: (chunks) {
                                  if (chunks.isEmpty) return;
                                  setState(
                                    () => _pendingDayChunk = chunks.last,
                                  );
                                },
                              ),
                            ),
                          ),
                          Expanded(
                            child: FSelectMenuTile<DayOfWeek>.fromMap(
                              {
                                for (var day in DayOfWeek.values)
                                  day.getFullName(context): day,
                              },
                              maxHeight: 200,
                              title: Text(
                                _pendingDayOfWeek.getFullName(context),
                              ),
                              selectControl: FMultiValueControl.lifted(
                                value: {_pendingDayOfWeek},
                                onChange: (days) {
                                  if (days.isEmpty) return;
                                  setState(() => _pendingDayOfWeek = days.last);
                                },
                              ),
                            ),
                          ),
                          FButton.icon(
                            style: FButtonStyle.ghost(),
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

                ],
              ),
              FButton(
                onPress: () => Navigator.of(context).pop(),
                child: Icon(FIcons.check),
              ),
              const SizedBox(height: 16,)
            ],
          ),
        ),
      ),
    );
  }
}
