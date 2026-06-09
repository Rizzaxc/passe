import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/auth_controller.dart';
import 'activity/feed_controller.dart';
import 'activity/upcoming_controller.dart';
import 'lobby_detail_controller.dart';

part 'schedule_activity_controller.g.dart';

/// Payment surface picked when an activity requires a deposit.
///
/// Mirrors the `activity_payment_type` enum on the DB side.
enum ActivityPaymentType {
  manual('manual'),
  da('da');

  final String db;
  const ActivityPaymentType(this.db);
}

@riverpod
class ScheduleActivityController extends _$ScheduleActivityController {
  final supabase = Supabase.instance.client;

  @override
  bool build(String lobbyId) => false; // in-flight flag

  Future<void> schedule({
    required DateTime start,
    required DateTime end,
    String? locationId,
    bool prepaymentRequired = false,
    ActivityPaymentType? paymentType,
    num? prepaymentAmount,
    int? confirmationThreshold,
    DateTime? confirmationDeadline,
    /// 0 = Mon … 6 = Sun (ISO ordering). null = one-off session.
    int? recurrenceDayOfWeek,
  }) async {
    state = true;
    try {
      final user = ref.read(authControllerProvider).value;
      if (user == null || user.id == null) return;

      final lobbyInfo =
          ref.read(lobbyDetailControllerProvider(lobbyId)).value;
      if (lobbyInfo == null) return;

      final params = <String, dynamic>{
        'user_id': user.id,
        'sport_id': lobbyInfo.lobby.sport.index,
        'lobby_id': lobbyId,
        'start_time': start.toUtc().toIso8601String(),
        'end_time': end.toUtc().toIso8601String(),
        'prepayment_required': prepaymentRequired,
      };

      if (locationId != null) params['location_id'] = locationId;
      if (prepaymentRequired && paymentType != null) {
        params['payment_type'] = paymentType.db;
        params['prepayment_amount'] = prepaymentAmount;
      }
      if (confirmationThreshold != null) {
        params['confirmation_threshold'] = confirmationThreshold;
      }
      if (confirmationDeadline != null) {
        params['confirmation_deadline'] =
            confirmationDeadline.toUtc().toIso8601String();
      }
      if (recurrenceDayOfWeek != null) {
        params['recurrence_day_of_week'] = recurrenceDayOfWeek;
      }

      await supabase
          .from('activity')
          .insert(params)
          .timeout(const Duration(seconds: 5));

      // Post a feed item so the captain-side activity tab shows the new
      // session immediately. The `scheduled` update kind + blue tone
      // matches the existing UpdateKind / FeedTone vocabulary.
      await supabase.from('lobby_feed_item').insert({
        'lobby_id': lobbyId,
        'author_id': user.id,
        'kind': 'update',
        'payload': {
          'title': 'Lên lịch buổi chơi',
          'kind': 'scheduled',
          'tone': 'blue',
          'fields': [
            ['Ngày', _fmtDate(start)],
            ['Giờ', '${_fmtTime(start)} - ${_fmtTime(end)}'],
            if (recurrenceDayOfWeek != null) ['Lặp lại', 'Hằng tuần'],
            if (prepaymentRequired && prepaymentAmount != null)
              ['Đặt cọc', '$prepaymentAmount ${paymentType == ActivityPaymentType.da ? 'Đá' : 'đ'}'],
          ],
        },
      }).timeout(const Duration(seconds: 5));

      ref.invalidate(lobbyFeedControllerProvider(lobbyId));
      ref.invalidate(lobbyUpcomingActivityControllerProvider(lobbyId));
    } finally {
      state = false;
    }
  }

  static const _wd = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  static String _fmtDate(DateTime d) =>
      '${_wd[d.weekday - 1]}, ${d.day}/${d.month}/${d.year}';

  static String _fmtTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
