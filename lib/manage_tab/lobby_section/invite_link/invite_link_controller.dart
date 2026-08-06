import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'invite_link_controller.g.dart';

/// The active (non-revoked, non-expired) invite link for a lobby, or null if
/// none exists yet. Only ever one active row per lobby — see
/// `schema/lobby_invite_link.sql`.
class LobbyInviteLink {
  final String code;
  final DateTime? expiresAt;

  const LobbyInviteLink({required this.code, this.expiresAt});
}

@riverpod
class InviteLinkController extends _$InviteLinkController {
  @override
  Future<LobbyInviteLink?> build(String lobbyId) async {
    final row = await Supabase.instance.client
        .from('lobby_invite_link')
        .select('code, expires_at')
        .eq('lobby_id', lobbyId)
        .isFilter('revoked_at', null)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle()
        .timeout(const Duration(seconds: 5));

    if (row == null) return null;

    final expiresAtRaw = row['expires_at'] as String?;
    final expiresAt = expiresAtRaw != null
        ? DateTime.parse(expiresAtRaw).toLocal()
        : null;
    // A row can still be un-revoked but past its own expiry (the sweep isn't
    // instant) — treat that the same as "no active link" client-side.
    if (expiresAt != null && expiresAt.isBefore(DateTime.now())) return null;

    return LobbyInviteLink(code: row['code'] as String, expiresAt: expiresAt);
  }

  /// Generate (or regenerate) the lobby's invite link. Manage-tier gated
  /// server-side by `generate_lobby_invite_link`; any previously active link
  /// is revoked in the same call.
  Future<void> generate({Duration? expiresIn}) async {
    await Supabase.instance.client
        .rpc(
          'generate_lobby_invite_link',
          params: {
            'p_lobby_id': lobbyId,
            if (expiresIn != null) 'p_expires_in': _toPgInterval(expiresIn),
          },
        )
        .timeout(const Duration(seconds: 5));
    ref.invalidateSelf();
  }

  /// Remove the active link without replacing it.
  Future<void> revoke() async {
    await Supabase.instance.client
        .rpc('revoke_lobby_invite_link', params: {'p_lobby_id': lobbyId})
        .timeout(const Duration(seconds: 5));
    ref.invalidateSelf();
  }
}

/// Postgres `interval` accepts an ISO-8601-ish duration string; `days`/
/// `seconds` covers every option this feature offers (never/1 day/7 days).
String _toPgInterval(Duration d) => '${d.inSeconds} seconds';
