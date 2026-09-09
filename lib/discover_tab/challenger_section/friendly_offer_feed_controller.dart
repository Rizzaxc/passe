import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/model/challenge.dart';
import '../../core/state/selected_sport_state.dart';
import '../filter_controller.dart';
import 'feed_controller.dart';

part 'friendly_offer_feed_controller.g.dart';

/// One advertised fixture on the Discover feed — a row of
/// `friendly_offer_feed_data`.
///
/// The unit here is the FIXTURE, not the lobby: a lobby can advertise three
/// different dates and a challenger is choosing between them, not between
/// clubs. That is why this feed has its own RPC rather than reusing
/// `home_challenger_lobby_data`, which returns one row per lobby.
class FriendlyOffer {
  final String offerId;
  final int slot;
  final String lobbyId;
  final String lobbyName;
  final int? lobbyMmr;
  final int? trustScore;
  final int ratedMatchCount;
  final int memberCount;
  final String? description;
  final String? homegroundName;

  final DateTime kickoff;
  final DateTime expiresAt;
  final String? locationName;

  final double? venueCost;
  final ChallengeCostSplit costSplit;
  final ChallengeBountyKind bountyKind;
  final double? bountyAmount;
  final ChallengeRuleset ruleset;
  final int? rulesetParam;
  final ChallengeHandicapSide handicapSide;
  final int? handicapAmount;
  final String? termsNote;

  /// 'harder' | 'even' | 'easier', stated from the CHALLENGER's point of view
  /// and honouring the same +50 home advantage the rating engine applies.
  final String favorability;

  final Map<LobbyRecommendationKind, int> recommendations;

  /// Whether our context lobby already has a live challenge on this fixture.
  final bool alreadyChallenged;

  const FriendlyOffer({
    required this.offerId,
    required this.slot,
    required this.lobbyId,
    required this.lobbyName,
    required this.lobbyMmr,
    required this.trustScore,
    required this.ratedMatchCount,
    required this.memberCount,
    required this.description,
    required this.homegroundName,
    required this.kickoff,
    required this.expiresAt,
    required this.locationName,
    required this.venueCost,
    required this.costSplit,
    required this.bountyKind,
    required this.bountyAmount,
    required this.ruleset,
    required this.rulesetParam,
    required this.handicapSide,
    required this.handicapAmount,
    required this.termsNote,
    required this.favorability,
    required this.recommendations,
    required this.alreadyChallenged,
  });

  bool get isLowTrust => (trustScore ?? 40) < 0;

  /// Under five rated matches an MMR is mostly the members' self-declared
  /// `elo_seed`, so it is shown as provisional rather than earned.
  bool get hasProvisionalMmr => ratedMatchCount < 5;

  factory FriendlyOffer.fromJson(Map<String, dynamic> m) {
    double? num_(String k) {
      final v = m[k];
      if (v == null) return null;
      return v is num ? v.toDouble() : double.tryParse(v.toString());
    }

    final counts = <LobbyRecommendationKind, int>{};
    final raw = m['recommendation_counts'];
    if (raw is Map) {
      raw.forEach((k, v) {
        final kind = LobbyRecommendationKind.fromDb(k as String?);
        if (kind != null) counts[kind] = (v as num?)?.toInt() ?? 0;
      });
    }

    return FriendlyOffer(
      offerId: m['offer_id'] as String,
      slot: (m['slot'] as num?)?.toInt() ?? 1,
      lobbyId: m['lobby_id'] as String,
      lobbyName: m['lobby_name'] as String? ?? '',
      lobbyMmr: (m['lobby_mmr'] as num?)?.toInt(),
      trustScore: (m['trust_score'] as num?)?.toInt(),
      ratedMatchCount: (m['rated_match_count'] as num?)?.toInt() ?? 0,
      memberCount: (m['member_count'] as num?)?.toInt() ?? 0,
      description: m['description'] as String?,
      homegroundName: m['homeground_name'] as String?,
      kickoff: DateTime.parse(m['kickoff'] as String).toLocal(),
      expiresAt: DateTime.parse(m['expires_at'] as String).toLocal(),
      locationName: m['location_name'] as String?,
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
      favorability: m['favorability'] as String? ?? 'even',
      recommendations: counts,
      alreadyChallenged: m['already_challenged'] as bool? ?? false,
    );
  }
}

