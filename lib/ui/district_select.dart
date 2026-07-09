import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../core/model/enum.dart';

/// Groups [values] by their district's legacy quận/huyện into
/// [FSelectSection]s (selected entries sorted first within each group).
/// Shared `contentBuilder` for every district picker's `.searchBuilder`
/// (home filter, profile location, lobby home-ground) so search + grouping
/// stay consistent across all three.
List<FSelectItemMixin> districtSections<T>({
  required BuildContext context,
  required Iterable<T> values,
  required District Function(T) toDistrict,
  required bool Function(T) isSelected,
}) {
  final groups = <String, List<T>>{};
  for (final v in values) {
    groups.putIfAbsent(toDistrict(v).legacyDistrict, () => []).add(v);
  }
  return [
    for (final entry in groups.entries)
      FSelectSection<T>.rich(
        label: Text(entry.key),
        children:
            (entry.value.toList()..sort((a, b) {
                  final aScore = isSelected(a) ? 0 : 1;
                  final bScore = isSelected(b) ? 0 : 1;
                  return aScore.compareTo(bScore);
                }))
                .map(
                  (v) => FSelectItem<T>(
                    title: Text(toDistrict(v).getLocalizedFullName(context)),
                    value: v,
                  ),
                )
                .toList(),
      ),
  ];
}

/// Shared search-field placeholder for district pickers. forui's own
/// localization delegate isn't registered app-wide (only easy_localization's
/// is — see `main.dart`), so its built-in search hint would render in
/// English; this supplies it from the app's translation files instead.
FSelectSearchFieldProperties districtSearchFieldProperties(
  BuildContext context,
) => FSelectSearchFieldProperties(hint: context.tr('district.searchHint'));

/// Shared "no results" empty state for district pickers, for the same reason
/// as [districtSearchFieldProperties] above.
Widget districtEmptyBuilder(BuildContext context) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
  child: Text(context.tr('district.noResults'), textAlign: TextAlign.center),
);
