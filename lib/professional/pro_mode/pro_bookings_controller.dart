import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/model/enum.dart';

part 'pro_bookings_controller.g.dart';

/// One `professional_booking` row from the *pro's* perspective — the client
/// they're booked with, not their own name/rating (that's
/// [ProfessionalBookingItem]'s client-side shape).
class ProBookingItem {
  final String id;
  final String clientName;
  final String? serviceType;
  final DateTime start;
  final DateTime end;
  final double? agreedRate;
  final ProfessionalBookingStatus status;
  final String? clientNotes;
  final String? professionalNotes;
  final String? locationName;
  final String? packageId;

  /// Set only when this booking is a referee hire attached to a lobby-vs-lobby
  /// challenge activity — the case where the professional is the one who
  /// records the result. Null on every coach booking, so the ordinary card
  /// path is untouched.
  final RefereedMatch? match;

  const ProBookingItem({
    required this.id,
    required this.clientName,
    this.serviceType,
    required this.start,
    required this.end,
    this.agreedRate,
    required this.status,
    this.clientNotes,
    this.professionalNotes,
    this.locationName,
    this.packageId,
    this.match,
  });

  factory ProBookingItem.fromJson(Map<String, dynamic> json) {
    final client = json['client'] as Map<String, dynamic>?;
    final service = json['professional_service'] as Map<String, dynamic>?;
    final location = json['location'] as Map<String, dynamic>?;
    return ProBookingItem(
      id: json['id'] as String,
      clientName: (client?['username'] ?? '') as String,
      serviceType: service?['service_type'] as String?,
      start: DateTime.parse(json['booking_time_start'] as String).toLocal(),
      end: DateTime.parse(json['booking_time_end'] as String).toLocal(),
      agreedRate: double.tryParse(json['agreed_rate']?.toString() ?? ''),
      status:
          ProfessionalBookingStatus.fromValue(json['status'] as String?) ??
          ProfessionalBookingStatus.requested,
      clientNotes: json['client_notes'] as String?,
      professionalNotes: json['professional_notes'] as String?,
      locationName: location?['name'] as String?,
      packageId: json['package_id'] as String?,
      match: RefereedMatch.fromEmbed(json['activity']),
    );
  }
}

/// The lobby-vs-lobby match a referee booking is attached to.
///
/// Resolved through `activity.referee_booking_id` → `lobby_challenge`. The
/// referee is not a member of either lobby, so reading that activity depends on
/// the "Linked professionals can view their attached activities" RLS policy —
/// without it this embed comes back null and the whole result-entry affordance
/// silently disappears.
class RefereedMatch {
  final String challengeId;
  final String homeLobbyName;
  final String awayLobbyName;

  /// End of the match itself, which gates result entry. Falls back to the
  /// booking's own window when the activity has no end time.
  final DateTime? activityEnd;

  /// True once a result exists — the challenge has reached `played`.
  final bool resultRecorded;

  const RefereedMatch({
    required this.challengeId,
    required this.homeLobbyName,
    required this.awayLobbyName,
    required this.activityEnd,
    required this.resultRecorded,
  });

  static RefereedMatch? fromEmbed(Object? embed) {
    // PostgREST returns a list for a reverse embed (many activities could in
    // principle cite one booking); take the first.
    final row = embed is List
        ? (embed.isEmpty ? null : embed.first as Map<String, dynamic>?)
        : embed as Map<String, dynamic>?;
    if (row == null) return null;
    final challenge = row['challenge'] as Map<String, dynamic>?;
    if (challenge == null) return null;

    final end = row['end_time'] as String?;
    return RefereedMatch(
      challengeId: challenge['id'] as String,
      homeLobbyName:
          (challenge['target'] as Map<String, dynamic>?)?['name'] as String? ??
          '—',
      awayLobbyName:
          (challenge['initiator'] as Map<String, dynamic>?)?['name']
              as String? ??
          '—',
      activityEnd: end != null ? DateTime.parse(end).toLocal() : null,
      resultRecorded: challenge['status'] == 'played',
    );
  }
}

const _proSelectColumns = '''
  id, booking_time_start, booking_time_end, agreed_rate, status,
  client_notes, professional_notes, package_id,
  client:client_user_id(username),
  professional_service(service_type),
  location(name),
  activity!activity_referee_booking_id_fkey(
    id, end_time,
    challenge:lobby_challenge(
      id, status,
      initiator:initiator_lobby_id(name),
      target:target_lobby_id(name)))
''';

