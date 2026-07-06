import '../core/model/enum.dart';

/// One row of `professional_booking`, joined with the professional, the
/// service booked, the venue (if any), and the caller's own review (if
/// any) — enough to render a session card without extra round-trips.
///
/// Plain class with manual `fromJson` (not freezed), matching
/// [ProfessionalFeedItem]'s convention for RPC/query-shaped models.
class ProfessionalBookingItem {
  final String id;
  final String professionalId;
  final String professionalName;
  final bool professionalVerified;
  final double professionalRating;
  final int professionalReviewCount;
  final String? serviceType;
  final DateTime start;
  final DateTime end;
  final double? agreedRate;
  final ProfessionalBookingStatus status;
  final String? clientNotes;
  final String? professionalNotes;
  final String? locationName;

  /// Whether the caller has already left a `professional_booking_review`
  /// for this booking.
  final bool reviewed;

  const ProfessionalBookingItem({
    required this.id,
    required this.professionalId,
    required this.professionalName,
    required this.professionalVerified,
    required this.professionalRating,
    required this.professionalReviewCount,
    this.serviceType,
    required this.start,
    required this.end,
    this.agreedRate,
    required this.status,
    this.clientNotes,
    this.professionalNotes,
    this.locationName,
    required this.reviewed,
  });

  /// Still awaiting the professional's response, or confirmed and not yet
  /// happened — the "upcoming" bucket in the Coaching section.
  bool get isUpcoming =>
      (status == ProfessionalBookingStatus.requested ||
          status == ProfessionalBookingStatus.confirmed) &&
      end.isAfter(DateTime.now());

  /// A confirmed session whose end time has passed and that the caller
  /// hasn't reviewed yet. See `schema/professional_booking_review_policy_fix.sql`
  /// for why this — not `status == completed` — is the review gate: the
  /// `completed` status can never actually be set on this table (a stale
  /// CHECK constraint forbids it), so the original review policy was dead.
  bool get reviewEligible =>
      status == ProfessionalBookingStatus.confirmed &&
      end.isBefore(DateTime.now()) &&
      !reviewed;

  factory ProfessionalBookingItem.fromJson(Map<String, dynamic> json) {
    final pro = json['professional'] as Map<String, dynamic>?;
    final service = json['professional_service'] as Map<String, dynamic>?;
    final location = json['location'] as Map<String, dynamic>?;
    final reviewRaw = json['professional_booking_review'];
    final review = reviewRaw is List
        ? (reviewRaw.isNotEmpty
              ? reviewRaw.first as Map<String, dynamic>?
              : null)
        : reviewRaw as Map<String, dynamic>?;

    return ProfessionalBookingItem(
      id: json['id'] as String,
      professionalId: json['professional_id'] as String,
      professionalName: (pro?['display_name'] ?? '') as String,
      professionalVerified: pro?['is_verified'] as bool? ?? false,
      professionalRating:
          double.tryParse(pro?['average_rating']?.toString() ?? '') ?? 0,
      professionalReviewCount: (pro?['review_count'] as num?)?.toInt() ?? 0,
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
      reviewed: review != null,
    );
  }
}
