import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image_picker/image_picker.dart';
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

/// Thrown by [LobbyFormController.commit] when trying to create a lobby with no
/// context sport selected (`Sport.others`).
class LobbySportNotSelected implements Exception {
  const LobbySportNotSelected();
}

@freezed
abstract class LobbyFormState with _$LobbyFormState {
  const factory LobbyFormState({
    required Lobby lobby,
    @Default(false) bool isSaving,
    // non-null when the user is entering a custom address (free-text mode)
    Map<String, String?>? freeAddress,
    // a not-yet-uploaded avatar pick; uploaded to the `lobby_avatar` bucket
    // on commit (see LobbyFormController.commit).
    XFile? pickedAvatar,
  }) = _LobbyFormState;
}

class LobbyListItem {
  final Lobby lobby;
  final int memberCount;
  final DateTime? nextActivity;
  final String? homeGroundName;
  final int mmr;

  /// True once the lobby has played at least one challenge match
  /// (opponent_lobby_id set) — before that, `mmr` is still just the
  /// untouched default and isn't a meaningful rating yet.
  final bool isMmrCalibrated;

  /// True if the current user is this lobby's captain-appointed
  /// coordinator — everything a captain does except kicking members and
  /// editing lobby info.
  final bool isCoordinator;

  const LobbyListItem({
    required this.lobby,
    required this.memberCount,
    this.nextActivity,
    this.homeGroundName,
    this.mmr = 1000,
    this.isMmrCalibrated = false,
    this.isCoordinator = false,
  });
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

    // Housekeeping (expiring past unconfirmed activities) runs server-side on a
    // pg_cron schedule ('expire_past_activities' job) — it must NOT run as a
    // mutation on this read path.

    // `lobby` has two FKs to `location` (`home_ground` and
    // `challenge_offer_location`, the latter added for the Challenger
    // System's offer terms), so an unqualified `location(...)` embed is
    // ambiguous — PostgREST rejects it with a 300/PGRST201 ("more than one
    // relationship was found"), which silently broke this whole query (and
    // therefore the entire Manage▸Lobby list) the moment that column
    // shipped. Pin the FK explicitly to keep resolving the homeground, not
    // the challenge-offer venue.
    final lobbyRows = await supabase
        .from('lobby')
        .select(
          'id, name, searchable_id, sport_id, captain_id, home_ground, details, mmr, location!lobby_home_ground_fkey(name), lobby_member!inner(user_id, role)',
        )
        .eq('sport_id', sport.index)
        .eq('lobby_member.user_id', user.id!)
        .timeout(const Duration(seconds: 5));

    talker.log(lobbyRows, logLevel: .debug);

    final lobbies = (lobbyRows as List).map((row) {
      final data = Map<String, dynamic>.from(row as Map)
        ..remove('lobby_member')
        ..remove('location');
      return Lobby.fromJson(data);
    }).toList();

    if (lobbies.isEmpty) return [];

    final homeGroundNames = <String, String>{};
    final mmrMap = <String, int>{};
    final coordinatorIds = <String>{};
    for (final row in lobbyRows as List) {
      final id = (row as Map)['id'] as String?;
      if (id == null) continue;
      final loc = row['location'];
      if (loc is Map) {
        final locName = loc['name'] as String?;
        if (locName != null) homeGroundNames[id] = locName;
      }
      mmrMap[id] = (row['mmr'] as num?)?.toInt() ?? 1000;

      // `!inner` still embeds as a list; the eq() filter above guarantees
      // it's exactly the caller's own row.
      final memberRows = row['lobby_member'] as List?;
      final myRole = (memberRows != null && memberRows.isNotEmpty)
          ? memberRows.first['role'] as String?
          : null;
      if (LobbyMemberRole.fromValue(myRole) == LobbyMemberRole.coordinator) {
        coordinatorIds.add(id);
      }
    }

    final lobbyIds = lobbies.map((l) => l.id!).toList();

    // A lobby's mmr is only meaningful once it's played at least one
    // challenge match — before that it's just sitting at the untouched
    // default, so the card shows a placeholder instead of the number.
    final challengeMatchRows = await supabase
        .from('lobby_match')
        .select('lobby_id')
        .inFilter('lobby_id', lobbyIds)
        .not('opponent_lobby_id', 'is', null)
        .timeout(const Duration(seconds: 5));

    final calibratedIds = <String>{
      for (final row in challengeMatchRows as List) row['lobby_id'] as String,
    };
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

