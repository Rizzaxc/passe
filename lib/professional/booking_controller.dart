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

  const ProfessionalServiceOption({
    required this.id,
    required this.serviceType,
    this.description,
    this.hourlyRate,
    this.minDurationMinutes,
  });

  factory ProfessionalServiceOption.fromJson(Map<String, dynamic> json) {
    return ProfessionalServiceOption(
      id: json['id'] as String,
      serviceType: json['service_type'] as String,
      description: json['service_description'] as String?,
      hourlyRate: double.tryParse(json['hourly_rate']?.toString() ?? ''),
      minDurationMinutes: (json['min_duration_minutes'] as num?)?.toInt(),
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

/// Creates a `professional_booking` row for one professional. RLS ("Clients
/// can manage their own bookings") scopes the insert to the caller as
/// `client_user_id`; the row starts at the default `requested` status and
/// the professional accepts/rejects it out of band (no in-app flow for the
/// professional side yet).
@riverpod
class ProfessionalBookingController extends _$ProfessionalBookingController {
  final supabase = Supabase.instance.client;

  @override
  bool build(String professionalId) => false; // in-flight flag

  Future<void> book({
    required String serviceId,
    required DateTime start,
    required DateTime end,
    double? agreedRate,
    String? notes,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    state = true;
    try {
      await supabase
          .from('professional_booking')
          .insert({
            'client_user_id': userId,
            'professional_id': professionalId,
            'service_id': serviceId,
            'booking_time_start': start.toUtc().toIso8601String(),
            'booking_time_end': end.toUtc().toIso8601String(),
            if (agreedRate != null) 'agreed_rate': agreedRate,
            if (notes != null && notes.isNotEmpty) 'client_notes': notes,
          })
          .timeout(const Duration(seconds: 5));
    } finally {
      state = false;
    }
  }
}
