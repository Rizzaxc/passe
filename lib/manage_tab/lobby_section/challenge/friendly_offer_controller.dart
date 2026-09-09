import 'package:easy_localization/easy_localization.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/model/challenge.dart';

part 'friendly_offer_controller.g.dart';

/// One advertised fixture — a row of `lobby_challenge_offer`.
///
/// A lobby holds up to three of these at once, addressed by [slot]. The slot is
/// what makes the cap a partial unique index rather than a counting trigger, so
/// two managers publishing at the same moment cannot both win.
class ChallengeOfferSlot {
  final String id;
  final int slot;
  final DateTime kickoff;
  final DateTime expiresAt;
  final String locationId;
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

  /// How many lobbies are on this fixture right now — deliberating or already
  /// waiting on an answer. Publishing over an occupied slot lapses them, so the
  /// form says how many people that would affect before it happens.
  final int liveChallengeCount;

  const ChallengeOfferSlot({
    required this.id,
    required this.slot,
    required this.kickoff,
    required this.expiresAt,
    required this.locationId,
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
    required this.liveChallengeCount,
  });

  /// The sweep runs once a minute, so between expiry and the next tick the row
  /// still says `open`. Never render a live advert over dead terms just because
  /// the sweep hasn't got there yet — the same guard the refereed offer uses.
  bool get isLive => expiresAt.isAfter(DateTime.now());

  factory ChallengeOfferSlot.fromJson(Map<String, dynamic> m) {
    double? num_(String k) {
      final v = m[k];
      if (v == null) return null;
      return v is num ? v.toDouble() : double.tryParse(v.toString());
    }

    final challenges = (m['lobby_challenge'] as List?) ?? const [];

    return ChallengeOfferSlot(
      id: m['id'] as String,
      slot: (m['slot'] as num).toInt(),
      kickoff: DateTime.parse(m['kickoff'] as String).toLocal(),
      expiresAt: DateTime.parse(m['expires_at'] as String).toLocal(),
      locationId: m['location_id'] as String,
      locationName: (m['location'] as Map<String, dynamic>?)?['name'] as String?,
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
      liveChallengeCount: challenges.length,
    );
  }
}

/// A lobby's three offer slots plus the homeground to seed new ones with.
class ChallengeOfferBoard {
  final List<ChallengeOfferSlot> open;
  final String? homegroundId;
  final String? homegroundName;

  const ChallengeOfferBoard({
    required this.open,
    this.homegroundId,
    this.homegroundName,
  });

  static const maxSlots = 3;

  ChallengeOfferSlot? bySlot(int slot) {
    for (final o in open) {
      if (o.slot == slot) return o;
    }
    return null;
  }

  /// The lowest unoccupied slot, or null when all three are taken.
  int? get nextFreeSlot {
    for (var i = 1; i <= maxSlots; i++) {
      if (bySlot(i) == null) return i;
    }
    return null;
  }
}

@riverpod
class FriendlyOfferController extends _$FriendlyOfferController {
  @override
  Future<ChallengeOfferBoard> build(String lobbyId) async {
    final supabase = Supabase.instance.client;

    // The offer table is public-readable, so this is a plain select rather than
    // an RPC. `lobby_challenge` is embedded only to count live challengers —
    // publishing over an occupied slot lapses them, and the form should say so.
    final rows = await supabase
        .from('lobby_challenge_offer')
        .select(
          'id, slot, kickoff, expires_at, location_id, venue_cost, cost_split, '
          'bounty_kind, bounty_amount, ruleset, ruleset_param, handicap_side, '
          'handicap_amount, terms_note, location(name), '
          'lobby_challenge!lobby_challenge_offer_id_fkey(id, status)',
        )
        .eq('lobby_id', lobbyId)
        .eq('status', 'open')
        .eq('mode', 'friendly')
        .order('slot')
        .timeout(const Duration(seconds: 5));

    final homeground = await supabase
        .from('lobby_homeground')
        .select('location(id, name)')
        .eq('lobby_id', lobbyId)
        .eq('is_primary', true)
        .maybeSingle()
        .timeout(const Duration(seconds: 5));

    final loc = homeground?['location'] as Map<String, dynamic>?;

    return ChallengeOfferBoard(
      open: (rows as List)
          .map((r) => ChallengeOfferSlot.fromJson(r as Map<String, dynamic>))
          .where((o) => o.isLive)
          .toList(),
      homegroundId: loc?['id'] as String?,
      homegroundName: loc?['name'] as String?,
    );
  }

  /// Publish (or replace) the offer in [slot].
  ///
  /// Replacing an occupied slot is a real action with a cost: the server lapses
  /// every challenger already on it and pushes them. The form warns first.
  Future<void> publish({
    required int slot,
    required DateTime kickoff,
    required String locationId,
    DateTime? expiresAt,
    double? venueCost,
    ChallengeCostSplit costSplit = ChallengeCostSplit.none,
    ChallengeBountyKind bountyKind = ChallengeBountyKind.none,
    double? bountyAmount,
    ChallengeRuleset ruleset = ChallengeRuleset.standard,
    int? rulesetParam,
    ChallengeHandicapSide handicapSide = ChallengeHandicapSide.none,
    int? handicapAmount,
    String? termsNote,
  }) async {
    await Supabase.instance.client
        .rpc(
          'publish_challenge_offer',
          params: {
            'p_lobby_id': lobbyId,
            'p_slot': slot,
            'p_kickoff': kickoff.toUtc().toIso8601String(),
            'p_location': locationId,
            'p_expires_at': expiresAt?.toUtc().toIso8601String(),
            'p_venue_cost': venueCost,
            'p_cost_split': costSplit.dbValue,
            'p_bounty_kind': bountyKind.dbValue,
            'p_bounty_amount': bountyAmount,
            'p_ruleset': ruleset.dbValue,
            'p_ruleset_param': rulesetParam,
            'p_handicap_side': handicapSide.dbValue,
            'p_handicap_amount': handicapAmount,
            'p_terms_note': termsNote,
          },
        )
        .timeout(const Duration(seconds: 5));
    ref.invalidateSelf();
  }

  Future<void> withdraw(String offerId) async {
    await Supabase.instance.client
        .rpc('withdraw_challenge_offer', params: {'p_offer_id': offerId})
        .timeout(const Duration(seconds: 5));
    ref.invalidateSelf();
  }
}

/// Maps `publish_challenge_offer`'s guards onto Vietnamese copy.
String friendlyOfferErrorMessage(Object e) {
  final msg = e.toString();
  if (msg.contains('not a manager')) {
    return 'challenge.offer.errorManagerOnly'.tr();
  }
  if (msg.contains('kickoff is in the past')) {
    return 'challenge.offer.errorPastKickoff'.tr();
  }
  if (msg.contains('close before kickoff')) {
    return 'challenge.offer.errorExpiryOrder'.tr();
  }
  if (msg.contains('close in the past')) {
    return 'challenge.offer.errorExpiryPast'.tr();
  }
  if (msg.contains('three offer slots')) {
    return 'challenge.offer.errorSlot'.tr();
  }
  if (msg.contains('needs a venue')) {
    return 'challenge.offer.errorVenue'.tr();
  }
  return 'challenge.offer.errorGeneric'.tr();
}