    // Soonest upcoming one-off activity per lobby, for the card's
    // activity-state row. Recurring series (recurrence_day_of_week) are
    // deliberately not resolved to their next occurrence here — that
    // needs the same virtual-occurrence math as
    // activity/upcoming_controller.dart, which is more than this compact
    // list card needs; a recurring-only lobby just shows "no activity"
    // until it's opened.
    final activityRows = await supabase
        .from('activity')
        .select('lobby_id, start_time')
        .inFilter('lobby_id', lobbyIds)
        .gt('start_time', DateTime.now().toUtc().toIso8601String())
        .order('start_time')
        .timeout(const Duration(seconds: 5));

    final nextActivityMap = <String, DateTime>{};
    for (final row in activityRows as List) {
      final id = row['lobby_id'] as String;
      // Rows arrive start_time-ascending, so the first one seen per
      // lobby is already the soonest.
      nextActivityMap.putIfAbsent(
        id,
        () => DateTime.parse(row['start_time'] as String),
      );
    }

    return lobbies
        .map(
          (lobby) => LobbyListItem(
            lobby: lobby,
            memberCount: countMap[lobby.id] ?? 0,
            homeGroundName: homeGroundNames[lobby.id],
            nextActivity: nextActivityMap[lobby.id],
            mmr: mmrMap[lobby.id] ?? 1000,
            isMmrCalibrated: calibratedIds.contains(lobby.id),
            isCoordinator: coordinatorIds.contains(lobby.id),
          ),
        )
        .toList();
  }

  Future<void> delete(String lobbyId) async {
    await supabase
        .from('lobby')
        .delete()
        .eq('id', lobbyId)
        .timeout(const Duration(seconds: 5));
    ref.invalidateSelf();
  }

  /// Leaves a lobby by removing the caller's own `lobby_member` row. The
  /// "Lobby membership deletion policy" RLS permits self-removal; the
  /// `lobby_member_prevent_captain_leave` trigger rejects a captain leaving
  /// (transfer captaincy or delete instead) — the caller surfaces that error.
  Future<void> leave(String lobbyId) async {
    final userId = ref.read(authControllerProvider).value?.id;
    if (userId == null) return;
    await supabase
        .from('lobby_member')
        .delete()
        .eq('lobby_id', lobbyId)
        .eq('user_id', userId)
        .timeout(const Duration(seconds: 5));
    ref.invalidateSelf();
  }

  /// Transfers captaincy to another member via the validated SECURITY DEFINER
  /// RPC (RLS has no UPDATE policy on lobby). The old captain stays a member.
  Future<void> transferCaptaincy(String lobbyId, String newCaptainId) async {
    await supabase
        .rpc(
          'transfer_lobby_captaincy',
          params: {'p_lobby_id': lobbyId, 'p_new_captain_id': newCaptainId},
        )
        .timeout(const Duration(seconds: 5));
    ref.invalidateSelf();
  }
}

@riverpod
class LobbyFormController extends _$LobbyFormController {
  final supabase = Supabase.instance.client;
  final talker = Talker();

  String? _lobbyId;

  // Snapshot of `details.hasAvatar` as loaded from the DB, so commit() can
  // tell "never had one" apart from "user just removed it".
  bool _originalHasAvatar = false;

  @override
  LobbyFormState build(String? lobbyId) {
    _lobbyId = lobbyId;
    // Default to the context sport; if it isn't resolved yet, leave it as
    // `others` so commit() blocks rather than silently creating a Soccer lobby.
    final sport = ref.read(selectedSportStateProvider).value ?? Sport.others;
    return LobbyFormState(
      lobby: Lobby(name: '', sport: sport),
    );
  }

  void initFromLobby(Lobby lobby) {
    _originalHasAvatar = lobby.details?.hasAvatar ?? false;
    state = LobbyFormState(lobby: lobby);
  }

