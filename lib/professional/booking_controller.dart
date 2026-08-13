import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_controller.dart';
import '../core/model/enum.dart';

part 'booking_controller.g.dart';

/// An active, priced offering of a professional — what the booking sheet
/// lets the client pick from.
class ProfessionalServiceOption {
  final String id;
  final String serviceType;
  final String? description;
  final double? priceAmount;
  final int? minDurationMinutes;
  final int? maxParticipants;
  final int sessionCount;
  final ProfessionalPricingKind pricingKind;

  const ProfessionalServiceOption({
    required this.id,
    required this.serviceType,
    this.description,
    this.priceAmount,
    this.minDurationMinutes,
    this.maxParticipants,
    required this.sessionCount,
    required this.pricingKind,
  });

  bool get isPackage => sessionCount > 1;
  bool get isGroup => (maxParticipants ?? 1) > 1;

  /// Price of one session at [duration]. Hourly services scale with time;
  /// per-session services remain fixed regardless of duration or headcount.
  double? priceFor(Duration duration) {
    final amount = priceAmount;
    if (amount == null) return null;
    return pricingKind == ProfessionalPricingKind.hourly
        ? amount * duration.inMinutes / 60
        : amount;
  }

  factory ProfessionalServiceOption.fromJson(Map<String, dynamic> json) {
    return ProfessionalServiceOption(
      id: json['id'] as String,
      serviceType: json['service_type'] as String,
      description: json['service_description'] as String?,
      priceAmount: double.tryParse(json['price_amount']?.toString() ?? ''),
      minDurationMinutes: (json['min_duration_minutes'] as num?)?.toInt(),
      maxParticipants: (json['max_participants'] as num?)?.toInt(),
      sessionCount: (json['session_count'] as num?)?.toInt() ?? 1,
      pricingKind: ProfessionalPricingKind.fromValue(
        json['pricing_kind'] as String?,
      ),
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
/// (`referee_booking_conflicts` RPC). Warns in the booking sheet UI —
/// the hard gate is `accept_referee_booking`'s atomic overlap check.
@riverpod
Future<bool> hasBookingConflict(
  Ref ref,
  String professionalId,
  DateTime start,
  DateTime end,
) async {
  final response = await Supabase.instance.client
      .rpc(
        'referee_booking_conflicts',
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

  /// [participantUserIds] populates `referee_booking_additional_users` for a
  /// group service. [activityId] links the booking to a *lobby* activity's
  /// referee slot.
  ///
  /// Packages are gone with the coach half of the booking system — a referee
  /// books one match at a time, and the RPC rejects package parameters.
  Future<void> book({
    required String serviceId,
    required DateTime start,
    required DateTime end,
    String? notes,
    String? locationId,
    String? customLocationName,
    List<String>? participantUserIds,
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
            'request_referee_booking',
            params: {
              'p_professional_id': professionalId,
              'p_service_id': serviceId,
              'p_start': start.toUtc().toIso8601String(),
              'p_end': end.toUtc().toIso8601String(),
              'p_notes': notes,
              'p_location_id': locationId,
              'p_custom_location_name': customLocationName,
              'p_participant_user_ids': participantUserIds ?? const <String>[],
              'p_activity_id': activityId,
            },
          )
          .timeout(const Duration(seconds: 5));
    } finally {
      state = false;
    }
  }
}
