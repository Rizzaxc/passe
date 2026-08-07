import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/model/activity.dart';
import '../../../core/model/enum.dart';

part 'upcoming_controller.g.dart';

/// A professional (coach or referee) hired for a lobby activity, resolved from
/// the `coach_booking_id` / `referee_booking_id` embed. Enough to render the
/// hero card's attachment row and deep-link to the pro's profile.
class AttachedProfessional {
  final String bookingId;
  final String professionalId;
  final String name;
  final bool verified;
  final ProfessionalBookingStatus status;

  const AttachedProfessional({
    required this.bookingId,
    required this.professionalId,
    required this.name,
    required this.verified,
    required this.status,
  });

  /// Parse one embedded `professional_booking` row (with a nested
  /// `professional`). Returns null when the embed is absent or RLS hid it.
  static AttachedProfessional? fromEmbed(Object? embed) {
    if (embed is! Map<String, dynamic>) return null;
    final pro = embed['professional'] as Map<String, dynamic>?;
    if (pro == null) return null;
    return AttachedProfessional(
      bookingId: embed['id'] as String,
      professionalId: embed['professional_id'] as String,
      name: (pro['display_name'] as String?) ?? '',
      verified: (pro['is_verified'] as bool?) ?? false,
      status:
          ProfessionalBookingStatus.fromValue(embed['status'] as String?) ??
          ProfessionalBookingStatus.requested,
    );
  }
}

/// The lobby-vs-lobby match behind a challenge activity, resolved from the
/// `lobby_challenge` embed and flattened to *this* lobby's point of view: who
/// the opponent is, and whether we are the home (challenged) side.
///
/// Home matters twice over: the home lobby set the terms, and it is the side
/// prompted to hire the referee.
class ChallengeContext {
  final String challengeId;
  final String status; // requested | accepted | scheduled | played | lapsed
  final String opponentName;
  final int? opponentMmr;
  final bool weAreHome;
  final double? costPerTeam;

  const ChallengeContext({
    required this.challengeId,
    required this.status,
    required this.opponentName,
    required this.opponentMmr,
    required this.weAreHome,
    required this.costPerTeam,
  });

  /// Parse the embedded `lobby_challenge` row from the perspective of
  /// [myLobbyId]. Returns null when the activity isn't a challenge one.
  static ChallengeContext? fromEmbed(Object? embed, String myLobbyId) {
    if (embed is! Map<String, dynamic>) return null;
    final weAreHome = embed['target_lobby_id'] == myLobbyId;
    final opponent =
        (weAreHome ? embed['initiator'] : embed['target']) as Map<String, dynamic>?;
    return ChallengeContext(
      challengeId: embed['id'] as String,
      status: (embed['status'] as String?) ?? 'accepted',
      opponentName: (opponent?['name'] as String?) ?? '—',
      opponentMmr: (opponent?['mmr'] as num?)?.toInt(),
      weAreHome: weAreHome,
      costPerTeam: double.tryParse(embed['agreed_cost']?.toString() ?? ''),
    );
  }
}

/// One current/future activity for a lobby, either a one-off or a single
/// occurrence of a recurring series — every row is now its own real,
/// independently-dated `activity` (see schema/recurring_activity_series.sql),
/// so there's no virtual "next occurrence" left to resolve.
///
/// The fields below (location, cost, confirmation) come straight off
/// the `activity` row / its `location` join but aren't part of the shared
/// `Activity` freezed model, so they're carried here instead of bloating a
/// model used elsewhere in the app.
class UpcomingActivity {
  final Activity activity;

  /// Null for one-off activities, 0–6 (Mon..Sun, ISO ordering) for a
  /// weekly recurrence.
  final int? recurrenceDayOfWeek;

  /// Opaque grouping tag shared by every occurrence of the same recurring
  /// series (null for a one-off). Purely informational client-side today —
  /// the sweep that extends a series keys off this on the server.
  final String? seriesId;

  final String? locationId;
  final String? locationName;
  final String? locationDistrict;

  /// Informational cost, settled post-session via the payment-request
  /// feature (chia tiền) — not collected at scheduling time.
  final String? costType; // 'per_pax' | 'total'
  final num? costAmount;

  final int? confirmationThreshold;
  final DateTime? confirmationDeadline;

  /// Attached professionals (null when no coach / referee is hired for this
  /// session). See schema/activity_professional_attachment.sql.
  final AttachedProfessional? coach;
  final AttachedProfessional? referee;

