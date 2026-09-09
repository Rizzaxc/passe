import 'package:easy_localization/easy_localization.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/model/challenge.dart';
import '../activity/upcoming_controller.dart';

part 'friendly_challenge_controller.g.dart';

/// One row of `friendly_challenge_data` — a live friendly challenge involving
/// this lobby.
///
/// Everything here is already in THIS lobby's frame: [myReport] is flipped by
/// the RPC, and [weAreHome] is what the structural terms ([costSplit],
/// [handicapSide]) resolve against. Never flip a result in widget code — see
/// the header of `lib/core/model/challenge.dart`.
class FriendlyChallenge {
  final String id;
  final String otherLobbyId;
  final String otherLobbyName;
  final int? otherLobbyMmr;
  final int? otherLobbyTrust;
  final FriendlyChallengeStatus status;

  /// Home posted the offer; away answered it. Drives every "us/them" label.
  final bool weAreHome;

  final DateTime? proposedTime;
  final String? proposedLocationName;

  // Snapshotted terms — what this challenge was sent under, not what the
  // other lobby's offer says today.
  final double? venueCost;
  final ChallengeCostSplit costSplit;
  final ChallengeBountyKind bountyKind;
  final double? bountyAmount;
  final ChallengeRuleset ruleset;
  final int? rulesetParam;
  final ChallengeHandicapSide handicapSide;
  final int? handicapAmount;
  final String? termsNote;
  final String? note;

  /// This lobby's own activity for the fixture.
  final String? activityId;

  /// RSVP progress on the CHALLENGER's side — the threshold that has to be met
  /// before the handshake reaches home at all.
  final int goingCount;
  final int? confirmationThreshold;

  /// What we filed, in our own frame. Null until we report.
  final LobbyMatchResult? myReport;
  final bool myReportForfeit;

  /// Whether the opponent has filed. Deliberately a bare bool — their actual
  /// answer is withheld by RLS until the match resolves, so there is nothing
  /// to leak here even if a widget wanted to show it.
  final bool opponentReported;

  final String? noShowClaimedBy;
  final DateTime? noShowClaimedAt;

  const FriendlyChallenge({
    required this.id,
    required this.otherLobbyId,
    required this.otherLobbyName,
    required this.otherLobbyMmr,
    required this.otherLobbyTrust,
    required this.status,
    required this.weAreHome,
    required this.proposedTime,
    required this.proposedLocationName,
    required this.venueCost,
    required this.costSplit,
    required this.bountyKind,
    required this.bountyAmount,
    required this.ruleset,
    required this.rulesetParam,
    required this.handicapSide,
    required this.handicapAmount,
    required this.termsNote,
    required this.note,
    required this.activityId,
    required this.goingCount,
    required this.confirmationThreshold,
    required this.myReport,
    required this.myReportForfeit,
    required this.opponentReported,
    required this.noShowClaimedBy,
    required this.noShowClaimedAt,
  });

  /// What we reported, phrased from our own side, for showing a filed report
  /// back to its author.
  MatchOutcome? get myOutcome =>
      MatchOutcome.fromCallerFramedResult(myReport, isForfeit: myReportForfeit);

  bool get iHaveReported => myReport != null;

  /// The window opens at the final whistle. The server is the authority
  /// (`report_match_result` re-checks `end_time`); this only decides whether
  /// to offer the button.
  bool get isReportable =>
      status == FriendlyChallengeStatus.scheduled ||
      status == FriendlyChallengeStatus.awaitingReports;

  factory FriendlyChallenge.fromJson(Map<String, dynamic> m) {
    DateTime? at(String k) {
      final v = m[k] as String?;
      return v == null ? null : DateTime.parse(v).toLocal();
    }

    // Supabase hands `numeric` back as String.
    double? num_(String k) {
      final v = m[k];
      if (v == null) return null;
      return v is num ? v.toDouble() : double.tryParse(v.toString());
    }

    return FriendlyChallenge(
      id: m['id'] as String,
      otherLobbyId: m['other_lobby_id'] as String,
      otherLobbyName: m['other_lobby_name'] as String? ?? '',
      otherLobbyMmr: (m['other_lobby_mmr'] as num?)?.toInt(),
      otherLobbyTrust: (m['other_lobby_trust'] as num?)?.toInt(),
      status:
          FriendlyChallengeStatus.fromDb(m['status'] as String?) ??
          FriendlyChallengeStatus.requested,
      weAreHome: m['we_are_home'] as bool? ?? false,
      proposedTime: at('proposed_time'),
      proposedLocationName: m['proposed_location_name'] as String?,
      venueCost: num_('venue_cost'),
      costSplit:
          ChallengeCostSplit.fromDb(m['cost_split'] as String?) ??
          ChallengeCostSplit.none,
      bountyKind:
          ChallengeBountyKind.fromDb(m['bounty_kind'] as String?) ??
          ChallengeBountyKind.none,
      bountyAmount: num_('bounty_amount'),
      ruleset:
          ChallengeRuleset.fromDb(m['ruleset'] as String?) ??
          ChallengeRuleset.standard,
      rulesetParam: (m['ruleset_param'] as num?)?.toInt(),
      handicapSide:
          ChallengeHandicapSide.fromDb(m['handicap_side'] as String?) ??
          ChallengeHandicapSide.none,
      handicapAmount: (m['handicap_amount'] as num?)?.toInt(),
      termsNote: m['terms_note'] as String?,
      note: m['note'] as String?,
      activityId: m['activity_id'] as String?,
      goingCount: (m['going_count'] as num?)?.toInt() ?? 0,
      confirmationThreshold: (m['confirmation_threshold'] as num?)?.toInt(),
      myReport: LobbyMatchResult.fromDb(m['my_report'] as String?),
      myReportForfeit: m['my_report_forfeit'] as bool? ?? false,
      opponentReported: m['opponent_reported'] as bool? ?? false,
      noShowClaimedBy: m['no_show_claimed_by'] as String?,
      noShowClaimedAt: at('no_show_claimed_at'),
    );
  }
}

