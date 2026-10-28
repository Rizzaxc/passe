import 'package:easy_localization/easy_localization.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/model/challenge.dart';
import 'friendly_challenge_controller.dart';

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

  /// When the match ends — the fixture's session runs kickoff → here.
  final DateTime endTime;
  final DateTime expiresAt;
  final String locationId;
  final String? locationName;

  final double? venueCost;
  final ChallengeCostSplit costSplit;
  final ChallengeBountyKind bountyKind;
  final double? bountyAmount;
  final ChallengeRuleset ruleset;
  final int? rulesetParam;
  final String? termsNote;

  /// How many lobbies are on this fixture right now — deliberating or already
  /// waiting on an answer. Publishing over an occupied slot lapses them, so the
  /// form says how many people that would affect before it happens.
  final int liveChallengeCount;

  const ChallengeOfferSlot({
    required this.id,
    required this.slot,
    required this.kickoff,
    required this.endTime,
    required this.expiresAt,
    required this.locationId,
    required this.locationName,
    required this.venueCost,
    required this.costSplit,
    required this.bountyKind,
    required this.bountyAmount,
    required this.ruleset,
    required this.rulesetParam,
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
    final kickoff = DateTime.parse(m['kickoff'] as String).toLocal();
    final end = m['end_time'] as String?;

    return ChallengeOfferSlot(
      id: m['id'] as String,
      slot: (m['slot'] as num).toInt(),
      kickoff: kickoff,
      // Offers predating the column were all given 90 minutes server-side.
      endTime: end == null
          ? kickoff.add(defaultChallengeMatchLength)
          : DateTime.parse(end).toLocal(),
      expiresAt: DateTime.parse(m['expires_at'] as String).toLocal(),
      locationId: m['location_id'] as String,
      locationName:
          (m['location'] as Map<String, dynamic>?)?['name'] as String?,
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
          'id, slot, kickoff, end_time, expires_at, location_id, venue_cost, '
          'cost_split, '
          'bounty_kind, bounty_amount, ruleset, ruleset_param, terms_note, '
          'location(name), '
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
    required DateTime endTime,
    required String locationId,
    DateTime? expiresAt,
    double? venueCost,
    ChallengeCostSplit costSplit = ChallengeCostSplit.none,
    ChallengeBountyKind bountyKind = ChallengeBountyKind.none,
    double? bountyAmount,
    ChallengeRuleset ruleset = ChallengeRuleset.standard,
    int? rulesetParam,
    String? termsNote,
  }) async {
    await Supabase.instance.client
        .rpc(
          'publish_challenge_offer',
          params: {
            'p_lobby_id': lobbyId,
            'p_slot': slot,
            'p_kickoff': kickoff.toUtc().toIso8601String(),
            'p_end_time': endTime.toUtc().toIso8601String(),
            'p_location': locationId,
            'p_expires_at': expiresAt?.toUtc().toIso8601String(),
            'p_venue_cost': venueCost,
            'p_cost_split': costSplit.dbValue,
            'p_bounty_kind': bountyKind.dbValue,
            'p_bounty_amount': bountyAmount,
            'p_ruleset': ruleset.dbValue,
            'p_ruleset_param': rulesetParam,
            'p_terms_note': termsNote,
          },
        )
        .timeout(const Duration(seconds: 5));
    // Publishing, withdrawing or renewing creates, moves or retires the
    // offer's Planner session and posts to the feed.
    invalidateFriendlyChallengeSurfaces(ref, lobbyId);
  }

  Future<void> withdraw(String offerId) async {
    await Supabase.instance.client
        .rpc('withdraw_challenge_offer', params: {'p_offer_id': offerId})
        .timeout(const Duration(seconds: 5));
    // Publishing, withdrawing or renewing creates, moves or retires the
    // offer's Planner session and posts to the feed.
    invalidateFriendlyChallengeSurfaces(ref, lobbyId);
  }

  /// Adds a line to an open offer's note without re-publishing it, so the
  /// lobbies already on it are not lapsed. They keep the terms they
  /// snapshotted; the addition is for whoever looks next.
  Future<void> amend(String offerId, String append) async {
    await Supabase.instance.client
        .rpc(
          'amend_challenge_offer',
          params: {'p_offer_id': offerId, 'p_append': append},
        )
        .timeout(const Duration(seconds: 5));
    // Publishing, withdrawing or renewing creates, moves or retires the
    // offer's Planner session and posts to the feed.
    invalidateFriendlyChallengeSurfaces(ref, lobbyId);
  }

  /// Re-posts an expired or withdrawn offer a week later, same terms — the
  /// action behind the "Lời mời hết hạn" notification.
  Future<void> renew(String offerId) async {
    await Supabase.instance.client
        .rpc('renew_challenge_offer', params: {'p_offer_id': offerId})
        .timeout(const Duration(seconds: 5));
    // Publishing, withdrawing or renewing creates, moves or retires the
    // offer's Planner session and posts to the feed.
    invalidateFriendlyChallengeSurfaces(ref, lobbyId);
  }
}

/// What a new offer's match length starts at, and what the server assumes
/// for an offer published without one.
const defaultChallengeMatchLength = Duration(minutes: 90);

/// The shortest length the offer form's slider offers.
const minChallengeMatchLength = Duration(minutes: 30);

/// The longest match `publish_challenge_offer` accepts.
const maxChallengeMatchLength = Duration(hours: 3);

/// The longest single amendment `amend_challenge_offer` accepts.
const challengeOfferAmendMaxLength = 140;

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
  if (msg.contains('end after kickoff')) {
    return 'challenge.offer.errorEndOrder'.tr();
  }
  if (msg.contains('match is too long')) {
    return 'challenge.offer.errorTooLong'.tr();
  }
  if (msg.contains('three offer slots')) {
    return 'challenge.offer.errorSlot'.tr();
  }
  if (msg.contains('needs a venue')) {
    return 'challenge.offer.errorVenue'.tr();
  }
  if (msg.contains('custom ruleset cannot be amended')) {
    return 'challenge.offer.errorAmendCustom'.tr();
  }
  if (msg.contains('amendment is too long') || msg.contains('note is full')) {
    return 'challenge.offer.errorAmendTooLong'.tr();
  }
  if (msg.contains('still open')) {
    return 'challenge.offer.errorRenewStillOpen'.tr();
  }
  if (msg.contains('already renewed')) {
    return 'challenge.offer.errorRenewDone'.tr();
  }
  if (msg.contains('already matched')) {
    return 'challenge.offer.errorRenewTaken'.tr();
  }
  return 'challenge.offer.errorGeneric'.tr();
}
