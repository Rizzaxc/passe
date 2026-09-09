import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/model/lobby.dart';

part 'freeplay_expose_controller.g.dart';

/// What the activity card needs to decide whether "mở chỗ trống" (expose seats
/// for freeplay) can be offered at all.
///
/// Exposure is only available to a **non-private** lobby — the whole point is
/// that strangers can find and request the seat, and `get_lobby_public_preview`
/// (the owner chip a browsing player taps) refuses private lobbies for the same
/// reason. The server enforces this in `fn_freeplay_activity_owner_guard`; this
/// is only so the CTA isn't offered where it would always fail.
///
/// [homeGroundId] is carried because `expose_lobby_activity_freeplay` pins the
/// activity's `location_id` to the lobby's home ground when the activity has
/// none — a lobby with neither has to type a venue into the sheet.
class LobbyExposureContext {
  final LobbyVisibility visibility;
  final String? homeGroundId;
  final String? homeGroundName;

  const LobbyExposureContext({
    required this.visibility,
    this.homeGroundId,
    this.homeGroundName,
  });

  static const unknown = LobbyExposureContext(
    visibility: LobbyVisibility.private,
  );

  bool get canExpose => visibility != LobbyVisibility.private;
}

@riverpod
Future<LobbyExposureContext> lobbyExposureContext(Ref ref, String lobbyId) async {
  final row = await Supabase.instance.client
      .from('lobby')
      .select('visibility, lobby_homeground(is_primary, location(id, name))')
      .eq('id', lobbyId)
      .maybeSingle()
      .timeout(const Duration(seconds: 5));
  if (row == null) return LobbyExposureContext.unknown;
  final ghRows = (row['lobby_homeground'] as List?) ?? [];
  final primary = ghRows.cast<Map>().firstWhere(
    (g) => g['is_primary'] == true,
    orElse: () => const {},
  );
  final primaryLoc = primary['location'] as Map<String, dynamic>?;
  return LobbyExposureContext(
    visibility: LobbyVisibility.values.firstWhere(
      (value) => value.name == row['visibility'],
      orElse: () => LobbyVisibility.discoverable,
    ),
    homeGroundId: primaryLoc?['id'] as String?,
    homeGroundName: primaryLoc?['name'] as String?,
  );
}

/// Whether the lobby currently advertises seats on the freeplay feed.
///
/// A lobby with a live listing cannot be made private — the server raises
/// `lobby_private_blocked_by_freeplay` rather than stranding outsiders who
/// already hold a seat. This is the client mirror, so the option is refused
/// with an explanation instead of a generic save failure.
@riverpod
Future<bool> lobbyHasLiveFreeplay(Ref ref, String lobbyId) async {
  final result = await Supabase.instance.client
      .rpc('fn_lobby_has_live_freeplay', params: {'p_lobby_id': lobbyId})
      .timeout(const Duration(seconds: 5));
  return result == true;
}
