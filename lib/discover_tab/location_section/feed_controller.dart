import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/model/enum.dart';
import '../../core/model/location.dart';
import '../../core/state/selected_sport_state.dart';
import '../filter_controller.dart';

part 'feed_controller.g.dart';

@riverpod
class LocationFeed extends _$LocationFeed {
  @override
  Future<List<Location>> build() async {
    final filter = ref.watch(filterStateProvider);
    final sport = ref.watch(selectedSportStateProvider.select((v) => v.value));
    if (sport == null) return [];

    // `location.district` is free text from a 3rd-party scrape, not
    // `District.id`. Verified against prod: the real (non-`mocked_`) rows
    // for HCMC's 16 old urban quận store the exact old-district label
    // ("Quận 7", "Quận Bình Thạnh") — which is exactly what each ward's
    // `legacyDistrict` holds (~43% of HCMC rows match this way). `id` is
    // included too for the handful of rows already using it (the `mocked_`
    // seed, plus a few coincidental matches where a ward kept its parent
    // district's name, e.g. `hcm_govap`). Rows using a pre-2021 sub-ward
    // name (e.g. "Phường Thảo Điền", predating even the old Quận 2/Thủ Đức
    // merger) or no district at all won't match any selected filter — a
    // real, accepted gap given the data's quality, not a bug to chase
    // further without a normalization pass on the source data.
    final districtLabels = <String>{
      for (final d in filter.districts) ...[d.legacyDistrict, d.id],
    }.toList();

    List<Location> results;
    if (filter.search.isNotEmpty || districtLabels.isNotEmpty) {
      // `search_locations` OR's the name/address search against the
      // district filter (not AND's) — picking a district should broaden
      // results, not narrow a name search down further. City is a hard AND
      // on top of that OR (schema/location_search_city_filter.sql).
      final response = await Supabase.instance.client
          .rpc(
            'search_locations',
            params: {
              'search_term': filter.search,
              'p_districts': districtLabels,
              if (filter.city != City.none) 'p_city_cluster': filter.city.dbIndex,
            },
          )
          .timeout(const Duration(seconds: 5));
      results = (response as List)
          .map((e) => Location.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      var query = Supabase.instance.client.from('location').select();

      if (filter.city != City.none) {
        query = query.eq('city_cluster', filter.city.dbIndex);
      }

      // Fetched pre-sport-filter, so a slightly larger page (60, up from 40)
      // keeps a reasonable result count once venues for other sports are
      // dropped below.
      final response = await query
          .limit(60)
          .timeout(const Duration(seconds: 5));
      results = (response as List)
          .map((e) => Location.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Sport-scope client-side (same precedent as the professional subtab's
    // `visibleRoles` filter) — the raw `tags` format ("key:[v1, v2]" OSM
    // strings) isn't something SQL can cleanly filter on without a
    // normalization migration. `Sport.others` (no sport chosen) skips
    // filtering entirely rather than hiding everything.
    if (sport == Sport.others) return results;
    final matched = results.where((l) => l.matchesSport(sport)).toList();

    // Venues explicitly tagged for the context sport surface first; untagged
    // ones (kept above since we can't confirm irrelevance) trail behind —
    // stable sort preserves each group's original (search-rank/limit) order.
    matched.sort((a, b) {
      final aTagged = a.sports.contains(sport) ? 0 : 1;
      final bTagged = b.sports.contains(sport) ? 0 : 1;
      return aTagged.compareTo(bTagged);
    });
    return matched;
  }
}
