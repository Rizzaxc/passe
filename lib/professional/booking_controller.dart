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

/// Requests a booking through the server-side professional booking workflow.
/// The RPC derives ownership, price, package details, and the initial status;
/// the professional then accepts or rejects the request through the matching
/// action RPCs.
@riverpod
class ProfessionalBookingController extends _$ProfessionalBookingController {
  final supabase = Supabase.instance.client;

  @override
  bool build(String professionalId) => false; // in-flight flag

  /// [existingPackageId] schedules the next session of an already-purchased
  /// rolling package (no new package row). [createPackage] creates a fresh
  /// `professional_booking_package` container plus its first session.
  /// [participantUserIds] populates `booking_additional_users` for a group
  /// service. [activityId] links the booking to a *lobby* activity in the
  /// coach/referee slot derived from the professional's role.
  Future<void> book({
    required String serviceId,
    required DateTime start,
    required DateTime end,
    String? notes,
    String? locationId,
    List<String>? participantUserIds,
    String? existingPackageId,
    bool createPackage = false,
    String? activityId,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      throw const AuthException(
        'Authentication required to book a professional.',
      );
    }

    state = true;
    try {
      await supabase
          .rpc(
            'request_professional_booking',
            params: {
              'p_professional_id': professionalId,
              'p_service_id': serviceId,
              'p_start': start.toUtc().toIso8601String(),
              'p_end': end.toUtc().toIso8601String(),
              'p_notes': notes,
              'p_location_id': locationId,
              'p_participant_user_ids': participantUserIds ?? const <String>[],
              'p_existing_package_id': existingPackageId,
              'p_create_package': createPackage,
              'p_activity_id': activityId,
            },
          )
          .timeout(const Duration(seconds: 5));
    } finally {
      state = false;
    }
  }
}
