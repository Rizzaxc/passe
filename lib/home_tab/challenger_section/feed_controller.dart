import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/model/lobby_feed_item.dart';
import '../../core/state/selected_sport_state.dart';
import '../filter_controller.dart';

part 'feed_controller.g.dart';

@riverpod
class ChallengerFeed extends _$ChallengerFeed {
  @override
  Future<List<LobbyFeedItem>> build() async {
    final filter = ref.watch(filterStateProvider);
    final sport = ref.watch(selectedSportStateProvider.select((v) => v.value));
    if (sport == null) return [];

    final districtIds = filter.districts.map((d) => d.id).toList();

    final response = await Supabase.instance.client.rpc(
      'home_challenger_lobby_data',
      params: {
        'p_sport_id': sport.index,
        'p_city': filter.city.dbIndex,
        'p_districts': districtIds,
        'p_page_size': 20,
        'p_page_number': 1,
      },
    ).timeout(const Duration(seconds: 5));

    return (response as List)
        .map((e) => LobbyFeedItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
