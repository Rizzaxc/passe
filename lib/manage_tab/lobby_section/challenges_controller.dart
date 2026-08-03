import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'challenges_controller.g.dart';

/// One row from `lobby_challenge_data` — a challenge involving this lobby,
/// seen from its perspective (`direction` = incoming/outgoing).
class LobbyChallenge {
  final String id;
  final String direction; // 'incoming' | 'outgoing'
  final String otherLobbyId;
  final String otherLobbyName;
  final int? otherLobbyMmr;
  final String status; // 'requested' | 'accepted'
  final DateTime? proposedTime;
  final String? note;

  const LobbyChallenge({
    required this.id,
    required this.direction,
    required this.otherLobbyId,
    required this.otherLobbyName,
    required this.otherLobbyMmr,
    required this.status,
    required this.proposedTime,
    required this.note,
  });

  bool get isIncoming => direction == 'incoming';
  bool get isOpen => status == 'requested';
}

/// Open + accepted challenges for a lobby, both directions. Managers accept /
/// decline incoming ones and cancel their own outgoing ones.
@riverpod
class LobbyChallengesController extends _$LobbyChallengesController {
  final supabase = Supabase.instance.client;

  @override
  Future<List<LobbyChallenge>> build(String lobbyId) async {
    final response = await supabase
        .rpc('lobby_challenge_data', params: {'p_lobby_id': lobbyId})
        .timeout(const Duration(seconds: 5));

    return (response as List).map((row) {
      final m = row as Map<String, dynamic>;
      final t = m['proposed_time'] as String?;
      return LobbyChallenge(
        id: m['id'] as String,
        direction: m['direction'] as String,
        otherLobbyId: m['other_lobby_id'] as String,
        otherLobbyName: m['other_lobby_name'] as String? ?? '',
        otherLobbyMmr: (m['other_lobby_mmr'] as num?)?.toInt(),
        status: (m['status'] as String?) ?? 'requested',
        proposedTime: t != null ? DateTime.parse(t).toLocal() : null,
        note: m['note'] as String?,
      );
    }).toList();
  }

  /// Accept or decline an incoming challenge (target-manager only, enforced by
  /// the `respond_challenge` RPC).
  Future<void> respond(String challengeId, String action) async {
    await supabase.rpc('respond_challenge', params: {
      'p_challenge_id': challengeId,
      'p_action': action,
    }).timeout(const Duration(seconds: 5));
    ref.invalidateSelf();
  }

  /// Cancel an outgoing challenge (initiator-manager only).
  Future<void> cancel(String challengeId) async {
    await supabase.rpc('cancel_challenge', params: {
      'p_challenge_id': challengeId,
    }).timeout(const Duration(seconds: 5));
    ref.invalidateSelf();
  }
}

/// Count of open incoming challenges — drives the badge on the lobby detail.
@riverpod
Future<int> incomingChallengeCount(Ref ref, String lobbyId) async {
  final list = await ref.watch(lobbyChallengesControllerProvider(lobbyId).future);
  return list.where((c) => c.isIncoming && c.isOpen).length;
}
