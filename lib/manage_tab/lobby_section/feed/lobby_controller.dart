import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../../auth/auth_controller.dart';
import '../../../core/model/enum.dart';
import '../../../core/model/lobby.dart';
import '../../../core/model/location.dart';
import '../../../core/model/timeslot.dart';
import '../../../core/state/selected_sport_state.dart';

part 'lobby_controller.freezed.dart';
part 'lobby_controller.g.dart';

@freezed
abstract class LobbyFormState with _$LobbyFormState {
  const factory LobbyFormState({
    required Lobby lobby,
    @Default(false) bool isSaving,
    // non-null when the user is entering a custom address (free-text mode)
    Map<String, String?>? freeAddress,
  }) = _LobbyFormState;
}

class LobbyListItem {
  final Lobby lobby;
  final int memberCount;
  final DateTime? nextActivity; // TODO: populate from schedule
  final String? homeGroundName;

  const LobbyListItem({required this.lobby, required this.memberCount, this.nextActivity, this.homeGroundName});
}

@riverpod
class UserLobbiesController extends _$UserLobbiesController {
  final supabase = Supabase.instance.client;
  final talker = Talker();

  @override
  Future<List<LobbyListItem>> build() async {
    final user = ref.watch(authControllerProvider).value;
    if (user == null || user.id == null) return [];

    final sport = ref.watch(selectedSportStateProvider).value;
    if (sport == null) return [];

    final lobbyRows = await supabase
        .from('lobby')
        .select('id, name, searchable_id, sport_id, captain_id, home_ground, location(name), lobby_member!inner(user_id)')
        .eq('sport_id', sport.index)
        .eq('lobby_member.user_id', user.id!)
        .timeout(const Duration(seconds: 5));

    talker.log(lobbyRows, logLevel: .debug);

    final lobbies = (lobbyRows as List)
        .map((row) {
          final data = Map<String, dynamic>.from(row as Map)
            ..remove('lobby_member')
            ..remove('location');
          return Lobby.fromJson(data);
        })
        .toList();

    if (lobbies.isEmpty) return [];

    final homeGroundNames = <String, String>{};
    for (final row in lobbyRows as List) {
      final id = (row as Map)['id'] as String?;
      final loc = row['location'];
      if (id != null && loc is Map) {
        final locName = loc['name'] as String?;
        if (locName != null) homeGroundNames[id] = locName;
      }
    }

    final lobbyIds = lobbies.map((l) => l.id!).toList();
    final countRows = await supabase
        .from('lobby_member')
        .select('lobby_id')
        .inFilter('lobby_id', lobbyIds)
        .timeout(const Duration(seconds: 5));

    final countMap = <String, int>{};
    for (final row in countRows as List) {
      final id = row['lobby_id'] as String;
      countMap[id] = (countMap[id] ?? 0) + 1;
    }

    return lobbies
        .map((lobby) => LobbyListItem(
              lobby: lobby,
              memberCount: countMap[lobby.id] ?? 0,
              homeGroundName: homeGroundNames[lobby.id],
            ))
        .toList();
  }

  Future<void> delete(String lobbyId) async {
    await supabase.from('lobby').delete().eq('id', lobbyId).timeout(const Duration(seconds: 5));
    ref.invalidateSelf();
  }
}

@riverpod
class LobbyFormController extends _$LobbyFormController {
  final supabase = Supabase.instance.client;
  final talker = Talker();

  @override
  LobbyFormState build(String? lobbyId) {
    final sport = ref.read(selectedSportStateProvider).value ?? Sport.soccer;
    return LobbyFormState(lobby: Lobby(name: '', sport: sport));
  }


  void updateFreeAddress(Map<String, String?>? addr) {
    state = state.copyWith(freeAddress: addr);
  }

  void updateDraft({
    String? name,
    Sport? sport,
    LobbyVisibility? visibility,
    List<Timeslot>? playtime,
    LobbyDetails? details,
    String? homeGround,
  }) {
    if (playtime != null) {
      while (playtime.length > 3) {
        playtime.removeAt(0);
      }
    }
    state = state.copyWith(
      lobby: state.lobby.copyWith(
        name: name ?? state.lobby.name,
        sport: sport ?? state.lobby.sport,
        visibility: visibility ?? state.lobby.visibility,
        playtime: playtime ?? state.lobby.playtime,
        details: details ?? state.lobby.details,
        homeGround: homeGround != null
            ? (homeGround.isEmpty ? null : homeGround)
            : state.lobby.homeGround,
      ),
    );
  }

  static const _absent = Object();

  void updateDetails({
    Object? ageGroup = _absent,
    Object? skill = _absent,
  }) {
    final current = state.lobby.details ?? const LobbyDetails();
    updateDraft(
      details: current.copyWith(
        ageGroup: ageGroup == _absent ? current.ageGroup : ageGroup as AgeGroup?,
        skill: skill == _absent ? current.skill : skill as int?,
      ),
    );
  }

  Future<List<Location>> searchHomeGround(String query) async {
    if (query.length < 8) return [];

    final response = await supabase
        .rpc('search_locations', params: {'search_term': query})
        .timeout(const Duration(seconds: 5));

    return (response as List)
        .map((e) => Location.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Lobby> commit() async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.id == null) {
      throw Exception('User not authenticated');
    }

    state = state.copyWith(isSaving: true);

    try {
      // Always use the RPC so the captain is added as first member atomically.
      // For geocoded locations pass p_home_ground_id; for free-text pass address fields.
      final params = <String, dynamic>{
        'p_name': state.lobby.name,
        'p_sport_id': state.lobby.sport.index,
        'p_visibility': state.lobby.visibility.name,
        if (state.lobby.playtime != null)
          'p_playtime': state.lobby.playtime!.map((t) => t.toJson()).toList(),
        if (state.lobby.details != null)
          'p_details': state.lobby.details!.toJson(),
      };

      final fa = state.freeAddress;
      if (fa != null) {
        // free-text mode: create a new location row from the supplied fields
        if ((fa['locationName'] ?? '').isNotEmpty)
          params['p_location_name'] = fa['locationName'];
        if ((fa['streetNumber'] ?? '').isNotEmpty)
          params['p_street_number'] = fa['streetNumber'];
        if ((fa['streetName'] ?? '').isNotEmpty)
          params['p_street_name'] = fa['streetName'];
        if ((fa['district'] ?? '').isNotEmpty)
          params['p_district'] = fa['district'];
        if ((fa['city'] ?? '').isNotEmpty)
          params['p_city'] = fa['city'];
      } else if (state.lobby.homeGround != null) {
        // geocoded mode: reference an existing location by UUID
        params['p_home_ground_id'] = state.lobby.homeGround;
      }

      final response = await supabase.rpc('create_lobby_with_location', params: params).timeout(const Duration(seconds: 5));
      final lobby = Lobby.fromJson(response as Map<String, dynamic>);
      ref.invalidate(userLobbiesControllerProvider);
      return lobby;
    } catch (e, st) {
      talker.handle(e, st, 'Error saving lobby');
      state = state.copyWith(isSaving: false);
      rethrow;
    }
  }
}
