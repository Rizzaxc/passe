import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/model/activity.dart';

part 'upcoming_controller.g.dart';

/// The next "live" activity for a lobby — either an upcoming one-off or
/// the next virtual occurrence of a recurring series.
///
/// [nextStart] is the resolved start instant (may differ from the
/// stored row's `start_time` when the row is a recurring template
/// whose first occurrence has already happened).
///
/// The fields below (location, prepayment, confirmation) come straight off
/// the `activity` row / its `location` join but aren't part of the shared
/// `Activity` freezed model, so they're carried here instead of bloating a
/// model used elsewhere in the app.
class UpcomingActivity {
  final Activity activity;
  final DateTime nextStart;

  /// Null for one-off activities, 0–6 (Mon..Sun, ISO ordering) for a
  /// weekly recurrence.
  final int? recurrenceDayOfWeek;

  final String? locationId;
  final String? locationName;
  final String? locationDistrict;

  final bool prepaymentRequired;
  final String? paymentType; // 'manual' | 'da'
  final num? prepaymentAmount;

  final int? confirmationThreshold;
  final DateTime? confirmationDeadline;

  const UpcomingActivity({
    required this.activity,
    required this.nextStart,
    required this.recurrenceDayOfWeek,
    required this.locationId,
    required this.locationName,
    required this.locationDistrict,
    required this.prepaymentRequired,
    required this.paymentType,
    required this.prepaymentAmount,
    required this.confirmationThreshold,
    required this.confirmationDeadline,
  });

  bool get isRecurring => recurrenceDayOfWeek != null;

  /// [nextStart] shifted by the row's own start→end duration, so a
  /// recurring series' "next occurrence" gets the right end time too.
  DateTime? get nextEnd {
    final end = activity.endTime;
    if (end == null) return null;
    return nextStart.add(end.difference(activity.startTime));
  }
}

/// Soonest upcoming activity for a lobby, accounting for weekly
/// recurrence.
///
/// Strategy:
///   1. Query for any candidate — either `start_time > now` (one-off) or
///      `recurrence_day_of_week IS NOT NULL` (recurring series whose
///      first occurrence may already be in the past).
///   2. Compute the next-start instant for each candidate (recurring
///      ones get advanced forward to the next matching weekday at the
///      same time-of-day).
///   3. Return the row with the earliest computed next-start.
@riverpod
class LobbyUpcomingActivityController extends _$LobbyUpcomingActivityController {
  final supabase = Supabase.instance.client;

  @override
  Future<UpcomingActivity?> build(String lobbyId) async {
    final nowUtc = DateTime.now().toUtc();

    final response = await supabase
        .from('activity')
        .select('*, location(name, district)')
        .eq('lobby_id', lobbyId)
        .or(
          'start_time.gt.${nowUtc.toIso8601String()},'
          'recurrence_day_of_week.not.is.null',
        )
        .timeout(const Duration(seconds: 5));

    final rows = (response as List).cast<Map<String, dynamic>>();
    if (rows.isEmpty) return null;

    UpcomingActivity? best;
    for (final row in rows) {
      final activity = Activity.fromJson(_stripExtras(row));
      final recDow = (row['recurrence_day_of_week'] as num?)?.toInt();
      final next = _nextOccurrence(
        startTime: activity.startTime,
        recurrenceDayOfWeek: recDow,
        now: DateTime.now(),
      );
      if (next == null) continue;
      if (best == null || next.isBefore(best.nextStart)) {
        final location = row['location'] as Map<String, dynamic>?;
        best = UpcomingActivity(
          activity: activity,
          nextStart: next,
          recurrenceDayOfWeek: recDow,
          locationId: row['location_id'] as String?,
          locationName: location?['name'] as String?,
          locationDistrict: location?['district'] as String?,
          prepaymentRequired: (row['prepayment_required'] as bool?) ?? false,
          paymentType: row['payment_type'] as String?,
          prepaymentAmount: row['prepayment_amount'] as num?,
          confirmationThreshold:
              (row['confirmation_threshold'] as num?)?.toInt(),
          confirmationDeadline: row['confirmation_deadline'] != null
              ? DateTime.parse(row['confirmation_deadline'] as String)
              : null,
        );
      }
    }
    return best;
  }

  /// Strip columns the freezed `Activity.fromJson` doesn't know about
  /// so the deserialisation succeeds. The augmented fields (location join,
  /// recurrence, prepayment, confirmation) are read directly from the row
  /// above and carried on `UpcomingActivity` instead.
  Map<String, dynamic> _stripExtras(Map<String, dynamic> row) {
    return {...row}
      ..remove('location')
      ..remove('recurrence_day_of_week')
      ..remove('location_id')
      ..remove('prepayment_required')
      ..remove('payment_type')
      ..remove('prepayment_amount')
      ..remove('confirmation_threshold')
      ..remove('confirmation_deadline');
  }

  /// Compute the next start instant for a single activity row.
  ///
  /// One-off: returns `startTime` iff it's still in the future; null
  /// otherwise (already happened).
  ///
  /// Recurring: returns the next date at or after `now` whose
  /// `weekday - 1` matches `recurrenceDayOfWeek`, with the same
  /// time-of-day as the original `startTime`.
  static DateTime? _nextOccurrence({
    required DateTime startTime,
    required int? recurrenceDayOfWeek,
    required DateTime now,
  }) {
    if (recurrenceDayOfWeek == null) {
      return startTime.isAfter(now) ? startTime : null;
    }

    // Walk forward up to 7 days from "today" to find the matching
    // weekday. ISO day-of-week is 1..7 (Mon..Sun) — our enum stores
    // 0..6, so add 1 to compare.
    final targetWeekday = recurrenceDayOfWeek + 1;
    final today = DateTime(now.year, now.month, now.day);
    final local = startTime.toLocal();
    for (var i = 0; i < 8; i++) {
      final candidate = today.add(Duration(days: i));
      if (candidate.weekday != targetWeekday) continue;
      final occurrence = DateTime(
        candidate.year,
        candidate.month,
        candidate.day,
        local.hour,
        local.minute,
      );
      if (occurrence.isAfter(now)) return occurrence;
    }
    return null;
  }
}
