import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// Models for the friendly (referee-free) challenge mode.
/// Schema: `schema/friendly_challenge*.sql`.
///
/// ## The one rule that matters here
///
/// **Every result the server hands the client is already in the CALLER's own
/// frame.** `win` always means "we won", never "the home team won".
///
/// The database stores results in the *home* frame, because one physical
/// `lobby_match` row has to read correctly from both ends — writing a mirror
/// row would let the two sides drift. The flip back happens in exactly two
/// places, both SQL: `lobby_match_history_data` (history) and
/// `friendly_challenge_data`'s `my_report` (the live fixture).
///
/// So: **never flip a result in widget code.** If a screen appears to be
/// showing the away team a win when they lost, the bug is in the RPC, not in
/// the widget, and fixing it in the widget will break the home team instead.
///
/// Structural terms — who pays, who is spotted a handicap, who claimed a
/// no-show — *are* absolute (`home`/`away`), deliberately: an offer card being
/// browsed by a stranger genuinely wants to say "chủ nhà được chấp 2 bàn".
/// Those are resolved to "us"/"them" by [ChallengeParty.resolve], which is the
/// only place that mapping is allowed to live.

// ─────────────────────────────────────────────────────────────────────────────
// Perspective
// ─────────────────────────────────────────────────────────────────────────────

/// Who a term refers to, from the reader's point of view.
///
/// This exists so `weAreHome` is consumed once, at the edge, instead of being
/// re-derived with a `?:` at every render site — which is how the away team
/// ends up being told the other lobby is paying for the pitch.
enum ChallengeParty {
  us,
  them,
  /// Decided by the result rather than by side — "bên thua trả".
  loser,
  both,
  nobody;

  String getLocalizedName(BuildContext context) =>
      context.tr('challenge.party.$name');
}

// ─────────────────────────────────────────────────────────────────────────────
// Offer terms
// ─────────────────────────────────────────────────────────────────────────────

/// How the two lobbies agreed to split the pitch fee. The app never moves
/// money (see CLAUDE.md ▸ đá currency is deferred) — this is a stated term the
/// two sides settle between themselves.
enum ChallengeCostSplit {
  none('none'),
  splitEven('split_even'),
  loserPays('loser_pays'),
  homePays('home_pays'),
  awayPays('away_pays');

  /// The value this enum has in Postgres.
  final String dbValue;

  const ChallengeCostSplit(this.dbValue);

  static ChallengeCostSplit? fromDb(String? v) {
    for (final e in ChallengeCostSplit.values) {
      if (e.dbValue == v) return e;
    }
    return null;
  }

  /// Absolute term → the reader's frame. The ONLY place home/away becomes
  /// us/them for cost.
  ChallengeParty resolve({required bool weAreHome}) => switch (this) {
    ChallengeCostSplit.none => ChallengeParty.nobody,
    ChallengeCostSplit.splitEven => ChallengeParty.both,
    ChallengeCostSplit.loserPays => ChallengeParty.loser,
    ChallengeCostSplit.homePays =>
      weAreHome ? ChallengeParty.us : ChallengeParty.them,
    ChallengeCostSplit.awayPays =>
      weAreHome ? ChallengeParty.them : ChallengeParty.us,
  };

  /// Reader-facing sentence, e.g. "Đội mình trả sân" / "Bên thua trả sân".
  String getLocalizedLabel(BuildContext context, {required bool weAreHome}) {
    final party = resolve(weAreHome: weAreHome);
    if (party == ChallengeParty.nobody) return context.tr('challenge.cost.none');
    return context.tr(
      'challenge.cost.paidBy',
      namedArgs: {'party': party.getLocalizedName(context)},
    );
  }

  /// Absolute phrasing, for a stranger browsing an offer they are not part of.
  String getLocalizedNeutralLabel(BuildContext context) =>
      context.tr('challenge.cost.neutral.$name');
}

/// A side bet stated on the offer. Also never processed by the app.
enum ChallengeBountyKind {
  none('none'),
  perGoalDiff('per_goal_diff'),
  fixedPerTeam('fixed_per_team');

  /// The value this enum has in Postgres.
  final String dbValue;

  const ChallengeBountyKind(this.dbValue);

  static ChallengeBountyKind? fromDb(String? v) {
    for (final e in ChallengeBountyKind.values) {
      if (e.dbValue == v) return e;
    }
    return null;
  }

  bool get isSet => this != ChallengeBountyKind.none;

  String getLocalizedName(BuildContext context) =>
      context.tr('challenge.bounty.$name');
}

/// The match format. Only [bestOfSets] produces a set-by-set score, which is
/// why it is the only one where the Elo margin multiplier fires — every other
/// format is reported as a bare win/loss/draw.
enum ChallengeRuleset {
  standard('standard'),
  bestOfSets('best_of_sets'),
  kingOfTheHill('king_of_the_hill'),
  teamTie('team_tie'),
  custom('custom');

  /// The value this enum has in Postgres.
  final String dbValue;

