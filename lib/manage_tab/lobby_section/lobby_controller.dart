import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../auth/auth_controller.dart';
import '../../core/model/enum.dart';
import '../../core/model/lobby.dart';
import '../../core/model/timeslot.dart';
import '../../core/state/selected_sport_state.dart';

part 'lobby_controller.freezed.dart';
part 'lobby_controller.g.dart';

@freezed
abstract class LobbyFormState with _$LobbyFormState {
  const factory LobbyFormState({
    required Lobby lobby,
    @Default(false) bool isNew,
    @Default(false) bool isSaving,
  }) = _LobbyFormState;
}

@riverpod
class UserLobbiesController extends _$UserLobbiesController {
  final supabase = Supabase.instance.client;
  final talker = Talker();

  @override
  Future<List<Lobby>> build() async {
    final user = ref.watch(authControllerProvider).value;
    if (user == null || user.id == null) return [];

    try {
      final response = await supabase
          .from('lobby')
          .select()
          .eq('captain_id', user.id!);

      return (response as List)
          .map((data) => Lobby.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      talker.handle(e, st, 'Error fetching user lobbies');
      return [];
    }
  }

  Future<void> delete(String lobbyId) async {
    await supabase.from('lobby').delete().eq('id', lobbyId);
    ref.invalidateSelf();
  }
}

@riverpod
class LobbyFormController extends _$LobbyFormController {
  final supabase = Supabase.instance.client;
  final talker = Talker();

  @override
  LobbyFormState build(String? lobbyId) {
    if (lobbyId == null) {
      final sport = ref.read(selectedSportStateProvider).value ?? Sport.soccer;
      return LobbyFormState(
        lobby: Lobby(name: '', sport: sport),
        isNew: true,
      );
    }

    _loadLobby(lobbyId);
    return LobbyFormState(
      lobby: Lobby(name: '', sport: Sport.soccer),
      isNew: false,
    );
  }

  Future<void> _loadLobby(String lobbyId) async {
    try {
      final response = await supabase
          .from('lobby')
          .select()
          .eq('id', lobbyId)
          .single();

      state = LobbyFormState(
        lobby: Lobby.fromJson(response),
        isNew: false,
      );
    } catch (e, st) {
      talker.handle(e, st, 'Error fetching lobby');
    }
  }

  void updateDraft({
    String? name,
    Sport? sport,
    LobbyVisibility? visibility,
    List<Timeslot>? playtime,
    LobbyDetails? details,
    String? homeGround,
  }) {
    state = state.copyWith(
      lobby: state.lobby.copyWith(
        name: name ?? state.lobby.name,
        sport: sport ?? state.lobby.sport,
        visibility: visibility ?? state.lobby.visibility,
        playtime: playtime ?? state.lobby.playtime,
        details: details ?? state.lobby.details,
        homeGround: homeGround ?? state.lobby.homeGround,
      ),
    );
  }

  void updateDetails({
    AgeGroup? ageGroup,
    int? skill,
  }) {
    final current = state.lobby.details ?? const LobbyDetails();
    updateDraft(
      details: current.copyWith(
        ageGroup: ageGroup ?? current.ageGroup,
        skill: skill ?? current.skill,
      ),
    );
  }

  Future<Lobby> commit() async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.id == null) {
      throw Exception('User not authenticated');
    }

    state = state.copyWith(isSaving: true);

    try {
      final lobbyData = {
        'name': state.lobby.name,
        'sport_id': state.lobby.sport.index,
        'visibility': state.lobby.visibility.name,
        if (state.lobby.playtime != null)
          'playtime': state.lobby.playtime!.map((t) => t.toJson()).toList(),
        if (state.lobby.details != null)
          'details': state.lobby.details!.toJson(),
        if (state.lobby.homeGround != null)
          'home_ground': state.lobby.homeGround,
      };

      Map<String, dynamic> response;
      if (state.isNew) {
        response = await supabase
            .from('lobby')
            .insert({
              'captain_id': user.id,
              ...lobbyData,
            })
            .select()
            .single();
      } else {
        response = await supabase
            .from('lobby')
            .update(lobbyData)
            .eq('id', state.lobby.id!)
            .select()
            .single();
      }

      final lobby = Lobby.fromJson(response);
      ref.invalidate(userLobbiesControllerProvider);
      return lobby;
    } catch (e, st) {
      talker.handle(e, st, 'Error saving lobby');
      state = state.copyWith(isSaving: false);
      rethrow;
    }
  }
}