/// Pending requests for the linked professional — `status = requested`.
@riverpod
Future<List<ProBookingItem>> proPendingRequests(
  Ref ref,
  String professionalId,
) async {
  final response = await Supabase.instance.client
      .from('professional_booking')
      .select(_proSelectColumns)
      .eq('professional_id', professionalId)
      .eq('status', 'requested')
      .order('booking_time_start')
      .timeout(const Duration(seconds: 5));

  return (response as List)
      .map((e) => ProBookingItem.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// Confirmed upcoming sessions — the pro-mode "schedule" surface.
@riverpod
Future<List<ProBookingItem>> proUpcomingBookings(
  Ref ref,
  String professionalId,
) async {
  final response = await Supabase.instance.client
      .from('professional_booking')
      .select(_proSelectColumns)
      .eq('professional_id', professionalId)
      .eq('status', 'confirmed')
      .order('booking_time_start')
      .timeout(const Duration(seconds: 5));

  return (response as List)
      .map((e) => ProBookingItem.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// Past bookings — completed, rejected, or cancelled, most recent first.
@riverpod
Future<List<ProBookingItem>> proBookingHistory(
  Ref ref,
  String professionalId,
) async {
  final response = await Supabase.instance.client
      .from('professional_booking')
      .select(_proSelectColumns)
      .eq('professional_id', professionalId)
      .inFilter('status', [
        'completed',
        'rejected',
        'cancelled_by_client',
        'cancelled_by_pro',
      ])
      .order('booking_time_start', ascending: false)
      .timeout(const Duration(seconds: 5));

  return (response as List)
      .map((e) => ProBookingItem.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// Records the result of a refereed challenge match.
///
/// Only the booked referee can call this (`record_challenge_match` checks the
/// caller against the booking's professional), and only after the match has
/// ended. The insert it performs also flips the booking to `completed` through
/// the existing `lobby_match_complete_referee_booking` trigger and moves both
/// lobbies' Elo — which is why the entry is final and has no edit affordance.
@riverpod
class RecordChallengeResultController
    extends _$RecordChallengeResultController {
  @override
  bool build(String professionalId) => false; // in-flight flag

  /// [result] is from the HOME side: 'win' | 'draw' | 'loss'.
  Future<void> record({
    required String challengeId,
    required String result,
    required List<(int home, int away)> sets,
    String? note,
  }) async {
    state = true;
    try {
      await Supabase.instance.client
          .rpc(
            'record_challenge_match',
            params: {
              'p_challenge_id': challengeId,
              'p_result': result,
              'p_sets': sets.isEmpty
                  ? null
                  : sets.map((s) => [s.$1, s.$2]).toList(),
              'p_note': note,
            },
          )
          .timeout(const Duration(seconds: 5));
      _invalidateAll(ref, professionalId);
    } finally {
      state = false;
    }
  }
}

/// Maps `record_challenge_match`'s guards onto Vietnamese copy.
String recordResultErrorMessage(Object e) {
  final msg = e.toString();
  if (msg.contains('already has a result')) return 'Trận này đã có kết quả';
  if (msg.contains('not finished')) return 'Trận đấu chưa kết thúc';
  if (msg.contains('only the booked referee')) {
    return 'Chỉ trọng tài được thuê mới ghi được kết quả';
  }
  if (msg.contains('no referee is booked')) {
    return 'Trận này chưa có trọng tài';
  }
  return 'Không thể ghi kết quả';
}

void _invalidateAll(Ref ref, String professionalId) {
  ref.invalidate(proPendingRequestsProvider(professionalId));
  ref.invalidate(proUpcomingBookingsProvider(professionalId));
  ref.invalidate(proBookingHistoryProvider(professionalId));
}

/// Accept/reject/mark-complete actions for the professional side, backed by
/// the validated `accept_professional_booking`/`reject_professional_booking`
/// RPCs (accept needs an atomic overlap check a bare UPDATE can't express).
@riverpod
class ProBookingActionController extends _$ProBookingActionController {
  final supabase = Supabase.instance.client;

  @override
  bool build(String professionalId) => false; // in-flight flag

  Future<void> accept(String bookingId) async {
    state = true;
    try {
      await supabase
          .rpc(
            'accept_professional_booking',
            params: {'p_booking_id': bookingId},
          )
          .timeout(const Duration(seconds: 5));
      _invalidateAll(ref, professionalId);
    } finally {
      state = false;
    }
  }

  Future<void> reject(String bookingId, {String? reason}) async {
    state = true;
    try {
      await supabase
          .rpc(
            'reject_professional_booking',
            params: {'p_booking_id': bookingId, 'p_reason': reason},
          )
          .timeout(const Duration(seconds: 5));
      _invalidateAll(ref, professionalId);
    } finally {
      state = false;
    }
  }

  /// Either party can mark a past confirmed session complete — first tap
  /// wins, no mutual confirmation (the dead `completed` status's CHECK
  /// constraint was dropped in schema/professional_booking_completion.sql).
  Future<void> markComplete(String bookingId) async {
    state = true;
    try {
      await supabase
          .rpc(
            'complete_professional_booking',
            params: {'p_booking_id': bookingId},
          )
          .timeout(const Duration(seconds: 5));
      _invalidateAll(ref, professionalId);
    } finally {
      state = false;
    }
  }
}
