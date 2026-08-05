import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'challenge_offer_controller.g.dart';

/// A lobby's live "we're accepting challenges" offer.
///
/// Opting in is not a boolean: a lobby that wants challengers has to say *when*
/// it will play, *where*, and *what a team pays* — the challenger feed
/// advertises those terms and `send_challenge` snapshots them onto the
/// challenge. The DB enforces the pairing (`lobby_challenge_offer_complete`),
/// so an [isOpen] offer always has all three fields.
class ChallengeOffer {
  final bool isOpen;
  final DateTime? kickoff;
  final String? locationId;
  final String? locationName;
  final double? costPerTeam;

  /// The lobby's homeground, carried alongside so the compose sheet can seed a
  /// venue without its callers having to thread one in — a lobby nearly always
  /// offers matches at the ground it already plays on.
  final String? homegroundId;
  final String? homegroundName;

  const ChallengeOffer({
    required this.isOpen,
    this.kickoff,
    this.locationId,
    this.locationName,
    this.costPerTeam,
    this.homegroundId,
    this.homegroundName,
  });

  static const closed = ChallengeOffer(isOpen: false);

  /// An offer whose kickoff has passed is treated as closed here as well as by
  /// the cron sweep — the sweep runs every minute, so between kickoff and the
  /// next tick the row still says open. Never render a checked box over dead
  /// terms just because the sweep hasn't got there yet.
  bool get isLive =>
      isOpen && kickoff != null && kickoff!.isAfter(DateTime.now());
}

@riverpod
class ChallengeOfferController extends _$ChallengeOfferController {
  @override
  Future<ChallengeOffer> build(String lobbyId) async {
    final row = await Supabase.instance.client
        .from('lobby')
        // `lobby` has two FKs into `location` (home_ground and the offer
        // venue), so both embeds have to name their constraint explicitly.
        .select(
          'open_to_challengers, challenge_offer_time, challenge_offer_cost, '
          'challenge_offer_location, home_ground, '
          'offer_venue:location!lobby_challenge_offer_location_fkey(name), '
          'homeground:location!lobby_home_ground_fkey(name)',
        )
        .eq('id', lobbyId)
        .maybeSingle()
        .timeout(const Duration(seconds: 5));

    if (row == null) return ChallengeOffer.closed;

    final time = row['challenge_offer_time'] as String?;
    return ChallengeOffer(
      isOpen: (row['open_to_challengers'] as bool?) ?? false,
      kickoff: time != null ? DateTime.parse(time).toLocal() : null,
      locationId: row['challenge_offer_location'] as String?,
      locationName:
          (row['offer_venue'] as Map<String, dynamic>?)?['name'] as String?,
      // numeric comes back as String from Supabase.
      costPerTeam: double.tryParse(row['challenge_offer_cost']?.toString() ?? ''),
      homegroundId: row['home_ground'] as String?,
      homegroundName:
          (row['homeground'] as Map<String, dynamic>?)?['name'] as String?,
    );
  }

  /// Publish or update the offer. Manager-gated server-side by
  /// `set_lobby_challenge_offer`.
  Future<void> publish({
    required DateTime kickoff,
    required String locationId,
    required double costPerTeam,
  }) async {
    await Supabase.instance.client.rpc('set_lobby_challenge_offer', params: {
      'p_lobby_id': lobbyId,
      'p_open': true,
      'p_time': kickoff.toUtc().toIso8601String(),
      'p_location': locationId,
      'p_cost': costPerTeam,
    }).timeout(const Duration(seconds: 5));
    ref.invalidateSelf();
  }

  /// Withdraw the offer. Clears the terms too, so nothing stale is left behind
  /// an unchecked box.
  Future<void> withdraw() async {
    await Supabase.instance.client.rpc('set_lobby_challenge_offer', params: {
      'p_lobby_id': lobbyId,
      'p_open': false,
    }).timeout(const Duration(seconds: 5));
    ref.invalidateSelf();
  }
}

/// Maps `set_lobby_challenge_offer`'s guard exceptions onto Vietnamese copy.
String challengeOfferErrorMessage(Object e) {
  final msg = e.toString();
  if (msg.contains('not a manager')) {
    return 'Chỉ đội trưởng hoặc điều phối viên mới đặt được';
  }
  if (msg.contains('in the past')) return 'Giờ thi đấu phải ở tương lai';
  if (msg.contains('negative')) return 'Chi phí không hợp lệ';
  return 'Không thể cập nhật lời mời thách đấu';
}
