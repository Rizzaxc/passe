import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_controller.dart';

part 'booking_controller.g.dart';

/// An active, priced offering of a professional — what the booking sheet
/// lets the client pick from.
class ProfessionalServiceOption {
  final String id;
  final String serviceType;
  final String? description;
  final double? hourlyRate;
  final int? minDurationMinutes;
  final int? maxParticipants;
  final int sessionCount;
  final String pricingMode; // 'per_session' | 'wholesale'

  const ProfessionalServiceOption({
    required this.id,
    required this.serviceType,
    this.description,
    this.hourlyRate,
    this.minDurationMinutes,
    this.maxParticipants,
    required this.sessionCount,
    required this.pricingMode,
  });

  bool get isPackage => sessionCount > 1;
  bool get isGroup => (maxParticipants ?? 1) > 1;

  factory ProfessionalServiceOption.fromJson(Map<String, dynamic> json) {
    return ProfessionalServiceOption(
      id: json['id'] as String,
      serviceType: json['service_type'] as String,
      description: json['service_description'] as String?,
      hourlyRate: double.tryParse(json['hourly_rate']?.toString() ?? ''),
      minDurationMinutes: (json['min_duration_minutes'] as num?)?.toInt(),
      maxParticipants: (json['max_participants'] as num?)?.toInt(),
      sessionCount: (json['session_count'] as num?)?.toInt() ?? 1,
      pricingMode: json['pricing_mode'] as String? ?? 'per_session',
    );
  }
}

/// Active services offered by one professional, for the booking sheet's
/// service picker. RLS only exposes services for *verified* professionals
/// (`professional_service` "Enable read for active services..." policy),
/// so this comes back empty for an unverified pro.
@riverpod
Future<List<ProfessionalServiceOption>> professionalServices(
  Ref ref,
  String professionalId,
) async {
  final response = await Supabase.instance.client
      .from('professional_service')
      .select()
      .eq('professional_id', professionalId)
      .eq('is_active', true)
      .timeout(const Duration(seconds: 5));

  return (response as List)
      .map((e) => ProfessionalServiceOption.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// Soft availability check: existing *confirmed* bookings for this
/// professional overlapping the requested window
/// (`professional_booking_conflicts` RPC). Warns in the booking sheet UI —
/// the hard gate is `accept_professional_booking`'s atomic overlap check.
@riverpod
Future<bool> hasBookingConflict(
  Ref ref,
  String professionalId,
  DateTime start,
  DateTime end,
) async {
  final response = await Supabase.instance.client
      .rpc(
        'professional_booking_conflicts',
        params: {
          'p_professional_id': professionalId,
          'p_start': start.toUtc().toIso8601String(),
          'p_end': end.toUtc().toIso8601String(),
        },
      )
      .timeout(const Duration(seconds: 5));
  return (response as List).isNotEmpty;
}

/// Creates a `professional_booking` row for one professional. RLS ("Clients
/// can manage their own bookings") scopes the insert to the caller as
/// `client_user_id`; the row starts at the default `requested` status —
/// the professional accepts/rejects it via `accept_professional_booking`/
/// `reject_professional_booking` (schema/professional_booking_actions.sql).
@riverpod
class ProfessionalBookingController extends _$ProfessionalBookingController {
  final supabase = Supabase.instance.client;

  @override
  bool build(String professionalId) => false; // in-flight flag

  /// [existingPackageId] schedules the next session of an already-purchased
  /// rolling package (no new package row). [newPackageSessionCount] > 1
  /// instead creates a fresh `professional_booking_package` container plus
  /// this one first session. Neither set = a plain single booking.
  /// [participantUserIds] populates `booking_additional_users` for a group
  /// service. [activityId] + [activityAttachColumn] link the new booking back
  /// to a *lobby* activity as an attached professional — the column is
  /// `coach_booking_id` or `referee_booking_id` (chosen by the pro's role),
  /// NOT `professional_booking_id` (which is reserved for a standalone
  /// client pro-session and is mutually exclusive with `lobby_id` via
  /// `activity_source_exclusivity`). See
  /// schema/activity_professional_attachment.sql.
  Future<void> book({
    required String serviceId,
    required DateTime start,
    required DateTime end,
    double? agreedRate,
    String? notes,
    String? locationId,
    List<String>? participantUserIds,
    String? existingPackageId,
    int? newPackageSessionCount,
    double? newPackageTotalPrice,
    String? activityId,
    String? activityAttachColumn,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    state = true;
    try {
      var packageId = existingPackageId;

      if (packageId == null &&
          newPackageSessionCount != null &&
          newPackageSessionCount > 1) {
        final packageRow = await supabase
            .from('professional_booking_package')
            .insert({
              'client_user_id': userId,
              'professional_id': professionalId,
              'service_id': serviceId,
              'sessions_total': newPackageSessionCount,
              'total_price': ?newPackageTotalPrice,
            })
            .select('id')
            .single()
            .timeout(const Duration(seconds: 5));
        packageId = packageRow['id'] as String;
      }

      final bookingRow = await supabase
          .from('professional_booking')
          .insert({
            'client_user_id': userId,
            'professional_id': professionalId,
            'service_id': serviceId,
            'booking_time_start': start.toUtc().toIso8601String(),
            'booking_time_end': end.toUtc().toIso8601String(),
            'agreed_rate': ?agreedRate,
            if (notes != null && notes.isNotEmpty) 'client_notes': notes,
            if (locationId != null && locationId.isNotEmpty)
              'location_id': locationId,
            'package_id': ?packageId,
          })
          .select('id')
          .single()
          .timeout(const Duration(seconds: 5));
      final bookingId = bookingRow['id'] as String;

      if (participantUserIds != null && participantUserIds.isNotEmpty) {
        await supabase
            .from('booking_additional_users')
            .insert([
              for (final uid in participantUserIds)
                {'booking_id': bookingId, 'user_id': uid},
            ])
            .timeout(const Duration(seconds: 5));
      }

      if (activityId != null && activityAttachColumn != null) {
        await supabase
            .from('activity')
            .update({activityAttachColumn: bookingId})
            .eq('id', activityId)
            .timeout(const Duration(seconds: 5));
      }
    } finally {
      state = false;
    }
  }
}
