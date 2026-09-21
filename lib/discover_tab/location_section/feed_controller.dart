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

    // `location.district` is free text from a 3rd-party scrape, so one
    // selected ward has to be offered to the RPC under every spelling the
    // data might store it as — `search_locations` compares with `=`, not a
    // fuzzy match (it does unaccent both sides, so diacritics are handled
    // server-side; spelling is not). Measured against prod, the four forms:
    //   `id`              — the canonical value the tool/venue ward backfill
    //                       writes (`hcm_ankhanh`), plus pre-existing
    //                       coincidences like `hcm_govap`.
    //   `legacyDistrict`  — the old quận label ("Quận 7"), stored by 436
    //                       HCMC / 676 Hanoi rows.
    //   `name`            — a bare ward name, no prefix.
    //   "Phường "/"Xã " + name — the prefixed ward label the scrape's
    //                       reverse-geocode wrote for 425 HCMC + 13 Hanoi
    //                       rows, which matched nothing at all before this
    //                       set included them.
    final districtLabels = <String>{
      for (final d in filter.districts) ...[
        d.id,
        d.legacyDistrict,
        d.name,
        d.toString(), // "Phường Thảo Điền" / "Xã …"
      ],
    }.toList();

    // One code path. `search_locations` gained a match-all branch (empty term
    // + no wards returns the city's venues) precisely so the old direct
    // `.from('location').select()` fallback could go: that query could not
    // express the sport predicate without re-reading the raw tag strings, and
    // filtering after a flat LIMIT 60 is what made a thin sport (badminton,
    // pickleball) render an empty list while matches sat past the limit.
    //
    // District is OR'd with the search term, not AND'd — picking a ward
    // broadens results rather than narrowing a name search. City and sport
    // are hard ANDs on top of that OR.
    final response = await Supabase.instance.client
        .rpc(
          'search_locations',
          params: {
            'search_term': filter.search,
            'p_districts': districtLabels,
            if (filter.city != City.none) 'p_city_cluster': filter.city.dbIndex,
            // `Sport.others` means "nothing chosen" — send null so the server
            // skips the filter entirely rather than matching sport id 0.
            if (sport != Sport.others) 'p_sport_id': sport.index,
          },
        )
        .timeout(const Duration(seconds: 5));

    return (response as List)
        .map((e) => Location.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
