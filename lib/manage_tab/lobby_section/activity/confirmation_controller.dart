import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/auth_controller.dart';

part 'confirmation_controller.g.dart';

/// Snapshot of an activity's confirmation state — the four numbers the
/// hero's RSVP control needs in one bundle.
///
/// `meConfirmed` = is the current user in the confirmation list (the
/// "member confirmation" side).
///
/// `activityConfirmed` = does the activity itself count as official
/// — either because [threshold] is null (fixed-schedule groups) or
/// because [confirmedCount] >= [threshold].
class ActivityConfirmationStatus {
  final int confirmedCount;
  final int? threshold;
  final bool meConfirmed;
  final bool activityConfirmed;

  const ActivityConfirmationStatus({
    required this.confirmedCount,
    required this.threshold,
    required this.meConfirmed,
    required this.activityConfirmed,
  });
}

/// Activity-level + member-level confirmation for one activity row.
///
/// The notifier reads through the `activity_confirmation_status` RPC
/// (single round-trip) and writes by inserting / deleting the caller's
/// row in `activity_confirmation`. Writes flip the local state
/// **optimistically** (so the RSVP control reacts in the same frame),
/// then reconcile against the server re-read; on failure the previous
/// snapshot is restored.
@riverpod
class ActivityConfirmationController
    extends _$ActivityConfirmationController {
  final supabase = Supabase.instance.client;

  @override
  Future<ActivityConfirmationStatus> build(String activityId) async {
    return _fetch(activityId);
  }

  Future<ActivityConfirmationStatus> _fetch(String activityId) async {
    final rows = await supabase
        .rpc('activity_confirmation_status', params: {
          'p_activity_id': activityId,
        })
        .timeout(const Duration(seconds: 5));

    final row = (rows as List).first as Map<String, dynamic>;
    return ActivityConfirmationStatus(
      confirmedCount: (row['confirmed_count'] as num).toInt(),
      threshold: (row['threshold'] as num?)?.toInt(),
      meConfirmed: row['me_confirmed'] as bool,
      activityConfirmed: row['activity_confirmed'] as bool,
    );
  }

  /// Local snapshot with `meConfirmed` toggled and the count nudged by
  /// [delta] — used to flip the UI before the server round-trip.
  ActivityConfirmationStatus _withSelf(
    ActivityConfirmationStatus s,
    bool confirmed,
    int delta,
  ) {
    final count = (s.confirmedCount + delta).clamp(0, 1 << 30);
    return ActivityConfirmationStatus(
      confirmedCount: count,
      threshold: s.threshold,
      meConfirmed: confirmed,
      activityConfirmed: s.threshold == null || count >= s.threshold!,
    );
  }

  /// Member confirmation — caller commits to attending. Idempotent via
  /// the `(activity_id, user_id)` primary key; `ignoreDuplicates` makes
  /// this an `ON CONFLICT DO NOTHING` insert so it never needs an UPDATE
  /// RLS policy.
  Future<void> confirm(String activityId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final prev = state.value;
    if (prev != null && !prev.meConfirmed) {
      state = AsyncData(_withSelf(prev, true, 1)); // optimistic
    }

    try {
      await supabase
          .from('activity_confirmation')
          .upsert(
            {'activity_id': activityId, 'user_id': userId},
            ignoreDuplicates: true,
          )
          .timeout(const Duration(seconds: 5));
      state = AsyncData(await _fetch(activityId)); // reconcile
    } catch (_) {
      if (prev != null) state = AsyncData(prev); // rollback
      rethrow;
    }
  }

  /// Retract a previous confirmation. The DELETE policy lets a user
  /// only delete their own row; the WHERE clause keeps that aligned.
  Future<void> retract(String activityId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final prev = state.value;
    if (prev != null && prev.meConfirmed) {
      state = AsyncData(_withSelf(prev, false, -1)); // optimistic
    }

    try {
      await supabase
          .from('activity_confirmation')
          .delete()
          .eq('activity_id', activityId)
          .eq('user_id', userId)
          .timeout(const Duration(seconds: 5));
      state = AsyncData(await _fetch(activityId)); // reconcile
    } catch (_) {
      if (prev != null) state = AsyncData(prev); // rollback
      rethrow;
    }
  }
}
