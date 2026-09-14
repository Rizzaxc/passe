import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_controller.dart';
import '../core/achievement_evaluator.dart';
import '../core/model/activity.dart';
import '../logger/talker.dart';
import 'achievements_section/model/achievement_celebration.dart';
import 'health_controller.dart';
import 'health_data_controller.dart';
import 'health_data_service.dart';
import 'health_settings_controller.dart';
import 'vitality_score_controller.dart';

part 'health_sync_service.g.dart';

enum HealthSyncPhase { idle, syncing }

/// Result of a [HealthSyncController.syncNow] pass, for the completion toast.
class HealthSyncResult {
  final int daysSynced;
  final int activitiesCaptured;
  final bool skipped; // true when not linked / no permission / guest
  final int achievementsUnlocked;
  final bool leveledUp;

  const HealthSyncResult({
    this.daysSynced = 0,
    this.activitiesCaptured = 0,
    this.skipped = false,
    this.achievementsUnlocked = 0,
    this.leveledUp = false,
  });
}

/// The device → Supabase sync engine. Fired once on app launch (non-blocking)
/// and on the explicit Sync button. Pull-to-refresh does NOT call this — it only
/// re-reads Supabase via the data providers.
@riverpod
class HealthSyncController extends _$HealthSyncController {
  final _supabase = Supabase.instance.client;

  @override
  HealthSyncPhase build() => HealthSyncPhase.idle;

  HealthDataService get _service =>
      ref.read(healthDataServiceProvider.notifier);

  /// Pull the device's data into Supabase. Self-guards guests / unlinked /
  /// revoked permissions, so it is safe to fire unconditionally at launch.
  Future<HealthSyncResult> syncNow() async {
    if (state == HealthSyncPhase.syncing) return const HealthSyncResult();

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return const HealthSyncResult(skipped: true);

    final status = await ref.read(healthControllerProvider.future);
    if (!ref.mounted) return const HealthSyncResult(skipped: true);
    if (status != HealthLinkStatus.linked) {
      return const HealthSyncResult(skipped: true);
    }

    state = HealthSyncPhase.syncing;
    try {
      final thresholds = await ref.read(hrThresholdsProvider.future);
      if (!ref.mounted) return const HealthSyncResult(skipped: true);

      final daysSynced = await _syncDailySummaries(userId);
      if (!ref.mounted) return HealthSyncResult(daysSynced: daysSynced);

      final captured = await _captureActivities(userId, thresholds);
      if (!ref.mounted) {
        return HealthSyncResult(
          daysSynced: daysSynced,
          activitiesCaptured: captured,
        );
      }

      await _createStandaloneActivities(userId);
      if (!ref.mounted) {
        return HealthSyncResult(
          daysSynced: daysSynced,
          activitiesCaptured: captured,
        );
      }

      final celebration = await _evaluateAchievements(userId);
      if (!ref.mounted) {
        return HealthSyncResult(
          daysSynced: daysSynced,
          activitiesCaptured: captured,
          achievementsUnlocked: celebration?.unlocked.length ?? 0,
          leveledUp: celebration?.leveledUp ?? false,
        );
      }

      await _evaluateVitalityScore(userId);
      if (!ref.mounted) {
        return HealthSyncResult(
          daysSynced: daysSynced,
          activitiesCaptured: captured,
          achievementsUnlocked: celebration?.unlocked.length ?? 0,
          leveledUp: celebration?.leveledUp ?? false,
        );
      }

      ref.invalidate(dailyHealthTrendProvider);
      ref.invalidate(activityHealthListProvider);
      ref.invalidate(activityHealthSportCountsProvider);
      ref.invalidate(detectedWorkoutsProvider);
      ref.invalidate(vitalityScoreSummaryProvider);

      return HealthSyncResult(
        daysSynced: daysSynced,
        activitiesCaptured: captured,
        achievementsUnlocked: celebration?.unlocked.length ?? 0,
        leveledUp: celebration?.leveledUp ?? false,
      );
    } catch (e, st) {
      talker.handle(e, st, 'Health sync failed');
      rethrow;
    } finally {
      if (ref.mounted) state = HealthSyncPhase.idle;
    }
  }

  /// Backfill daily summaries: first run = [healthBackfillDays]; thereafter
  /// today + the gap since `last_sync_at`. Idempotent upserts. Stops at the
  /// first day that fails to read (rather than throwing) so a single slow
  /// or denied day doesn't abort the rest of `syncNow()` — notably activity
  /// capture, a separate pass that must still run.
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
        : DateTime(
            today.year,
            today.month,
            today.day,
          ).subtract(const Duration(days: healthBackfillDays));