  const ChallengeRuleset(this.dbValue);

  static ChallengeRuleset? fromDb(String? v) {
    for (final e in ChallengeRuleset.values) {
      if (e.dbValue == v) return e;
    }
    return null;
  }

  /// Whether the offer form must collect a number, and what it means.
  /// Mirrors `lobby_challenge_offer_ruleset_param_shape`.
  bool get takesParam =>
      this == ChallengeRuleset.bestOfSets || this == ChallengeRuleset.teamTie;

  /// Only this format has a scoreline worth entering on the report sheet.
  bool get hasSets => this == ChallengeRuleset.bestOfSets;

  /// Free text is the format, so the offer form must require a note.
  bool get requiresNote => this == ChallengeRuleset.custom;

  String getLocalizedName(BuildContext context, {int? param}) {
    if (takesParam && param != null) {
      return context.tr(
        'challenge.ruleset.withParam.$name',
        namedArgs: {'n': '$param'},
      );
    }
    return context.tr('challenge.ruleset.$name');
  }

  String getLocalizedDescription(BuildContext context) =>
      context.tr('challenge.ruleset.description.$name');
}

/// Which side is spotted a head start. Orthogonal to [ChallengeRuleset] —
/// a handicap composes with any format, and it is what lets a much stronger
/// lobby post a fixture a weaker one can meaningfully accept.
enum ChallengeHandicapSide {
  none('none'),
  home('home'),
  away('away');

  /// The value this enum has in Postgres.
  final String dbValue;

  const ChallengeHandicapSide(this.dbValue);

  static ChallengeHandicapSide? fromDb(String? v) {
    for (final e in ChallengeHandicapSide.values) {
      if (e.dbValue == v) return e;
    }
    return null;
  }

  ChallengeParty resolve({required bool weAreHome}) => switch (this) {
    ChallengeHandicapSide.none => ChallengeParty.nobody,
    ChallengeHandicapSide.home =>
      weAreHome ? ChallengeParty.us : ChallengeParty.them,
    ChallengeHandicapSide.away =>
      weAreHome ? ChallengeParty.them : ChallengeParty.us,
  };

