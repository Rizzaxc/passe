import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'invite_landing_controller.g.dart';

class InvitePreview {
  final bool valid;
  final String? reason; // 'not_found' | 'revoked' | 'expired'
  final String? lobbyId;
  final String? lobbyName;
  final int? sportId;
  final int? memberCount;
  final String? captainUsername;

  const InvitePreview({
    required this.valid,
    this.reason,
    this.lobbyId,
    this.lobbyName,
    this.sportId,
    this.memberCount,
    this.captainUsername,
  });
}

@riverpod
Future<InvitePreview> inviteLinkPreview(Ref ref, String code) async {
  final res = await Supabase.instance.client
      .rpc('get_lobby_invite_preview', params: {'p_code': code})
      .timeout(const Duration(seconds: 5));

  final map = res as Map<String, dynamic>;
  return InvitePreview(
    valid: map['valid'] as bool,
    reason: map['reason'] as String?,
    lobbyId: map['lobby_id'] as String?,
    lobbyName: map['lobby_name'] as String?,
    sportId: (map['sport_id'] as num?)?.toInt(),
    memberCount: (map['member_count'] as num?)?.toInt(),
    captainUsername: map['captain_username'] as String?,
  );
}

/// One-shot redeem call — not a controller, just a thin RPC wrapper the page
/// calls from its join button. Returns the raw `{status, lobby_id,
/// lobby_name}` payload; the caller interprets `status`.
Future<Map<String, dynamic>> redeemInviteLink(String code) async {
  final res = await Supabase.instance.client
      .rpc('redeem_lobby_invite_link', params: {'p_code': code})
      .timeout(const Duration(seconds: 5));
  return res as Map<String, dynamic>;
}