  Future<void> pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked == null) return;
    state = state.copyWith(pickedAvatar: picked);
  }

  void removeAvatar() {
    state = state.copyWith(pickedAvatar: null);
    updateDetails(hasAvatar: false);
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
    bool? hasAvatar,
  }) {
    final current = state.lobby.details ?? const LobbyDetails();
    updateDraft(
      details: current.copyWith(
        ageGroup: ageGroup == _absent
            ? current.ageGroup
            : ageGroup as AgeGroup?,
        skill: skill == _absent ? current.skill : skill as int?,
        hasAvatar: hasAvatar ?? current.hasAvatar,
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

  Future<bool> _uploadAvatar(String lobbyId, XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      await supabase.storage
          .from('lobby_avatar')
          .uploadBinary(
            '$lobbyId.jpg',
            bytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          )
          .timeout(const Duration(seconds: 5));
      return true;
    } catch (e, st) {
      talker.handle(e, st, 'Failed to upload lobby avatar');
      return false;
    }
  }

  Future<void> _deleteAvatar(String lobbyId) async {
    try {
      await supabase.storage
          .from('lobby_avatar')
          .remove(['$lobbyId.jpg'])
          .timeout(const Duration(seconds: 5));
    } catch (e, st) {
      talker.handle(e, st, 'Failed to remove lobby avatar');
    }
  }

  Future<Lobby> commit() async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.id == null) {
      throw Exception('User not authenticated');
    }

    state = state.copyWith(isSaving: true);

    try {
      final Lobby lobby;

      if (_lobbyId != null) {
        // Edit path — call update_lobby SECURITY DEFINER RPC.
        var details = state.lobby.details;
        if (state.pickedAvatar != null) {
          final uploaded = await _uploadAvatar(_lobbyId!, state.pickedAvatar!);
          if (uploaded) {
            details = (details ?? const LobbyDetails()).copyWith(
              hasAvatar: true,
            );
          }
        } else if (_originalHasAvatar && !(details?.hasAvatar ?? false)) {
          await _deleteAvatar(_lobbyId!);
        }

        final params = <String, dynamic>{
          'p_lobby_id': _lobbyId,
          'p_name': state.lobby.name,
          'p_visibility': state.lobby.visibility.name,
          'p_playtime': state.lobby.playtime?.map((t) => t.toJson()).toList(),
          if (details != null) 'p_details': details.toJson(),
        };
        if (state.lobby.homeGround != null) {
          params['p_home_ground_id'] = state.lobby.homeGround;
        }
        await supabase
            .rpc('update_lobby', params: params)
            .timeout(const Duration(seconds: 5));
        lobby = state.lobby.copyWith(id: _lobbyId, details: details);
        ref.invalidate(userLobbiesControllerProvider);
      } else {
        // Block creating a lobby with no real sport (Sport.others = index 0):
        // the whole app is scoped to a context sport, and a sportless lobby
        // corrupts every sport-filtered feed. Previously this silently fell back
        // to Soccer.
        if (state.lobby.sport == Sport.others) {
          throw const LobbySportNotSelected();
        }
        // Create path — always use the RPC so the captain is added as first member atomically.
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
          if ((fa['locationName'] ?? '').isNotEmpty) {
            params['p_location_name'] = fa['locationName'];
          }
          if ((fa['streetNumber'] ?? '').isNotEmpty) {
            params['p_street_number'] = fa['streetNumber'];
          }
          if ((fa['streetName'] ?? '').isNotEmpty) {
            params['p_street_name'] = fa['streetName'];
          }
          if ((fa['district'] ?? '').isNotEmpty) {
            params['p_district'] = fa['district'];
          }
          if ((fa['city'] ?? '').isNotEmpty) {
            params['p_city'] = fa['city'];
          }
        } else if (state.lobby.homeGround != null) {
          params['p_home_ground_id'] = state.lobby.homeGround;
        }

        final response = await supabase
            .rpc('create_lobby_with_location', params: params)
            .timeout(const Duration(seconds: 5));
        var createdLobby = Lobby.fromJson(response as Map<String, dynamic>);

        if (state.pickedAvatar != null && createdLobby.id != null) {
          final uploaded = await _uploadAvatar(
            createdLobby.id!,
            state.pickedAvatar!,
          );
          if (uploaded) {
            final details = (createdLobby.details ?? const LobbyDetails())
                .copyWith(hasAvatar: true);
            await supabase
                .rpc(
                  'update_lobby',
                  params: {
                    'p_lobby_id': createdLobby.id,
                    'p_name': createdLobby.name,
                    'p_visibility': createdLobby.visibility.name,
                    'p_playtime': createdLobby.playtime
                        ?.map((t) => t.toJson())
                        .toList(),
                    'p_details': details.toJson(),
                    if (createdLobby.homeGround != null)
                      'p_home_ground_id': createdLobby.homeGround,
                  },
                )
                .timeout(const Duration(seconds: 5));
            createdLobby = createdLobby.copyWith(details: details);
          }
        }

        lobby = createdLobby;
        ref.invalidate(userLobbiesControllerProvider);
      }

      return lobby;
    } catch (e, st) {
      talker.handle(e, st, 'Error saving lobby');
      state = state.copyWith(isSaving: false);
      rethrow;
    }
  }
}