  /// Set when this activity was materialised by accepting a lobby-vs-lobby
  /// challenge (schema/challenge_flow.sql). Both lobbies get one activity each,
  /// linked by the same `challenge_id`.
  final ChallengeContext? challenge;

  /// A challenge activity is official only once RSVP quorum is met *and* a
  /// manager confirms; this is the second half. Null on ordinary activities.
  final DateTime? managerConfirmedAt;

  const UpcomingActivity({
    required this.activity,
    required this.recurrenceDayOfWeek,
    required this.seriesId,
    required this.locationId,
    required this.locationName,
    required this.locationDistrict,
    required this.costType,
    required this.costAmount,
    required this.confirmationThreshold,
    required this.confirmationDeadline,
    required this.coach,
    required this.referee,
    this.challenge,
    this.managerConfirmedAt,
  });

  bool get isRecurring => recurrenceDayOfWeek != null;

  /// Direct pass-throughs now that every occurrence is its own dated row —
  /// no more resolving a template's "next" instant.
  DateTime get nextStart => activity.startTime;
  DateTime? get nextEnd => activity.endTime;
}

/// Every current/future activity for a lobby, sorted soonest-first. A lobby
/// can legitimately have several live at once (an organic session and a
/// challenge match, several weeks of a recurring series once materialised,
/// …) — each is its own row, so this is a plain `start_time > now` query.
@riverpod
class LobbyUpcomingActivitiesController
    extends _$LobbyUpcomingActivitiesController {
  final supabase = Supabase.instance.client;

  @override
  Future<List<UpcomingActivity>> build(String lobbyId) async {
    final nowUtc = DateTime.now().toUtc();

    final response = await supabase
        .from('activity')
        .select(
          '*, location(name, district), '
          'coach:professional_booking!activity_coach_booking_id_fkey('
          'id, status, professional_id, '
          'professional:professional_id(display_name, is_verified)), '
          'referee:professional_booking!activity_referee_booking_id_fkey('
          'id, status, professional_id, '
          'professional:professional_id(display_name, is_verified)), '
          'challenge:lobby_challenge(id, status, target_lobby_id, agreed_cost, '
          'initiator:initiator_lobby_id(name, mmr), '
          'target:target_lobby_id(name, mmr))',
        )
        .eq('lobby_id', lobbyId)
        .gt('start_time', nowUtc.toIso8601String())
        .timeout(const Duration(seconds: 5));

    final rows = (response as List).cast<Map<String, dynamic>>();
    if (rows.isEmpty) return const [];

    final list = <UpcomingActivity>[];
    for (final row in rows) {
      final activity = Activity.fromJson(_stripExtras(row));
      final location = row['location'] as Map<String, dynamic>?;
      list.add(UpcomingActivity(
        activity: activity,
        recurrenceDayOfWeek: (row['recurrence_day_of_week'] as num?)?.toInt(),
        seriesId: row['series_id'] as String?,
        locationId: row['location_id'] as String?,
        locationName: location?['name'] as String?,
        locationDistrict: location?['district'] as String?,
        costType: row['cost_type'] as String?,
        costAmount: row['cost_amount'] as num?,
        confirmationThreshold:
            (row['confirmation_threshold'] as num?)?.toInt(),
        confirmationDeadline: row['confirmation_deadline'] != null
            ? DateTime.parse(row['confirmation_deadline'] as String)
            : null,
        coach: AttachedProfessional.fromEmbed(row['coach']),
        referee: AttachedProfessional.fromEmbed(row['referee']),
        challenge: ChallengeContext.fromEmbed(row['challenge'], lobbyId),
        managerConfirmedAt: row['manager_confirmed_at'] != null
            ? DateTime.parse(row['manager_confirmed_at'] as String).toLocal()
            : null,
      ));
    }
    list.sort((a, b) => a.nextStart.compareTo(b.nextStart));
    return list;
  }

  /// Strip columns the freezed `Activity.fromJson` doesn't know about
  /// so the deserialisation succeeds. The augmented fields (location join,
  /// recurrence, cost, confirmation) are read directly from the row
  /// above and carried on `UpcomingActivity` instead.
  Map<String, dynamic> _stripExtras(Map<String, dynamic> row) {
    return {...row}
      ..remove('location')
      ..remove('coach')
      ..remove('referee')
      ..remove('challenge')
      ..remove('challenge_id')
      ..remove('manager_confirmed_at')
      ..remove('recurrence_day_of_week')
      ..remove('series_id')
      ..remove('location_id')
      ..remove('cost_type')
      ..remove('cost_amount')
      ..remove('confirmation_threshold')
      ..remove('confirmation_deadline');
  }
}
