import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/model/professional_feed_item.dart';
import '../../core/model/timeslot.dart';
import '../../core/state/selected_sport_state.dart';
import '../filter_controller.dart';

part 'feed_controller.g.dart';

@riverpod
class ProfessionalFeed extends _$ProfessionalFeed {
  @override
  Future<List<ProfessionalFeedItem>> build() async {
    final sport = ref.watch(selectedSportStateProvider.select((v) => v.value));

    // Refetch only when a query-affecting filter field changes. The role
    // toggle is applied client-side in the subtab, so it is intentionally
    // NOT watched here (copyWith reuses references for untouched fields, so a
    // role change leaves these selects equal → no refetch).
    final city = ref.watch(filterStateProvider.select((f) => f.city));
    final districts = ref.watch(filterStateProvider.select((f) => f.districts));
    final schedule = ref.watch(filterStateProvider.select((f) => f.schedule));
    final search = ref.watch(filterStateProvider.select((f) => f.search));

    if (sport == null) return [];

    // `home_professional_data` applies sport + (soft) city/district/schedule
    // + search (display_name) filtering, ranks verified → rating → reviews,
    // and rolls up each pro's cheapest active service rate as `price_from`.
    final response = await Supabase.instance.client
        .rpc(
          'home_professional_data',
          params: {
            'p_sport_id': sport.index,
            'p_timeslots': Timeslot.listToJson(schedule),
            'p_city': city.dbIndex,
            'p_districts': districts.map((d) => d.id).toList(),
            'p_search': search,
            'p_page_size': 20,
            'p_page_number': 1,
          },
        )
        .timeout(const Duration(seconds: 5));

    return (response as List)
        .map((e) => ProfessionalFeedItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