/// Live friendly challenges for a lobby, both directions.
@riverpod
class FriendlyChallengesController extends _$FriendlyChallengesController {
  @override
  Future<List<FriendlyChallenge>> build(String lobbyId) async {
    final response = await Supabase.instance.client
        .rpc('friendly_challenge_data', params: {'p_lobby_id': lobbyId})
        .timeout(const Duration(seconds: 5));

    return (response as List)
        .map((r) => FriendlyChallenge.fromJson(r as Map<String, dynamic>))
        .toList();
  }
}

/// One lobby's blind result report.
///
/// The opponent files separately and neither side sees the other until both
/// are in — enforced by RLS on `lobby_challenge_report`, not by this class.
@riverpod
class ReportMatchResultController extends _$ReportMatchResultController {
  @override
  bool build(String lobbyId) => false; // in-flight flag

  /// Returns what the server concluded: `awaiting_opponent`, `agreed`,
  /// `mutual_concession`, `no_match` or `disputed`.
  ///
  /// [sets] is entered OUR-side-first (`[us, them]` per set); the RPC flips it
  /// for the away team, since sets are stored home-first on disk.
  Future<String> report({
    required String challengeId,
    required MatchOutcome outcome,
    List<List<int>>? sets,
    String? note,
  }) async {
    state = true;
    try {
      final result = await Supabase.instance.client
          .rpc(
            'report_match_result',
            params: {
              'p_challenge_id': challengeId,
              'p_result': outcome.rpcValue,
              'p_sets': sets,
              'p_note': note,
            },
          )
          .timeout(const Duration(seconds: 5));

      ref.invalidate(friendlyChallengesControllerProvider(lobbyId));
      ref.invalidate(lobbyUpcomingActivitiesControllerProvider(lobbyId));
      return result as String? ?? 'awaiting_opponent';
    } finally {
      state = false;
    }
  }
}

/// The in-match no-show claim, its counter, and withdrawing a challenge.
///
/// The claim window is live rather than post-match on purpose: the team
/// standing on an empty pitch should be able to go home knowing where it
/// stands, not wait a day for the reporting window. The accused gets 10
/// minutes; the sweep settles it as a walkover if nobody answers, and as a
/// dispute if they do.
@riverpod
class FriendlyChallengeActionsController
    extends _$FriendlyChallengeActionsController {
  @override
  bool build(String lobbyId) => false; // in-flight flag

  Future<void> _call(String rpc, String challengeId) async {
    state = true;
    try {
      await Supabase.instance.client
          .rpc(rpc, params: {'p_challenge_id': challengeId})
          .timeout(const Duration(seconds: 5));
      ref.invalidate(friendlyChallengesControllerProvider(lobbyId));
      ref.invalidate(lobbyUpcomingActivitiesControllerProvider(lobbyId));
    } finally {
      state = false;
    }
  }

  Future<void> claimNoShow(String challengeId) =>
      _call('claim_no_show', challengeId);

  Future<void> counterNoShow(String challengeId) =>
      _call('counter_no_show', challengeId);

  /// Withdraw before the handshake completes. Allowed only while the challenge
  /// is still gathering players or waiting on the home lobby.
  Future<void> cancel(String challengeId) =>
      _call('cancel_friendly_challenge', challengeId);
}

/// Maps the no-show and withdraw guards onto Vietnamese copy.
String friendlyChallengeActionErrorMessage(Object e) {
  final msg = e.toString();
  if (msg.contains('too early')) {
    return 'challenge.noShow.errorTooEarly'.tr();
  }
  if (msg.contains('match has ended')) {
    return 'challenge.noShow.errorEnded'.tr();
  }
  if (msg.contains('already made this claim')) {
    return 'challenge.noShow.errorAlready'.tr();
  }
  if (msg.contains('window to answer has closed')) {
    return 'challenge.noShow.errorWindowClosed'.tr();
  }
  if (msg.contains('no claim to answer')) {
    return 'challenge.noShow.errorNoClaim'.tr();
  }
  if (msg.contains('can no longer be withdrawn')) {
    return 'challenge.cancel.errorTooLate'.tr();
  }
  if (msg.contains('not a manager')) {
    return 'challenge.noShow.errorManagerOnly'.tr();
  }
  return 'challenge.noShow.errorGeneric'.tr();
}

/// Maps `report_match_result`'s guards onto Vietnamese copy.
String reportResultErrorMessage(Object e) {
  final msg = e.toString();
  if (msg.contains('has not finished')) {
    return 'challenge.report.errorTooEarly'.tr();
  }
  if (msg.contains('not open for reporting')) {
    return 'challenge.report.errorClosed'.tr();
  }
  if (msg.contains('not a manager')) {
    return 'challenge.report.errorManagerOnly'.tr();
  }
  return 'challenge.report.errorGeneric'.tr();
}
