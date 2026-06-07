import 'package:riverpod_annotation/riverpod_annotation.dart';

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

/// Captain-side "schedule a play session" mutation for a lobby.
///
/// TODO(activity-schedule): currently a no-op so the captain-side
/// CTA flow completes without persisting. Wire to a Supabase insert
/// into `activity` (with all the prepayment / confirmation / recurrence
/// columns added by `schema/activity_scheduling.sql`) once the captain-
/// only RLS policy lands.
@riverpod
class ScheduleActivityController extends _$ScheduleActivityController {
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
      // No-op for now. Real call shape:
      //   await supabase.from('activity').insert({
      //     'lobby_id': lobbyId,
      //     'start_time': start.toIso8601String(),
      //     'end_time': end.toIso8601String(),
      //     'location_id': locationId,
      //     'prepayment_required': prepaymentRequired,
      //     'payment_type': paymentType?.db,
      //     'prepayment_amount': prepaymentAmount,
      //     'confirmation_threshold': confirmationThreshold,
      //     'confirmation_deadline': confirmationDeadline?.toIso8601String(),
      //     'recurrence_day_of_week': recurrenceDayOfWeek,
      //     ...
      //   });
      await Future<void>.delayed(const Duration(milliseconds: 300));
    } finally {
      state = false;
    }
  }
}
