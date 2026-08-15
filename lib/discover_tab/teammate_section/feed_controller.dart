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

    final response = await Supabase.instance.client
        .rpc(
          'home_teammate_lobby_data',
          params: {
            'p_sport_id': sport.index,
            'p_timeslots': timeslots,
            'p_city': filter.city.dbIndex,
            'p_districts': districtIds,
            'p_search': filter.search,
            'p_page_size': 20,
            'p_page_number': 1,
          },
        )
        .timeout(const Duration(seconds: 5));

    return (response as List)
        .map((e) => LobbyFeedItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// Per-lobby, in-session override of the join-request state. The feed row's
/// `alreadyRequested` (from the server) is the baseline; an entry here takes
/// precedence (`true` = just requested, `false` = just undone). `keepAlive` so
/// an optimistic toggle isn't lost if the list briefly stops watching.
@Riverpod(keepAlive: true)
class JoinRequestState extends _$JoinRequestState {
  @override
  Map<String, bool> build() => {};

  void _set(String lobbyId, bool? value) {
    final next = {...state};
    if (value == null) {
      next.remove(lobbyId);
    } else {
      next[lobbyId] = value;
    }
    state = next;
  }

  /// Whether the lobby should render as "requested" given the server baseline.
  bool isRequested(String lobbyId, {required bool serverPending}) =>
      state[lobbyId] ?? serverPending;

  Future<void> request(String lobbyId) async {
    final previous = state[lobbyId];
    _set(lobbyId, true);
    try {
      final userId = ref.read(authControllerProvider).value?.id;
      await Supabase.instance.client
          .from('lobby_befriend_record')
          .insert({
            'initiator_user_id': ?userId,
            'target_lobby_id': lobbyId,
            'interaction_type': 'request',
          })
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      _set(lobbyId, previous);
      rethrow;
    }
  }

  /// Cancels a pending join request (the "undo" CTA). Optimistically marks the
  /// lobby not-requested, then flips the befriend record to `cancelled` — there
  /// is no DELETE policy, but the initiator may UPDATE its own record, and the
  /// insert trigger's dup-check ignores `cancelled`, so the lobby becomes
  /// re-requestable. Rolls back the override on failure.
  Future<void> unrequest(String lobbyId) async {
    final userId = ref.read(authControllerProvider).value?.id;
    if (userId == null) return;
    final previous = state[lobbyId];
    _set(lobbyId, false);
    try {
      await Supabase.instance.client
          .from('lobby_befriend_record')
          .update({'status': 'cancelled'})
          .eq('initiator_user_id', userId)
          .eq('target_lobby_id', lobbyId)
          .eq('interaction_type', 'request')
          .eq('status', 'pending')
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      _set(lobbyId, previous);
      rethrow;
    }
  }
}
