import '../core/model/enum.dart';

/// One row of `referee_booking`, joined with the professional, the
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

  /// `professional.linked_user_id` — the coach's own signed-in account, if
  /// they've linked one (set out-of-app). Null means there's no `user` row
  /// to look up payment info for — hide "pay coach" rather than show a
  /// dead button.
  final String? professionalLinkedUserId;
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

  /// Whether the caller has already left a `referee_booking_review`
  /// for this booking.
  final bool reviewed;


  final String? serviceId;
  final int? maxParticipants;

  const ProfessionalBookingItem({
    required this.id,
    required this.professionalId,
    required this.professionalName,
    required this.professionalVerified,
    this.professionalLinkedUserId,
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
    this.serviceId,
    this.maxParticipants,
  });

  /// Still awaiting the professional's response, or confirmed and not yet
  /// happened — the "upcoming" bucket in the Coaching section.
  bool get isUpcoming =>
      (status == ProfessionalBookingStatus.requested ||
          status == ProfessionalBookingStatus.confirmed) &&
      end.isAfter(DateTime.now());

  /// A confirmed session whose end time has passed, ready to be marked
  /// complete by either party (client or professional — first tap wins).
  bool get completionEligible =>
      status == ProfessionalBookingStatus.confirmed &&
      end.isBefore(DateTime.now());

  /// A completed session the caller hasn't reviewed yet. For a package
  /// booking, only the *final* session is review-eligible — earlier
  /// sessions in the same package are skipped (one review per package, not
  /// per session).
  /// Packages were a coach concept and went with the coach half of the
  /// booking system; a referee books one match at a time, so a completed
  /// booking is reviewable outright.
  bool get reviewEligible =>
      status == ProfessionalBookingStatus.completed && !reviewed;

  factory ProfessionalBookingItem.fromJson(Map<String, dynamic> json) {
    final pro = json['professional'] as Map<String, dynamic>?;
    final service = json['professional_service'] as Map<String, dynamic>?;
    final location = json['location'] as Map<String, dynamic>?;
    final reviewRaw = json['referee_booking_review'];
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
      professionalLinkedUserId: pro?['linked_user_id'] as String?,
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
      serviceId: json['service_id'] as String?,
      maxParticipants: (service?['max_participants'] as num?)?.toInt(),
    );
  }
}
