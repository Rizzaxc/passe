import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'invite_challenge_controller.g.dart';

/// Thrown when a target lobby can't be resolved from a SearchID.
class ChallengeTargetNotFound implements Exception {
  const ChallengeTargetNotFound();
}

/// Send a challenge from one lobby to another (lobby-vs-lobby "Thách đấu").
///
/// Backed by the `send_challenge` RPC (schema/lobby_challenge.sql), which
/// validates that the caller manages the initiating lobby, the target is
/// `open_to_challengers` in the same sport, and enqueues a `challenge_received`
/// push to the target's managers.
@riverpod
class InviteChallengeController extends _$InviteChallengeController {
  late String _initiatorLobbyId;

  @override
  bool build(String initiatorLobbyId) {
    _initiatorLobbyId = initiatorLobbyId;
    return false; // in-flight flag
  }

  /// Send a challenge. Provide either [targetLobbyId] (from a feed row) or
  /// [targetSearchId] (the human-shareable code entered by the user).
  Future<void> invite({
    String? targetLobbyId,
    String? targetSearchId,
    DateTime? proposedAt,
    String? note,
  }) async {
    state = true;
    try {
      final supabase = Supabase.instance.client;

      var lobbyId = targetLobbyId;
      if (lobbyId == null && targetSearchId != null) {
        final row = await supabase
            .from('lobby')
            .select('id')
            .eq('searchable_id', targetSearchId)
            .maybeSingle()
            .timeout(const Duration(seconds: 5));
        if (row == null) throw const ChallengeTargetNotFound();
        lobbyId = row['id'] as String;
      }
      if (lobbyId == null) throw const ChallengeTargetNotFound();

      await supabase.rpc('send_challenge', params: {
        'p_initiator_lobby': _initiatorLobbyId,
        'p_target_lobby': lobbyId,
        'p_proposed_time': proposedAt?.toUtc().toIso8601String(),
        'p_note': note,
      }).timeout(const Duration(seconds: 5));
    } finally {
      state = false;
    }
  }
}