  /// e.g. "Đội mình được chấp 2".
  String? getLocalizedLabel(
    BuildContext context, {
    required bool weAreHome,
    required int? amount,
  }) {
    if (this == ChallengeHandicapSide.none || amount == null) return null;
    return context.tr(
      'challenge.handicap.spotted',
      namedArgs: {
        'party': resolve(weAreHome: weAreHome).getLocalizedName(context),
        'amount': '$amount',
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Results — all caller-framed, see the file header
// ─────────────────────────────────────────────────────────────────────────────

/// A recorded result, **already flipped into the reader's frame** by the RPC.
/// `win` means "we won". Do not flip it again.
enum LobbyMatchResult {
  win('win'),
  loss('loss'),
  draw('draw'),
  practice('practice'),

  /// The two lobbies filed conflicting reports. Reads as itself from both
  /// ends — it is nobody's win — and cost both sides a loss in rating.
  disputed('disputed');

  /// The value this enum has in Postgres.
  final String dbValue;

  const LobbyMatchResult(this.dbValue);

  static LobbyMatchResult? fromDb(String? v) {
    for (final x in LobbyMatchResult.values) {
      if (x.dbValue == v) return x;
    }
    return null;
  }

  String getLocalizedName(BuildContext context) =>
      context.tr('challenge.result.$name');
}

/// Why a result stands. Drives the explanatory line under a history row, so a
/// rating drop is never unexplained.
enum MatchResultSource {
  referee('referee'),
  agreed('agreed'),
  oneSided('one_sided'),
  forfeit('forfeit'),
  mutualConcession('mutual_concession'),
  disputed('disputed');

  /// The value this enum has in Postgres.
  final String dbValue;

  const MatchResultSource(this.dbValue);

  static MatchResultSource? fromDb(String? v) {
    for (final e in MatchResultSource.values) {
      if (e.dbValue == v) return e;
    }
    return null;
  }

  /// Whether this outcome needs saying out loud on the card. An ordinary
  /// agreed result explains itself; the other four do not.
  bool get needsExplaining => this != MatchResultSource.agreed &&
      this != MatchResultSource.referee;

  String? getLocalizedExplanation(BuildContext context) =>
      needsExplaining ? context.tr('challenge.resultSource.$name') : null;
}

/// What a manager picks on the report sheet — phrased from **their own** side,
/// which is the whole point: an away manager is never asked whether "home won".
/// The server normalises to the home frame on the way in.
enum MatchOutcome {
  weWon('win'),
  weLost('loss'),
  draw('draw'),
  theyDidNotShow('no_show_them'),
  weDidNotShow('no_show_us');

  /// The `p_result` value `report_match_result` expects.
  final String rpcValue;

  const MatchOutcome(this.rpcValue);

  bool get isForfeit =>
      this == MatchOutcome.theyDidNotShow || this == MatchOutcome.weDidNotShow;

  String getLocalizedName(BuildContext context) =>
      context.tr('challenge.outcome.$name');

  /// Render a report the caller already filed. [result] must be caller-framed
  /// (`friendly_challenge_data.my_report` already is).
  static MatchOutcome? fromCallerFramedResult(
    LobbyMatchResult? result, {
    bool isForfeit = false,
  }) => switch (result) {
    LobbyMatchResult.win =>
      isForfeit ? MatchOutcome.theyDidNotShow : MatchOutcome.weWon,
    LobbyMatchResult.loss =>
      isForfeit ? MatchOutcome.weDidNotShow : MatchOutcome.weLost,
    LobbyMatchResult.draw => MatchOutcome.draw,
    _ => null,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Lifecycle
// ─────────────────────────────────────────────────────────────────────────────

/// Where a friendly challenge has got to. Several states read differently
/// depending on which side you are on — `pendingHome` is "waiting on them" to
/// the challenger and "your call" to the home lobby — so the label always
/// takes `weAreHome` rather than leaving each screen to remember.
enum FriendlyChallengeStatus {
  requested('requested'),
  pendingHome('pending_home'),
  scheduled('scheduled'),
  noShowClaimed('no_show_claimed'),
  awaitingReports('awaiting_reports'),
  played('played'),
  disputed('disputed'),
  declined('declined'),
  lapsed('lapsed'),
  cancelled('cancelled'),

  /// Refereed mode only; a friendly challenge never enters it.
  accepted('accepted');

  /// The value this enum has in Postgres.
  final String dbValue;

  const FriendlyChallengeStatus(this.dbValue);

  static FriendlyChallengeStatus? fromDb(String? v) {
    for (final x in FriendlyChallengeStatus.values) {
      if (x.dbValue == v) return x;
    }
    return null;
  }

  /// The fixture is dead — kept for the record, but nothing acts on it and it
  /// must not read as an upcoming session. Mirrors the SQL rule that a
  /// challenge activity is dead iff its challenge is in this set.
  bool get isDead =>
      this == FriendlyChallengeStatus.declined ||
      this == FriendlyChallengeStatus.lapsed ||
      this == FriendlyChallengeStatus.cancelled;

  bool get isSettled =>
      this == FriendlyChallengeStatus.played ||
      this == FriendlyChallengeStatus.disputed;

  /// Several states read differently depending on which side you are on —
  /// `pendingHome` is "waiting on them" to the challenger and "your call" to
  /// the home lobby — so the label always takes [weAreHome] rather than
  /// leaving each screen to remember.
  String getLocalizedLabel(BuildContext context, {required bool weAreHome}) =>
      context.tr('challenge.status.${weAreHome ? 'home' : 'away'}.$name');
}

/// A post-match verdict on the lobby you just played. The five kinds have no
/// mechanical difference beyond their sign — they exist so a lobby's profile
/// reads as "12 thân thiện · 2 smurf" rather than a bare integer, and so
/// `smurfing` is sayable at all.
enum LobbyRecommendationKind {
  friendly('friendly'),
  fairplay('fairplay'),
  unfriendly('unfriendly'),
  dirty('dirty'),
  smurfing('smurfing');

  /// The value this enum has in Postgres.
  final String dbValue;

  const LobbyRecommendationKind(this.dbValue);

  static LobbyRecommendationKind? fromDb(String? v) {
    for (final e in LobbyRecommendationKind.values) {
      if (e.dbValue == v) return e;
    }
    return null;
  }

  /// The `p_kind` value `recommend_lobby` expects.
  String get rpcValue => switch (this) {
    LobbyRecommendationKind.friendly => 'friendly',
    LobbyRecommendationKind.fairplay => 'fairplay',
    LobbyRecommendationKind.unfriendly => 'unfriendly',
    LobbyRecommendationKind.dirty => 'dirty',
    LobbyRecommendationKind.smurfing => 'smurfing',
  };

  bool get isPositive =>
      this == LobbyRecommendationKind.friendly ||
      this == LobbyRecommendationKind.fairplay;

  /// Shown on the tile so nobody casts a denouncement without knowing it costs
  /// the other lobby something.
  int get points => isPositive ? 2 : -2;

  static const positives = [
    LobbyRecommendationKind.friendly,
    LobbyRecommendationKind.fairplay,
  ];
  static const negatives = [
    LobbyRecommendationKind.unfriendly,
    LobbyRecommendationKind.dirty,
    LobbyRecommendationKind.smurfing,
  ];

  String getLocalizedName(BuildContext context) =>
      context.tr('challenge.verdict.$name');

  String getLocalizedDescription(BuildContext context) =>
      context.tr('challenge.verdict.description.$name');
}

/// A lobby's public trust standing. Baseline 40; negative is the signal.
/// Display only this pass — it gates nothing.
extension TrustScoreDisplay on int {
  bool get isLowTrust => this < 0;
}
