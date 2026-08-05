/// A played-out match for a lobby — the row model behind the
/// "Lịch sử trận đấu" tab. Backed by the `lobby_match` table via the
/// `lobby_match_history_data` RPC (read) and `RecordMatchController` (write).
class LobbyMatch {
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
  });

  bool get isWin => result == LobbyMatchResult.win;
  bool get isLoss => result == LobbyMatchResult.loss;
  bool get isDraw => result == LobbyMatchResult.draw;
  bool get isPractice => result == LobbyMatchResult.practice;

  /// A challenge is any match against an opponent lobby. A *scored* one
  /// (win/loss/draw) always carries a referee booking — the DB enforces
  /// that ("ref = rated"). An unrefereed challenge is still logged for both
  /// sides, just with no score: it's a challenge match with `result ==
  /// practice`, indistinguishable at the DB level from an internal scrimmage
  /// except for [opponent] being set — [isScorelessEncounter] is that case.
  bool get isChallenge => opponent != null;
  bool get isScorelessEncounter => isChallenge && isPractice;
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
