import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/auth_controller.dart';
import '../../professional/professional_booking.dart';

part 'coaching_controller.g.dart';

const _selectColumns = '''
  id, professional_id, service_id, booking_time_start, booking_time_end, agreed_rate, status,
  client_notes, professional_notes, package_id,
  professional!inner(display_name, professional_role, is_verified, average_rating, review_count),
  professional_service(service_type, max_participants),
  location(name),
  professional_booking_review(rating),
  professional_booking_package(sessions_total, sessions_used)
''';

/// The signed-in user's coach bookings (`professional_booking` rows where
/// the linked professional's role is `coach`) — real data behind Manage ▸
/// Coaching, replacing the fully-mocked course/session prototype. Referee
/// bookings surface elsewhere (attached to a lobby activity via
/// `activity.referee_booking_id`, shown on the activity hero card; and on a
/// recorded match via `lobby_match.referee_booking_id`), so this coach-only
/// view excludes them.
@riverpod
Future<List<ProfessionalBookingItem>> coachingBookings(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final response = await Supabase.instance.client
      .from('professional_booking')
      .select(_selectColumns)
      .eq('client_user_id', userId)
      .eq('professional.professional_role', 'coach')
      .order('booking_time_start', ascending: false)
      .timeout(const Duration(seconds: 5));

  return (response as List)
      .map((e) => ProfessionalBookingItem.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// Client-side actions on a coaching booking: cancelling an upcoming
/// request/confirmation, marking a past confirmed session complete (either
/// party, first tap wins — see `schema/professional_booking_completion.sql`),
/// or reviewing a completed session.
@riverpod
class CoachingBookingActionController
    extends _$CoachingBookingActionController {
  final supabase = Supabase.instance.client;

  @override
  bool build() => false; // in-flight flag

  Future<void> cancel(String bookingId) async {
    state = true;
    try {
      await supabase
          .from('professional_booking')
          .update({'status': 'cancelled_by_client'})
          .eq('id', bookingId)
          .timeout(const Duration(seconds: 5));
      ref.invalidate(coachingBookingsProvider);
    } finally {
      state = false;
    }
  }

  Future<void> markComplete(String bookingId) async {
    state = true;
    try {
      await supabase
          .from('professional_booking')
          .update({'status': 'completed'})
          .eq('id', bookingId)
          .timeout(const Duration(seconds: 5));
      ref.invalidate(coachingBookingsProvider);
    } finally {
      state = false;
    }
  }

  Future<void> submitReview({
    required String bookingId,
    required String professionalId,
    required double rating,
    String? comment,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    state = true;
    try {
      await supabase
          .from('professional_booking_review')
          .insert({
            'booking_id': bookingId,
            'reviewer_user_id': userId,
            'professional_id': professionalId,
            'rating': rating,
            if (comment != null && comment.isNotEmpty) 'comment': comment,
          })
          .timeout(const Duration(seconds: 5));
      ref.invalidate(coachingBookingsProvider);
    } finally {
      state = false;
    }
  }
}
