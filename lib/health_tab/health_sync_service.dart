import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../auth/auth_controller.dart';
import '../core/model/activity.dart';
import 'health_controller.dart';
import 'health_data_controller.dart';
import 'health_data_service.dart';

part 'health_sync_service.g.dart';

enum HealthSyncPhase { idle, syncing }

/// Result of a [HealthSyncController.syncNow] pass, for the completion toast.
class HealthSyncResult {
  final int daysSynced;
  final int activitiesCaptured;
  final bool skipped; // true when not linked / no permission / guest

  const HealthSyncResult({
    this.daysSynced = 0,
    this.activitiesCaptured = 0,
    this.skipped = false,
  });
}

/// The device → Supabase sync engine. Fired once on app launch (non-blocking)
/// and on the explicit Sync button. Pull-to-refresh does NOT call this — it only
/// re-reads Supabase via the data providers.
@riverpod
class HealthSyncController extends _$HealthSyncController {
  final _supabase = Supabase.instance.client;
  final _talker = Talker();

  @override
  HealthSyncPhase build() => HealthSyncPhase.idle;

  HealthDataService get _service => ref.read(healthDataServiceProvider.notifier);

  /// Pull the device's data into Supabase. Self-guards guests / unlinked /
  /// revoked permissions, so it is safe to fire unconditionally at launch.
  Future<HealthSyncResult> syncNow() async {
    if (state == HealthSyncPhase.syncing) return const HealthSyncResult();

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return const HealthSyncResult(skipped: true);

    // Reuse the link-status state machine: it re-verifies OS permissions.
    final status = await ref.read(healthControllerProvider.future);
    if (status != HealthLinkStatus.linked) return const HealthSyncResult(skipped: true);

    state = HealthSyncPhase.syncing;
    try {
      final thresholds = await ref.read(hrThresholdsProvider.future);
      final daysSynced = await _syncDailySummaries(userId);
      final captured = await _captureActivities(userId, thresholds);

      // Refresh the read model so open subtabs reflect the new rows.
      ref.invalidate(dailyHealthTrendProvider);
      ref.invalidate(activityHealthListProvider);
      ref.invalidate(detectedWorkoutsProvider);

      return HealthSyncResult(daysSynced: daysSynced, activitiesCaptured: captured);
    } catch (e, st) {
      _talker.handle(e, st, 'Health sync failed');
      rethrow;
    } finally {
      state = HealthSyncPhase.idle;
    }
  }

  /// Backfill daily summaries: first run = [healthBackfillDays]; thereafter
  /// today + the gap since `last_sync_at`. Idempotent upserts.
  Future<int> _syncDailySummaries(String userId) async {
    DateTime? lastSync;
    final linkRow = await _supabase
        .from('user_health_link')
        .select('last_sync_at')
        .eq('user_id', userId)
        .maybeSingle()
        .timeout(const Duration(seconds: 5));
    final raw = linkRow?['last_sync_at'];
    if (raw is String) lastSync = DateTime.tryParse(raw);

    final today = DateTime.now();
    final firstDay = lastSync != null
        ? DateTime(lastSync.year, lastSync.month, lastSync.day)
        : DateTime(today.year, today.month, today.day)
            .subtract(const Duration(days: healthBackfillDays));

    var count = 0;
    for (var day = firstDay;
        !day.isAfter(DateTime(today.year, today.month, today.day));
        day = day.add(const Duration(days: 1))) {
      final summary = await _service.readDailyHealthSummary(userId: userId, date: day);
      if (summary != null) {
        await _service.saveDailySummary(summary);
        count++;
      }
    }

    await _supabase
        .from('user_health_link')
        .update({'last_sync_at': today.toIso8601String()})
        .eq('user_id', userId)
        .timeout(const Duration(seconds: 5));
    return count;
  }

  /// Auto-capture confirmed candidates with wearable evidence. Unconfirmed ones
  /// are left for the "Detected workouts" UI (see [detectedWorkoutsProvider]).
  Future<int> _captureActivities(String userId, HrThresholds thresholds) async {
    final windowStart = DateTime.now().subtract(const Duration(days: healthBackfillDays));
    final rows = await _supabase.rpc('health_capture_candidates',
        params: {'p_window_start': windowStart.toIso8601String()}).timeout(const Duration(seconds: 5));

    var captured = 0;
    for (final r in rows as List) {
      if (r['confirmed'] != true) continue;
      final activity = Activity(
        userId: userId,
        id: r['activity_id'] as String,
        sportId: (r['sport_id'] as num).toInt(),
        startTime: DateTime.parse(r['start_time'] as String),
        endTime: DateTime.parse(r['end_time'] as String),
      );
      final result =
          await _service.readActivityHealthData(activity: activity, thresholds: thresholds);
      if (result == null || result.evidence == HealthEvidence.none) continue;
      await _service.saveActivityMetrics(result.metrics);
      await _service.saveHrCurve(activityId: activity.id!, points: result.curve);
      captured++;
    }
    return captured;
  }

  /// Attach a detected (unconfirmed) workout: read its window and persist
  /// metrics + curve. Health-only — never touches attendance / đá.
  Future<bool> attach(DetectedWorkout workout) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return false;
    final thresholds = await ref.read(hrThresholdsProvider.future);
    final activity = Activity(
      userId: userId,
      id: workout.activityId,
      sportId: workout.sportId,
      startTime: workout.startTime,
      endTime: workout.endTime,
    );
    final result =
        await _service.readActivityHealthData(activity: activity, thresholds: thresholds);
    if (result == null) return false;
    await _service.saveActivityMetrics(result.metrics);
    await _service.saveHrCurve(activityId: activity.id!, points: result.curve);
    ref.invalidate(detectedWorkoutsProvider);
    ref.invalidate(activityHealthListProvider);
    return true;
  }

  /// Dismiss a detected workout: write a tombstone so it isn't re-prompted.
  Future<void> dismiss(String activityId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    await _service.dismissActivity(userId: userId, activityId: activityId);
    ref.invalidate(detectedWorkoutsProvider);
  }
}