    var count = 0;
    // The last day we actually persisted — advancing last_sync_at only this
    // far (not to `today`) means a day that failed to read gets retried on
    // the next sync instead of being silently skipped forever. A failure
    // stops the backfill rather than aborting the whole sync: activity
    // capture (a separate concern) must still run even if one day's summary
    // couldn't be read.
    DateTime? lastSyncedDay = lastSync;
    for (
      var day = firstDay;
      !day.isAfter(DateTime(today.year, today.month, today.day));
      day = day.add(const Duration(days: 1))
    ) {
      if (!ref.mounted) return count;
      final summary = await _service.readDailyHealthSummary(
        userId: userId,
        date: day,
      );
      if (summary == null) break;
      // A save failure (e.g. a value a DB CHECK constraint rejects) stops
      // the backfill exactly like a read failure — retry this day next
      // time rather than letting it abort the whole sync.
      try {
        await _service.saveDailySummary(summary);
      } catch (e, st) {
        talker.handle(e, st, 'Failed to save daily summary for $day');
        break;
      }
      count++;
      lastSyncedDay = day;
    }

    if (!ref.mounted) return count;
    if (lastSyncedDay != null) {
      await _supabase
          .from('user_health_link')
          .update({'last_sync_at': lastSyncedDay.toUtc().toIso8601String()})
          .eq('user_id', userId)
          .timeout(const Duration(seconds: 5));
    }
    return count;
  }

  /// Auto-capture every confirmed candidate the device can be queried for. A
  /// committed activity always gets a best-effort report, however sparse —
  /// `HealthEvidence` is not consulted here; it only gates whether an
  /// *unconfirmed* candidate is worth surfacing at all (see
  /// [detectedWorkoutsProvider]), since there the user never RSVP'd and we
  /// have nothing else to anchor "did something happen" on. A confirmed
  /// activity already answers that question — we just report what the
  /// device saw for its window. `result == null` still means the device
  /// reads themselves failed (or the activity has no end time yet), which is
  /// the only case worth skipping and retrying on a later sync.
  Future<int> _captureActivities(String userId, HrThresholds thresholds) async {
    final windowStart = DateTime.now().subtract(
      const Duration(days: healthBackfillDays),
    );
    final rows = await _supabase
        .rpc(
          'health_capture_candidates',
          params: {'p_window_start': windowStart.toUtc().toIso8601String()},
        )
        .timeout(const Duration(seconds: 5));

    var captured = 0;
    for (final r in rows as List) {
      if (r['confirmed'] != true) continue;
      if (!ref.mounted) return captured;
      final activityId = r['activity_id'] as String;
      // One bad candidate (a malformed row, a DB constraint rejecting a
      // write) must not abort the rest of the batch — or the sync as a
      // whole, since this loop runs after the daily-summary pass.
      try {
        final activity = Activity(
          userId: userId,
          id: activityId,
          sportId: (r['sport_id'] as num).toInt(),
          startTime: DateTime.parse(r['start_time'] as String),
          endTime: DateTime.parse(r['end_time'] as String),
        );
        final result = await _service.readActivityHealthData(
          activity: activity,
          thresholds: thresholds,
        );
        if (result == null) continue;
        await _service.saveActivityMetrics(result.metrics);
        await _service.saveHrCurve(
          activityId: activity.id!,
          points: result.curve,
        );
        captured++;
      } catch (e, st) {
        talker.handle(e, st, 'Failed to capture activity $activityId');
      }
    }
    return captured;
  }

  /// Create bare "personal" activity rows (`lobby_id`/`freeplay_host_id`/
  /// `course_id` all NULL — schema-legal: `activity_source_exclusivity` is
  /// `<= 1`, not `= 1`) for standalone device workouts of the 5 supported
  /// sports that have no existing Passe activity overlapping their window.
  /// Deliberately does **not** capture metrics itself:
  /// `health_capture_candidates`'s `confirmed` flag is computed purely from
  /// `activity_confirmation`/`freeplay_request` rows, so a bare self-activity
  /// always comes back unconfirmed and flows into the existing "Detected
  /// workouts" review inbox unchanged — the same reconciliation flow an
  /// unconfirmed lobby session already goes through, reused as-is.
  /// `attach()`/`dismiss()` need no changes: once this row exists it behaves
  /// exactly like any other unconfirmed candidate.
  ///
  /// Gated by [standaloneWorkoutSyncSettingProvider] (default on) — off
  /// skips the device scan entirely, not just the writes. Own try/catch,
  /// mirroring [_evaluateVitalityScore]: a failure here must never block
  /// achievement/vitality evaluation right after it.
  Future<void> _createStandaloneActivities(String userId) async {
    try {
      final enabled = await ref.read(
        standaloneWorkoutSyncSettingProvider.future,
      );
      if (!ref.mounted || !enabled) return;

      final windowStart = DateTime.now().subtract(
        const Duration(days: healthBackfillDays),
      );
      final sessions = await _service.readWorkoutSessions(
        windowStart: windowStart,
      );
      if (sessions.isEmpty || !ref.mounted) return;

      // Every activity in the window regardless of source/confirmation —
      // used only to skip a span that's already represented, including a
      // bare activity this same method created on a previous sync (this is
      // what makes repeated syncs idempotent with no separate dedup table).
      final existingRows = await _supabase
          .from('activity')
          .select('start_time, end_time')
          .eq('user_id', userId)
          .gte('start_time', windowStart.toUtc().toIso8601String())
          .timeout(const Duration(seconds: 5));
      final existing = (existingRows as List)
          .map(
            (r) => (
              start: DateTime.parse(r['start_time'] as String),
              end: r['end_time'] != null
                  ? DateTime.parse(r['end_time'] as String)
                  : null,
            ),
          )
          .toList();

      for (final session in sessions) {
        if (!ref.mounted) return;
        final overlaps = existing.any(
          (a) =>
              a.start.isBefore(session.endTime) &&
              (a.end == null || a.end!.isAfter(session.startTime)),
        );
        if (overlaps) continue;

        // One bad insert must not abort the rest of the batch.
        try {
          await _supabase
              .from('activity')
              .insert({
                'user_id': userId,
                'sport_id': session.sport.index,
                'start_time': session.startTime.toUtc().toIso8601String(),
                'end_time': session.endTime.toUtc().toIso8601String(),
              })
              .timeout(const Duration(seconds: 5));
        } catch (e, st) {
          talker.handle(e, st, 'Failed to create standalone activity');
        }
      }
    } catch (e, st) {
      talker.handle(e, st, 'Standalone workout detection failed');
    }
  }

  /// Re-run the achievement evaluator after fresh data lands. Persists unlocks
  /// + banks XP server-side; the shared [evaluateAchievements] helper stashes
  /// the celebration payload (consumed by the achievements subtab) and lights
  /// the unseen dot.
  Future<AchievementCelebration?> _evaluateAchievements(String userId) =>
      evaluateAchievements(ref, userId);

  /// Re-run the vitality-score evaluator after fresh data lands. Own
  /// try/catch, mirroring [_evaluateAchievements] — a failure here must never
  /// block achievement unlocks or the sync toast.
  Future<void> _evaluateVitalityScore(String userId) async {
    try {
      await _supabase
          .rpc('evaluate_vitality_score', params: {'p_user_id': userId})
          .timeout(const Duration(seconds: 5));
    } catch (e, st) {
      talker.handle(e, st, 'Vitality score evaluation failed');
    }
  }

  /// Attach a detected (unconfirmed) workout: read its window and persist
  /// metrics + curve. Health-only — never touches attendance / đá.
  Future<bool> attach(DetectedWorkout workout) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return false;
    final thresholds = await ref.read(hrThresholdsProvider.future);
    if (!ref.mounted) return false;
    final activity = Activity(
      userId: userId,
      id: workout.activityId,
      sportId: workout.sportId,
      startTime: workout.startTime,
      endTime: workout.endTime,
    );
    final result = await _service.readActivityHealthData(
      activity: activity,
      thresholds: thresholds,
    );
    if (result == null) return false;
    await _service.saveActivityMetrics(result.metrics);
    await _service.saveHrCurve(activityId: activity.id!, points: result.curve);
    if (!ref.mounted) return true;
    ref.invalidate(detectedWorkoutsProvider);
    ref.invalidate(activityHealthListProvider);
    ref.invalidate(activityHealthSportCountsProvider);
    return true;
  }

  /// Dismiss a detected workout: write a tombstone so it isn't re-prompted.
  Future<void> dismiss(String activityId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    await _service.dismissActivity(userId: userId, activityId: activityId);
    if (!ref.mounted) return;
    ref.invalidate(detectedWorkoutsProvider);
  }
}
