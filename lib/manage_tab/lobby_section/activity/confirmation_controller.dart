import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/auth_controller.dart';
import '../../../core/model/enum.dart';

part 'confirmation_controller.g.dart';

/// Snapshot of an activity's RSVP state — the numbers the hero's RSVP
/// control needs in one bundle.
///
/// [myAttendance] is the current user's own RSVP (`null` = no response yet).
///
/// [activityConfirmed] = does the activity itself count as official —
/// either because [threshold] is null (fixed-schedule groups) or because
/// [confirmedCount] (the **going** tally only) >= [threshold]. `maybe` /
/// `out` never count toward the threshold.
class ActivityConfirmationStatus {
  final int confirmedCount; // "going" only
  final int maybeCount;
  final int? threshold;
  final Attendance? myAttendance;
  final bool activityConfirmed;

  /// True once the confirmation deadline has passed while still under
  /// threshold (`activity.at_risk_notified_at IS NOT NULL`) — freezes direct
  /// RSVP writes for everyone, going/out included, until the organizer or a
  /// maybe/never-responded member resolves it via the notification card (see
  /// `resolve_at_risk_activity_rsvp` / `resolve_at_risk_activity_organizer`).
  /// Distinct from [activityConfirmed]'s own quorum-reached lock.
  final bool deadlineLocked;

  const ActivityConfirmationStatus({
    required this.confirmedCount,
    required this.maybeCount,
    required this.threshold,
    required this.myAttendance,
    required this.activityConfirmed,
    this.deadlineLocked = false,
  });
}

/// Activity-level + member-level RSVP for one activity row.
///
/// The notifier reads through the `activity_confirmation_status` RPC
/// (single round-trip) and writes by upserting the caller's row in
/// `activity_confirmation` with the chosen [Attendance]. Writes flip the
/// local state **optimistically** (so the RSVP control reacts in the same
/// frame), then reconcile against the server re-read; on failure the
/// previous snapshot is restored.
@riverpod
class ActivityConfirmationController extends _$ActivityConfirmationController {
  final supabase = Supabase.instance.client;

  @override
  Future<ActivityConfirmationStatus> build(String activityId) async {
    return _fetch(activityId);
  }

  Future<ActivityConfirmationStatus> _fetch(String activityId) async {
    final rows = await supabase
        .rpc(
          'activity_confirmation_status',
          params: {'p_activity_id': activityId},
        )
        .timeout(const Duration(seconds: 5));

    final row = (rows as List).first as Map<String, dynamic>;
    return ActivityConfirmationStatus(
      confirmedCount: (row['confirmed_count'] as num).toInt(),
      maybeCount: (row['maybe_count'] as num).toInt(),
      threshold: (row['threshold'] as num?)?.toInt(),
      myAttendance: Attendance.fromValue(row['my_attendance'] as String?),
      activityConfirmed: row['activity_confirmed'] as bool,
      deadlineLocked: row['deadline_locked'] as bool? ?? false,
    );
  }

  /// Local snapshot with the caller's RSVP changed to [next], adjusting the
  /// going / maybe tallies — used to flip the UI before the server round-trip.
  ActivityConfirmationStatus _withAttendance(
    ActivityConfirmationStatus s,
    Attendance next,
  ) {
    final wasGoing = s.myAttendance == Attendance.going;
    final wasMaybe = s.myAttendance == Attendance.maybe;
    final going =
        s.confirmedCount +
        (next == Attendance.going ? 1 : 0) -
        (wasGoing ? 1 : 0);
    final maybe =
        s.maybeCount + (next == Attendance.maybe ? 1 : 0) - (wasMaybe ? 1 : 0);
    return ActivityConfirmationStatus(
      confirmedCount: going.clamp(0, 1 << 30),
      maybeCount: maybe.clamp(0, 1 << 30),
      threshold: s.threshold,
      myAttendance: next,
      activityConfirmed: s.threshold == null || going >= s.threshold!,
      deadlineLocked: s.deadlineLocked,
    );
  }

  /// Set the caller's RSVP. Upserts on the `(activity_id, user_id)` primary
  /// key, so switching going ⇄ maybe ⇄ out updates the existing row.
  Future<void> setAttendance(String activityId, Attendance attendance) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final prev = state.value;
    if (prev != null && prev.myAttendance != attendance) {
      state = AsyncData(_withAttendance(prev, attendance)); // optimistic
    }

    try {
      await supabase
          .from('activity_confirmation')
          .upsert({
            'activity_id': activityId,
            'user_id': userId,
            'attendance': attendance.value,
          })
          .timeout(const Duration(seconds: 5));
      state = AsyncData(await _fetch(activityId)); // reconcile
    } catch (_) {
      if (prev != null) state = AsyncData(prev); // rollback
      rethrow;
    }
  }
}

/// One row of the hero's RSVP avatar strip.
class Attendee {
  final String userId;
  final String username;
  final String? generatedAvatar;
  final Attendance attendance;
  const Attendee({
    required this.userId,
    required this.username,
    this.generatedAvatar,
    required this.attendance,
  });
}

/// Small sample of who's going / maybe, for the hero's avatar strip.
/// `activity_confirmation_status` only returns aggregate counts, so this
/// is a separate lightweight query rather than bloating that RPC.
@riverpod
Future<List<Attendee>> activityAttendees(Ref ref, String activityId) async {
  final supabase = Supabase.instance.client;
  final rows = await supabase
      .from('activity_confirmation')
      .select(
        'attendance, user!activity_confirmation_user_id_fkey(id, username, details)',
      )
      .eq('activity_id', activityId)
      .inFilter('attendance', ['going', 'maybe'])
      .order('confirmed_at')
      .limit(6)
      .timeout(const Duration(seconds: 5));

  return (rows as List).map((row) {
    final u = row['user'] as Map<String, dynamic>;
    final details = u['details'] as Map<String, dynamic>?;
    return Attendee(
      userId: u['id'] as String,
      username: u['username'] as String,
      generatedAvatar: details?['generatedAvatar'] as String?,
      attendance: Attendance.fromValue(row['attendance'] as String)!,
    );
  }).toList();
}
