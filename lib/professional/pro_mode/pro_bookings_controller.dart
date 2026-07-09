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
    );
  }
}

const _proSelectColumns = '''
  id, booking_time_start, booking_time_end, agreed_rate, status,
  client_notes, professional_notes, package_id,
  client:client_user_id(username),
  professional_service(service_type),
  location(name)
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
          .rpc('accept_professional_booking', params: {'p_booking_id': bookingId})
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
          .from('professional_booking')
          .update({'status': 'completed'})
          .eq('id', bookingId)
          .timeout(const Duration(seconds: 5));
      _invalidateAll(ref, professionalId);
    } finally {
      state = false;
    }
  }
}
