import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/model/lobby.dart';
import '../../core/model/timeslot.dart';
import 'feed/lobby_controller.dart';

part 'lobby_invite_response_controller.g.dart';

/// A single roster row shown at the `public` visibility tier.
class LobbyInviteMember {
  final String username;
  final String tagNumber;

  const LobbyInviteMember({required this.username, required this.tagNumber});
}

/// Preview of a `lobby_befriend_record` invite (interaction_type = 'invite'),
/// keyed by the record id carried in a `lobby_invite` notification payload
/// (`fn_notify_lobby_invite`). Backs `LobbyInvitePreviewPage`. `status` lets
/// the page tell a still-open invite apart from one already resolved on the
/// other surface (the notification card's own inline Accept/Reject).
///
/// Fields are tiered by the target lobby's own [visibility]
/// (`get_lobby_befriend_invite_preview`, additive):
/// - always: [lobbyId]/[lobbyName]/[hasAvatar], [inviterUsername]
/// - `discoverable`+: [memberCount], [captainUsername], [relationship],
///   [fitscore]
/// - `public`: [homeGroundName], [playtime], [mmr]/[isMmrCalibrated],
///   [members]
class LobbyInvitePreview {
  final bool valid;
  final String? reason; // 'not_found'
  final String? status; // 'pending' | 'accepted' | 'declined'
  final String? lobbyId;
  final String? lobbyName;
  final bool hasAvatar;
  final LobbyVisibility? visibility;
  final String? inviterUsername;

  // discoverable+
  final int? memberCount;
  final String? captainUsername;
  final String? relationship; // 'none'|'friend'|'incoming'|'outgoing'|'blocked'
  final double? fitscore;

  // public only
  final String? homeGroundName;
  final List<Timeslot>? playtime;
  final int? mmr;
  final bool isMmrCalibrated;
  final List<LobbyInviteMember>? members;

  const LobbyInvitePreview({
    required this.valid,
    this.reason,
    this.status,
    this.lobbyId,
    this.lobbyName,
    this.hasAvatar = false,
    this.visibility,
    this.inviterUsername,
    this.memberCount,
    this.captainUsername,
    this.relationship,
    this.fitscore,
    this.homeGroundName,
    this.playtime,
    this.mmr,
    this.isMmrCalibrated = false,
    this.members,
  });
}

@riverpod
Future<LobbyInvitePreview> lobbyInvitePreview(Ref ref, String recordId) async {
  final res = await Supabase.instance.client
      .rpc(
        'get_lobby_befriend_invite_preview',
        params: {'p_record_id': recordId},
      )
      .timeout(const Duration(seconds: 5));

  final map = res as Map<String, dynamic>;
  if (map['valid'] != true) {
    return LobbyInvitePreview(valid: false, reason: map['reason'] as String?);
  }

  final visibility = LobbyVisibility.values.firstWhere(
    (v) => v.name == map['visibility'],
    orElse: () => LobbyVisibility.private,
  );

  final rawMembers = map['members'] as List?;
  final rawPlaytime = map['playtime'] as List?;

  return LobbyInvitePreview(
    valid: true,
    status: map['status'] as String?,
    lobbyId: map['lobby_id'] as String?,
    lobbyName: map['lobby_name'] as String?,
    hasAvatar: map['has_avatar'] as bool? ?? false,
    visibility: visibility,
    inviterUsername: map['inviter_username'] as String?,
    memberCount: (map['member_count'] as num?)?.toInt(),
    captainUsername: map['captain_username'] as String?,
    relationship: map['relationship'] as String?,
    fitscore: (map['fitscore'] as num?)?.toDouble(),
    homeGroundName: map['home_ground_name'] as String?,
    playtime: rawPlaytime
        ?.map((e) => Timeslot.fromJson(e as Map<String, dynamic>))
        .toList(),
    mmr: (map['mmr'] as num?)?.toInt(),
    isMmrCalibrated: map['is_mmr_calibrated'] as bool? ?? false,
    members: rawMembers
        ?.map(
          (e) => LobbyInviteMember(
            username: (e as Map<String, dynamic>)['username'] as String,
            tagNumber: e['tag_number'] as String,
          ),
        )
        .toList(),
  );
}

/// Cheap status-only read for the notification list row's inline state —
/// avoids pulling the full preview (lobby name/sport/captain/…) just to know
/// whether to show Accept/Reject or a resolved hint.
@riverpod
Future<String?> lobbyInviteStatus(Ref ref, String recordId) async {
  final row = await Supabase.instance.client
      .from('lobby_befriend_record')
      .select('status')
      .eq('id', recordId)
      .maybeSingle()
      .timeout(const Duration(seconds: 5));
  return row?['status'] as String?;
}

/// Accept/decline a lobby invite. Shared by the notification card's inline
/// buttons and LobbyInvitePreviewPage — the only two surfaces that respond to
/// an invite (the old Manage▸Lobby mail-icon sheet is retired).
///
/// `keepAlive: true` — nothing ever watches this controller's (trivial void)
/// state, only its `.notifier` for `respond()`, so a plain autoDispose
/// provider gets disposed the instant the `ref.read` call returns (no
/// listeners) — then `respond()`'s own `ref.invalidate(...)` throws after its
/// `await` gap because its own `ref` is already dead.
@Riverpod(keepAlive: true)
class LobbyInviteResponseController extends _$LobbyInviteResponseController {
  final supabase = Supabase.instance.client;

  @override
  void build() {}

  Future<void> respond(String recordId, {required bool accept}) async {
    await supabase
        .from('lobby_befriend_record')
        .update({'status': accept ? 'accepted' : 'declined'})
        .eq('id', recordId)
        .timeout(const Duration(seconds: 5));
    ref.invalidate(lobbyInviteStatusProvider(recordId));
    ref.invalidate(lobbyInvitePreviewProvider(recordId));
    // Membership itself is added server-side by lobby_befriend_accepted_trigger_fn.
    if (accept) ref.invalidate(userLobbiesControllerProvider);
  }
}
