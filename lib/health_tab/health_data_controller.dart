import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_controller.dart';
import '../core/model/activity.dart';
import '../core/model/enum.dart';
import '../core/state/selected_sport_state.dart';
import 'health_data_service.dart';
import 'model/activity_health_row.dart';
import 'model/daily_health_summary.dart';
import 'model/user_health_link.dart';

part 'health_data_controller.g.dart';

/// Backfill window shared by the trend read and the capture passes.
const healthBackfillDays = 90;

/// A detected-but-unattached workout surfaced in the "Detected workouts"
/// section. Carries the candidate's window so [HealthSyncController.attach]
/// can re-read and persist it.
class DetectedWorkout {
  final String activityId;
  final DateTime startTime;
  final DateTime endTime;
  final int sportId;
  final String source;
  final HealthEvidence evidence;

  const DetectedWorkout({
    required this.activityId,
    required this.startTime,
    required this.endTime,
    required this.sportId,
    required this.source,
    required this.evidence,
  });
}

int _ageMidpoint(AgeGroup? group) => switch (group) {
  AgeGroup.student => 20,
  AgeGroup.mature => 30,
  AgeGroup.middleAge => 45,
  null => 30,
};

/// Resolves the caller's HR thresholds: user-declared values from
/// `user_health_link`, else estimated from an age-bucket max HR. `estimated`
/// stays true until the user declares both LT thresholds.
@riverpod
Future<HrThresholds> hrThresholds(Ref ref) async {
  final supabase = Supabase.instance.client;
  final userId = ref.watch(currentUserIdProvider);
  final ageGroup = ref.watch(authControllerProvider).value?.details?.ageGroup;

  int? maxHr, lt1, lt2;
  if (userId != null) {
    final row = await supabase
        .from('user_health_link')
        .select('max_heart_rate, lt1_bpm, lt2_bpm')
        .eq('user_id', userId)
        .maybeSingle()
        .timeout(const Duration(seconds: 5));
    if (row != null) {
      final link = UserHealthLink.fromJson({
        ...row,
        'user_id': userId,
        'platform': 'apple_health',
        'linked_at': DateTime.now().toIso8601String(),
      });
      maxHr = link.maxHeartRate;
      lt1 = link.lt1Bpm;
      lt2 = link.lt2Bpm;
    }
  }

  final resolvedMax = maxHr ?? (220 - _ageMidpoint(ageGroup));
  return HrThresholds(
    maxHr: resolvedMax,
    lt1: lt1 ?? (resolvedMax * 0.80).round(),
    lt2: lt2 ?? (resolvedMax * 0.88).round(),
    estimated: lt1 == null || lt2 == null,
  );
}

/// Saves the user's declared HR-zone thresholds to `user_health_link`.
/// Pass `maxHeartRate: null` to fall back to the age-bucket estimate.
@riverpod
class HrThresholdController extends _$HrThresholdController {
  @override
  bool build() => false; // saving

  Future<void> save({
    required int lt1Bpm,
    required int lt2Bpm,
    int? maxHeartRate,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    state = true;
    try {
      await Supabase.instance.client
          .from('user_health_link')
          .update({
            'lt1_bpm': lt1Bpm,
            'lt2_bpm': lt2Bpm,
            'max_heart_rate': maxHeartRate,
          })
          .eq('user_id', userId)
          .timeout(const Duration(seconds: 5));
      ref.invalidate(hrThresholdsProvider);
    } finally {
      state = false;
    }
  }
}

/// Whole-body daily summaries for the last [healthBackfillDays] (direct select).
/// Sport-agnostic. Newest first.
@riverpod
Future<List<DailyHealthSummary>> dailyHealthTrend(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final since = DateTime.now()
      .subtract(const Duration(days: healthBackfillDays))
      .toIso8601String()
      .split('T')
      .first;

  final rows = await Supabase.instance.client
      .from('daily_health_summary')
      .select()
      .eq('user_id', userId)
      .gte('date', since)
      .order('date', ascending: false)
      .timeout(const Duration(seconds: 5));

  return (rows as List)
      .map((r) => DailyHealthSummary.fromJson(r as Map<String, dynamic>))
      .toList();
}

/// Captured activity recaps for the context sport (RPC). Returns `[]` when no
/// sport is selected.
@riverpod
Future<List<ActivityHealthRow>> activityHealthList(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  final sport = ref.watch(selectedSportStateProvider).value;
  if (userId == null || sport == null || sport == Sport.others) return [];

  final rows = await Supabase.instance.client
      .rpc('activity_health_data', params: {'p_sport_id': sport.index})
      .timeout(const Duration(seconds: 5));

  return (rows as List)
      .map((r) => ActivityHealthRow.fromJson(r as Map<String, dynamic>))
      .toList();
}

/// Candidate activities the user never confirmed but for which the wearable
/// shows exercise evidence — the reconciliation inbox. Re-checks the device per
/// candidate (the RPC only narrows the set; the device holds the samples).
@riverpod
Future<List<DetectedWorkout>> detectedWorkouts(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final thresholds = await ref.watch(hrThresholdsProvider.future);
  final service = ref.watch(healthDataServiceProvider.notifier);

  final windowStart = DateTime.now().subtract(
    const Duration(days: healthBackfillDays),
  );
  final rows = await Supabase.instance.client
      .rpc(
        'health_capture_candidates',
        params: {'p_window_start': windowStart.toIso8601String()},
      )
      .timeout(const Duration(seconds: 5));

  final detected = <DetectedWorkout>[];
  for (final r in rows as List) {
    if (r['confirmed'] == true)
      continue; // confirmed ones are auto-captured by sync
    final activity = Activity(
      userId: userId,
      id: r['activity_id'] as String,
      sportId: (r['sport_id'] as num).toInt(),
      startTime: DateTime.parse(r['start_time'] as String),
      endTime: DateTime.parse(r['end_time'] as String),
    );
    final result = await service.readActivityHealthData(
      activity: activity,
      thresholds: thresholds,
    );
    if (result == null || result.evidence == HealthEvidence.none) continue;
    detected.add(
      DetectedWorkout(
        activityId: activity.id!,
        startTime: activity.startTime,
        endTime: activity.endTime!,
        sportId: activity.sportId,
        source: r['source'] as String,
        evidence: result.evidence,
      ),
    );
  }
  return detected;
}
