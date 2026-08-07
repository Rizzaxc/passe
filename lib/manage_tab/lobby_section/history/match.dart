import '../activity/upcoming_controller.dart';

/// A chronological entry in a lobby's History tab. Matches and completed
/// activities deliberately share a timeline, but only matches contribute to
/// the competitive record.
sealed class LobbyHistoryEntry {
  const LobbyHistoryEntry();

  String get id;
  DateTime get occurredAt;
  bool get isChallenge;
  bool get isPractice;
}

/// A recorded match from `lobby_match`.
class LobbyMatch extends LobbyHistoryEntry {
  @override
  final String id;
  final String date;
  final String when;
  final String? opponent;
  final String opponentTag;
  final LobbyMatchResult result;
  final List<(int us, int them)>? sets;
  final String? mvp;
  final String venue;
  final List<String> members;
  final String? note;

  /// FK to the `professional_booking` row that hired a referee for
  /// this match. Required at the DB level for challenge matches
  /// (`opponent != null`), so non-null whenever this lobby played a
  /// real opponent. Null for internal practice.
  final String? refereeBookingId;
  final String? refereeName;

  /// The underlying activity when this match came from a challenge. Used to
  /// avoid rendering the same completed session twice in the unified timeline.
  final String? activityId;

  @override
  final DateTime occurredAt;

  const LobbyMatch({
    required this.id,
    required this.date,
    required this.when,
    this.opponent,
    required this.opponentTag,
    required this.result,
    this.sets,
    this.mvp,
    required this.venue,
    required this.members,
    this.note,
    this.refereeBookingId,
    this.refereeName,
    this.activityId,
    required this.occurredAt,
  });

  bool get isWin => result == LobbyMatchResult.win;
  bool get isLoss => result == LobbyMatchResult.loss;
  bool get isDraw => result == LobbyMatchResult.draw;
  @override
  bool get isPractice => result == LobbyMatchResult.practice;

  /// A challenge is any match against an opponent lobby. A *scored* one
  /// (win/loss/draw) always carries a referee booking — the DB enforces
  /// that ("ref = rated"). An unrefereed challenge is still logged for both
  /// sides, just with no score: it's a challenge match with `result ==
  /// practice`, indistinguishable at the DB level from an internal scrimmage
  /// except for [opponent] being set — [isScorelessEncounter] is that case.
  @override
  bool get isChallenge => opponent != null;
  bool get isScorelessEncounter => isChallenge && isPractice;
}

/// A completed lobby activity that did not produce a `lobby_match` row.
/// Scheduling has no separate completion column, so `end_time` (or
/// `start_time` for older rows without one) is the completion signal.
class PastLobbyActivity extends LobbyHistoryEntry {
  final UpcomingActivity activity;

  const PastLobbyActivity(this.activity);

  @override
  String get id => activity.activity.id!;

  @override
  DateTime get occurredAt => activity.nextEnd ?? activity.nextStart;

  @override
  bool get isChallenge => activity.challenge != null;

  @override
  bool get isPractice => !isChallenge;
}

class LobbyHistory {
  final List<LobbyHistoryEntry> entries;

  const LobbyHistory(this.entries);

  List<LobbyMatch> get matches =>
      entries.whereType<LobbyMatch>().toList(growable: false);
}

enum LobbyMatchResult { win, loss, draw, practice }

/// Win / loss / draw / total / win-rate roll-up across a match list.
class LobbyMatchStats {
  final int total;
  final int wins;
  final int losses;
  final int draws;
  final int winRate; // 0–100, computed against decisive matches only

  const LobbyMatchStats({
    required this.total,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.winRate,
  });

  factory LobbyMatchStats.from(List<LobbyMatch> matches) {
    final wins = matches.where((m) => m.isWin).length;
    final losses = matches.where((m) => m.isLoss).length;
    final draws = matches.where((m) => m.isDraw).length;
    final decided = wins + losses + draws;
    return LobbyMatchStats(
      total: matches.length,
      wins: wins,
      losses: losses,
      draws: draws,
      winRate: decided > 0 ? (wins * 100 ~/ decided) : 0,
    );
  }
}
