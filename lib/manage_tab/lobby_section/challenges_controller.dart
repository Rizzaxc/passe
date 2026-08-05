import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'activity/upcoming_controller.dart';

part 'challenges_controller.g.dart';

/// One row from `lobby_challenge_data` — a challenge involving this lobby,
/// seen from its perspective (`direction` = incoming/outgoing).
class LobbyChallenge {
  final String id;
  final String direction; // 'incoming' | 'outgoing'
  final String otherLobbyId;
  final String otherLobbyName;
  final int? otherLobbyMmr;

  /// 'requested' | 'accepted' | 'scheduled'. The RPC filters out the terminal
  /// states (declined / cancelled / played / lapsed) so the list can't grow
  /// without bound.
  final String status;

  /// The agreed terms, snapshotted from the home lobby's offer when the
  /// challenge was sent — not a live read of that lobby's current offer.
  final DateTime? proposedTime;
  final String? proposedLocationName;
  final double? agreedCost;

  final String? note;

  /// This lobby's own activity for the match; null until the challenge is
  /// accepted.
  final String? activityId;

  /// Whether a referee has been hired for the match (either side's activity).
  final bool refereeBooked;

  const LobbyChallenge({
    required this.id,
    required this.direction,
    required this.otherLobbyId,
    required this.otherLobbyName,
    required this.otherLobbyMmr,
    required this.status,
    required this.proposedTime,
    required this.proposedLocationName,
    required this.agreedCost,
    required this.note,
    required this.activityId,
    required this.refereeBooked,
  });

  bool get isIncoming => direction == 'incoming';
  bool get isOpen => status == 'requested';
  bool get isScheduled => status == 'scheduled';
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
        proposedLocationName: m['proposed_location_name'] as String?,
        agreedCost: double.tryParse(m['agreed_cost']?.toString() ?? ''),
        note: m['note'] as String?,
        activityId: m['activity_id'] as String?,
        refereeBooked: (m['referee_booked'] as bool?) ?? false,
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

/// Locks in this lobby's half of an accepted challenge.
///
/// RSVP quorum alone doesn't make a challenge official — a manager has to
/// confirm too, and the match only flips to `scheduled` once *both* lobbies
/// have. The RPC enforces the quorum and the manager gate; this just surfaces
/// the outcome and refreshes what the hero shows.
@riverpod
class ConfirmChallengeActivityController
    extends _$ConfirmChallengeActivityController {
  @override
  bool build(String lobbyId) => false; // in-flight flag

  Future<void> confirm(String activityId) async {
    state = true;
    try {
      await Supabase.instance.client.rpc('confirm_challenge_activity', params: {
        'p_activity_id': activityId,
      }).timeout(const Duration(seconds: 5));
      ref.invalidate(lobbyUpcomingActivityControllerProvider(lobbyId));
      ref.invalidate(lobbyChallengesControllerProvider(lobbyId));
    } finally {
      state = false;
    }
  }
}

/// Maps `confirm_challenge_activity`'s guards onto Vietnamese copy.
String confirmChallengeErrorMessage(Object e) {
  final msg = e.toString();
  if (msg.contains('not enough confirmations')) {
    return 'Chưa đủ thành viên xác nhận tham gia';
  }
  if (msg.contains('not a manager')) {
    return 'Chỉ đội trưởng hoặc điều phối viên mới xác nhận được';
  }
  return 'Không thể xác nhận trận đấu';
}

/// Count of open incoming challenges — drives the badge on the lobby detail.
@riverpod
Future<int> incomingChallengeCount(Ref ref, String lobbyId) async {
  final list = await ref.watch(lobbyChallengesControllerProvider(lobbyId).future);
  return list.where((c) => c.isIncoming && c.isOpen).length;
}