/// Open friendly fixtures for the context sport, ranked by how close a match
/// they'd be against the lobby the user is challenging as.
@riverpod
class FriendlyOfferFeed extends _$FriendlyOfferFeed {
  @override
  Future<List<FriendlyOffer>> build() async {
    final filter = ref.watch(filterStateProvider);
    final sport = ref.watch(selectedSportStateProvider.select((v) => v.value));
    if (sport == null) return [];

    final ctx = await ref.watch(contextLobbyProvider.future);
    if (ctx == null) return [];

    final response = await Supabase.instance.client
        .rpc(
          'friendly_offer_feed_data',
          params: {
            'p_context_lobby_id': ctx.id,
            'p_sport_id': sport.index,
            'p_city': filter.city.dbIndex,
            'p_districts': filter.districts.map((d) => d.id).toList(),
            'p_search': filter.search,
            'p_page_size': 20,
            'p_page_number': 1,
          },
        )
        .timeout(const Duration(seconds: 5));

    return (response as List)
        .map((e) => FriendlyOffer.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// Sends a friendly challenge against one advertised fixture.
///
/// The challenger does not propose anything — the fixture's terms are fixed
/// and the RPC snapshots them. What the challenger DOES set is their own
/// confirmation threshold: how many of their players have to commit before the
/// handshake is allowed to reach the other lobby at all. That number is theirs
/// because it is their roster, and only they know what a Saturday produces.
@riverpod
class SendFriendlyChallengeController
    extends _$SendFriendlyChallengeController {
  @override
  bool build(String initiatorLobbyId) => false; // in-flight flag

  Future<void> send({
    required String offerId,
    required int threshold,
    String? note,
  }) async {
    state = true;
    try {
      await Supabase.instance.client
          .rpc(
            'send_friendly_challenge',
            params: {
              'p_initiator_lobby': initiatorLobbyId,
              'p_offer_id': offerId,
              'p_threshold': threshold,
              'p_note': note,
            },
          )
          .timeout(const Duration(seconds: 5));
      ref.invalidate(friendlyOfferFeedProvider);
    } finally {
      state = false;
    }
  }
}

/// How many members the context lobby has — the ceiling on the threshold the
/// challenger can set, mirroring `send_friendly_challenge`'s own guard.
@riverpod
Future<int> contextLobbyMemberCount(Ref ref, String lobbyId) async {
  final row = await Supabase.instance.client
      .from('lobby')
      .select('member_count')
      .eq('id', lobbyId)
      .maybeSingle()
      .timeout(const Duration(seconds: 5));
  return (row?['member_count'] as num?)?.toInt() ?? 0;
}

/// Maps `send_friendly_challenge`'s guards onto Vietnamese copy.
String friendlyChallengeErrorMessage(Object e) {
  final msg = e.toString();
  if (msg.contains('no longer open')) {
    return 'challenge.send.errorClosed'.tr();
  }
  if (msg.contains('has closed')) return 'challenge.send.errorExpired'.tr();
  if (msg.contains('different sports')) {
    return 'challenge.send.errorSport'.tr();
  }
  if (msg.contains('already have an open challenge')) {
    return 'challenge.send.errorDuplicate'.tr();
  }
  if (msg.contains('cannot challenge itself')) {
    return 'challenge.send.errorSelf'.tr();
  }
  if (msg.contains('larger than the lobby')) {
    return 'challenge.send.errorThresholdTooBig'.tr();
  }
  if (msg.contains('threshold must be at least')) {
    return 'challenge.send.errorThresholdTooSmall'.tr();
  }
  if (msg.contains('not a manager')) {
    return 'challenge.send.errorManagerOnly'.tr();
  }
  return 'challenge.send.errorGeneric'.tr();
}
