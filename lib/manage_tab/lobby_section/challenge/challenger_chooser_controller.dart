import 'package:easy_localization/easy_localization.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/model/challenge.dart';
import '../activity/upcoming_controller.dart';
import 'friendly_challenge_controller.dart';

part 'challenger_chooser_controller.g.dart';

/// A lobby that has committed its own players and is waiting on our answer —
/// one row of `pending_home_challengers`.
///
/// Home only ever sees challengers who already cleared their own RSVP
/// threshold. A lobby still gathering players is invisible here on purpose:
/// there is nothing to act on, and it would leak who is merely considering us.
class PendingChallenger {
  final String challengeId;
  final String? offerId;
  final int? offerSlot;

  final String lobbyId;
  final String lobbyName;
  final int? mmr;
  final int? trustScore;
  final int ratedMatchCount;
  final int memberCount;
  final String? description;
  final String? homegroundName;

  /// How many of theirs confirmed, against the threshold they set themselves.
  final int goingCount;
  final int? confirmationThreshold;

  final DateTime? kickoff;
  final String? locationName;
  final String? note;
  final DateTime? createdAt;

  /// All-time verdict tallies, keyed by [LobbyRecommendationKind.dbValue].
  final Map<LobbyRecommendationKind, int> recommendations;

  const PendingChallenger({
    required this.challengeId,
    required this.offerId,
    required this.offerSlot,
    required this.lobbyId,
    required this.lobbyName,
    required this.mmr,
    required this.trustScore,
    required this.ratedMatchCount,
    required this.memberCount,
    required this.description,
    required this.homegroundName,
    required this.goingCount,
    required this.confirmationThreshold,
    required this.kickoff,
    required this.locationName,
    required this.note,
    required this.createdAt,
    required this.recommendations,
  });

  /// Baseline is 40 and negative is the signal — worth calling out rather than
  /// leaving the reader to know what a good number looks like.
  bool get isLowTrust => (trustScore ?? 40) < 0;

  /// A lobby with too few rated matches has an MMR that is mostly its members'
  /// self-declared `elo_seed`, so it is shown as provisional rather than earned
  /// — the same posture `LobbyFeedItem.hasProvisionalMmr` takes.
  bool get hasProvisionalMmr => ratedMatchCount < 5;

  Iterable<MapEntry<LobbyRecommendationKind, int>> get topVerdicts =>
      (recommendations.entries.where((e) => e.value > 0).toList()
            ..sort((a, b) => b.value.compareTo(a.value)))
          .take(3);

  factory PendingChallenger.fromJson(Map<String, dynamic> m) {
    DateTime? at(String k) {
      final v = m[k] as String?;
      return v == null ? null : DateTime.parse(v).toLocal();
    }

    final counts = <LobbyRecommendationKind, int>{};
    final raw = m['recommendation_counts'];
    if (raw is Map) {
      raw.forEach((k, v) {
        final kind = LobbyRecommendationKind.fromDb(k as String?);
        if (kind != null) counts[kind] = (v as num?)?.toInt() ?? 0;
      });
    }

    return PendingChallenger(
      challengeId: m['challenge_id'] as String,
      offerId: m['offer_id'] as String?,
      offerSlot: (m['offer_slot'] as num?)?.toInt(),
      lobbyId: m['initiator_lobby_id'] as String,
      lobbyName: m['initiator_name'] as String? ?? '',
      mmr: (m['initiator_mmr'] as num?)?.toInt(),
      trustScore: (m['trust_score'] as num?)?.toInt(),
      ratedMatchCount: (m['rated_match_count'] as num?)?.toInt() ?? 0,
      memberCount: (m['member_count'] as num?)?.toInt() ?? 0,
      description: m['description'] as String?,
      homegroundName: m['homeground_name'] as String?,
      goingCount: (m['going_count'] as num?)?.toInt() ?? 0,
      confirmationThreshold: (m['confirmation_threshold'] as num?)?.toInt(),
      kickoff: at('kickoff'),
      locationName: m['location_name'] as String?,
      note: m['note'] as String?,
      createdAt: at('created_at'),
      recommendations: counts,
    );
  }
}

/// Challengers waiting on this lobby's answer.
@riverpod
class PendingChallengersController extends _$PendingChallengersController {
  @override
  Future<List<PendingChallenger>> build(String lobbyId) async {
    final response = await Supabase.instance.client
        .rpc('pending_home_challengers', params: {'p_lobby_id': lobbyId})
        .timeout(const Duration(seconds: 5));

    return (response as List)
        .map((r) => PendingChallenger.fromJson(r as Map<String, dynamic>))
        .toList();
  }
}

/// Home's answer. Accepting is not just a yes — it spends the offer slot and
/// declines every other lobby waiting on it, which is why the sheet says so
/// before the button is pressed.
@riverpod
class RespondFriendlyChallengeController
    extends _$RespondFriendlyChallengeController {
  @override
  String? build(String lobbyId) => null; // challengeId currently in flight

  Future<void> respond(String challengeId, {required bool accept}) async {
    state = challengeId;
    try {
      await Supabase.instance.client
          .rpc(
            'respond_friendly_challenge',
            params: {
              'p_challenge_id': challengeId,
              'p_action': accept ? 'accept' : 'decline',
            },
          )
          .timeout(const Duration(seconds: 5));

      ref.invalidate(pendingChallengersControllerProvider(lobbyId));
      ref.invalidate(friendlyChallengesControllerProvider(lobbyId));
      ref.invalidate(lobbyUpcomingActivitiesControllerProvider(lobbyId));
    } finally {
      state = null;
    }
  }
}

/// Maps `respond_friendly_challenge`'s guards onto Vietnamese copy.
String respondFriendlyChallengeErrorMessage(Object e) {
  final msg = e.toString();
  if (msg.contains('not waiting on you')) {
    return 'challenge.chooser.errorAlreadyAnswered'.tr();
  }
  if (msg.contains('not a manager')) {
    return 'challenge.chooser.errorManagerOnly'.tr();
  }
  return 'challenge.chooser.errorGeneric'.tr();
}

/// Badge count for the lobby detail — how many lobbies are waiting on us.
@riverpod
Future<int> pendingChallengerCount(Ref ref, String lobbyId) async {
  final list = await ref.watch(
    pendingChallengersControllerProvider(lobbyId).future,
  );
  return list.length;
}
