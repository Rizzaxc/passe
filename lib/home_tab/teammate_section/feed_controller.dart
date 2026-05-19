import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/auth_controller.dart';
import '../../core/model/lobby_feed_item.dart';
import '../../core/model/timeslot.dart';
import '../../core/state/selected_sport_state.dart';
import '../filter_controller.dart';

part 'feed_controller.g.dart';

@riverpod
class TeammateFeed extends _$TeammateFeed {
  @override
  Future<List<LobbyFeedItem>> build() async {
    final filter = ref.watch(filterStateProvider);
    final sport = ref.watch(selectedSportStateProvider.select((v) => v.value));
    if (sport == null) return [];

    final timeslots = Timeslot.listToJson(filter.schedule);
    final districtIds = filter.districts.map((d) => d.id).toList();

    final response = await Supabase.instance.client.rpc(
      'home_teammate_lobby_data',
      params: {
        'p_sport_id': sport.index,
        'p_timeslots': timeslots,
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

@riverpod
class RequestedLobbyIds extends _$RequestedLobbyIds {
  @override
  Set<String> build() => {};

  Future<void> request(String lobbyId) async {
    state = {...state, lobbyId};
    try {
      final user = ref.read(authControllerProvider).value;
      await Supabase.instance.client.from('lobby_befriend_record').insert({
        if (user?.id != null) 'user_id': user!.id,
        'target_lobby_id': lobbyId,
        'interaction_type': 'request',
      }).timeout(const Duration(seconds: 5));
    } catch (e) {
      state = state.difference({lobbyId});
      rethrow;
    }
  }
}
