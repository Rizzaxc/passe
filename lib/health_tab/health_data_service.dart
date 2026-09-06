import 'dart:io';

import 'package:health/health.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/model/activity.dart';
import 'health_controller.dart';
import 'model/activity_health_metrics.dart';
import 'model/daily_health_summary.dart';
import 'model/hr_sample.dart';

part 'health_data_service.g.dart';

/// Resolved per-user heart-rate thresholds (bpm) used to bucket the 3-zone
/// model and derive training load. `estimated` is true when the values are
/// app-derived (age bucket / observed) rather than user-declared.
class HrThresholds {
  final int maxHr;
  final int lt1; // aerobic threshold — below = easy
  final int lt2; // anaerobic threshold — above = hard
  final bool estimated;

  const HrThresholds({
    required this.maxHr,
    required this.lt1,
    required this.lt2,
    required this.estimated,
  });
}

/// How strongly the wearable suggests exercise actually happened in a window.
enum HealthEvidence { none, medium, high }

/// Outcome of reading a single activity's window from the device.
class ActivityCaptureResult {
  final ActivityHealthMetrics metrics;
  final List<HrSamplePoint> curve; // already downsampled to ~1/min
  final HealthEvidence evidence;

  const ActivityCaptureResult({
    required this.metrics,
    required this.curve,
    required this.evidence,
  });
}

/// Service for reading health data and syncing to backend.
@riverpod
class HealthDataService extends _$HealthDataService {
  final _health = Health();
  final _supabase = Supabase.instance.client;

  @override
  void build() {
    // No-op initialization
  }

  /// Read + aggregate one activity's window. Zones are computed at full sample
  /// resolution; the returned [ActivityCaptureResult.curve] is downsampled to
  /// ~1 point/min. Returns null when the activity has no end time.
  Future<ActivityCaptureResult?> readActivityHealthData({
    required Activity activity,
    required HrThresholds thresholds,
  }) async {
    if (activity.endTime == null) return null;

    final startTime = activity.startTime;
    final endTime = activity.endTime!;

    try {
      final results = await Future.wait([
        _health.getHealthDataFromTypes(
          types: [HealthDataType.STEPS],
          startTime: startTime,
          endTime: endTime,
        ),
        _health.getHealthDataFromTypes(
          types: healthDistanceDataTypes(),
          startTime: startTime,
          endTime: endTime,
        ),
        _health.getHealthDataFromTypes(
          types: [HealthDataType.ACTIVE_ENERGY_BURNED],
          startTime: startTime,
          endTime: endTime,
        ),
        _health.getHealthDataFromTypes(
          types: [HealthDataType.HEART_RATE],
          startTime: startTime,
          endTime: endTime,
        ),
        _health.getHealthDataFromTypes(
          types: [hrvDataType],
          startTime: startTime,
          endTime: endTime,
        ),
        _health.getHealthDataFromTypes(
          types: [HealthDataType.WEIGHT],
          startTime: startTime.subtract(const Duration(days: 7)),
          endTime: endTime,
        ),
        _health.getHealthDataFromTypes(
          types: [HealthDataType.WORKOUT],
          startTime: startTime,
          endTime: endTime,
        ),
      ]);

      final stepsData = results[0];
      final distanceData = results[1];
      final caloriesData = results[2];
      final heartRateData = results[3];
      final hrvData = results[4];
      final weightData = results[5];
      final workoutData = results[6];

      final steps = _sumNumericValues(stepsData);
      final distance = _sumNumericValues(distanceData);
      final calories = _sumNumericValues(caloriesData);

      final hrValues = _extractNumericValues(heartRateData);
      final avgHr = hrValues.isNotEmpty
          ? (hrValues.reduce((a, b) => a + b) / hrValues.length).round()
          : null;
      final maxHr = hrValues.isNotEmpty
          ? hrValues.reduce((a, b) => a > b ? a : b).round()
          : null;
      final minHr = hrValues.isNotEmpty
          ? hrValues.reduce((a, b) => a < b ? a : b).round()
          : null;

      // 3-zone time-in-zone (full resolution).
      final zones = _calculateHrZones(heartRateData, stepsData, thresholds);
      final easy = zones['easy']!;
      final moderate = zones['moderate']!;
      final hard = zones['hard']!;

      final hrvValues = _extractNumericValues(hrvData);
      final avgHrv = hrvValues.isNotEmpty
          ? hrvValues.reduce((a, b) => a + b) / hrvValues.length
          : null;

      final weight = weightData.isNotEmpty
          ? _extractNumericValue(weightData.last)
          : null;

      // Training load (simplified TRIMP).
      double? trainingLoad;
      if (avgHr != null) {
        final durationMinutes = endTime.difference(startTime).inMinutes;
        final hrReserve = ((avgHr - 60) / (thresholds.maxHr - 60)).clamp(
          0.0,
          1.0,
        );
        trainingLoad = durationMinutes * hrReserve * 0.64;
      }

      // Effort score 0–100 from time-in-zone distribution.
      final effortScore = _effortScore(
        easy: easy,
        moderate: moderate,
        hard: hard,
      );

      // Workout type label (from the first overlapping workout, if any).
      final workoutType = _workoutType(workoutData);

      // Evidence: an explicit workout = high; ≥10 min in moderate+hard = medium.
      final HealthEvidence evidence;
      if (workoutData.isNotEmpty) {
        evidence = HealthEvidence.high;
      } else if ((moderate + hard) >= 600) {
        evidence = HealthEvidence.medium;
      } else {
        evidence = HealthEvidence.none;
      }

      final metrics = ActivityHealthMetrics(
        userId: activity.userId,
        activityId: activity.id!,
        steps: steps?.round(),
        distanceMeters: distance,
        activeCalories: calories,
        avgHeartRate: avgHr,
        maxHeartRate: maxHr,
        minHeartRate: minHr,
        hrvSdnnMs: Platform.isIOS ? avgHrv : null,
        hrvRmssdMs: Platform.isIOS ? null : avgHrv,
        hrZoneEasySeconds: easy,
        hrZoneModerateSeconds: moderate,
        hrZoneHardSeconds: hard,
        trainingLoad: trainingLoad,
        effortScore: effortScore,
        weightKg: weight,
        workoutType: workoutType,
        recordedAt: DateTime.now(),
      );

      return ActivityCaptureResult(
        metrics: metrics,
        curve: _downsampleHrToMinutes(heartRateData),
        evidence: evidence,
      );
    } catch (e) {
      return null;
    }
  }

  /// Read a single day's whole-body summary from the device.
  Future<DailyHealthSummary?> readDailyHealthSummary({
    required String userId,
    required DateTime date,
  }) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      final results = await Future.wait([
        _health.getHealthDataFromTypes(
          types: [HealthDataType.STEPS],
          startTime: startOfDay,
          endTime: endOfDay,
        ),
        _health.getHealthDataFromTypes(
          types: healthDistanceDataTypes(),
          startTime: startOfDay,
          endTime: endOfDay,
        ),
        _health.getHealthDataFromTypes(
          types: [HealthDataType.ACTIVE_ENERGY_BURNED],
          startTime: startOfDay,
          endTime: endOfDay,
        ),
        _health.getHealthDataFromTypes(
          types: [healthAdditionalEnergyDataType()],
          startTime: startOfDay,
          endTime: endOfDay,
        ),
        _health.getHealthDataFromTypes(
          types: [HealthDataType.RESTING_HEART_RATE],
          startTime: startOfDay,
          endTime: endOfDay,
        ),
        _health.getHealthDataFromTypes(
          types: [hrvDataType],
          startTime: startOfDay,
          endTime: endOfDay,
        ),
        _health.getHealthDataFromTypes(
          types: [HealthDataType.WEIGHT],
          startTime: startOfDay,
          endTime: endOfDay,
        ),
      ]);

      final steps = _sumNumericValues(results[0])?.round();
      final distance = _sumNumericValues(results[1]);
      final activeCalories = _sumNumericValues(results[2]);
      final additionalCalories = _sumNumericValues(results[3]);
      final totalCalories = Platform.isIOS
          ? _sumNullable(activeCalories, additionalCalories)
          : additionalCalories;

      final restingHrValues = _extractNumericValues(results[4]);
      final restingHr = restingHrValues.isNotEmpty
          ? restingHrValues.reduce((a, b) => a < b ? a : b).round()
          : null;

      final hrvValues = _extractNumericValues(results[5]);
      final hrv = hrvValues.isNotEmpty
          ? hrvValues.reduce((a, b) => a + b) / hrvValues.length
          : null;

      final weightData = results[6];
      final weight = weightData.isNotEmpty
          ? _extractNumericValue(weightData.last)
          : null;

      return DailyHealthSummary(
        userId: userId,
        date: startOfDay,
        steps: steps,
        distanceMeters: distance,
        activeCalories: activeCalories,
        totalCalories: totalCalories,
        restingHeartRate: restingHr,
        hrvSdnnMs: Platform.isIOS ? hrv : null,
        hrvRmssdMs: Platform.isIOS ? null : hrv,
        weightKg: weight,
        syncedAt: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Read raw HR samples (full resolution) — used by the recap detail when the
  /// curve isn't already persisted. Most callers read the downsampled rows from
  /// `activity_hr_sample` instead.
  Future<List<HrSample>> readHrSamples({
    required String activityId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final heartRateData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: startTime,
        endTime: endTime,
      );

      return heartRateData
          .map(
            (point) => HrSample(
              activityId: activityId,
              timestamp: point.dateFrom,
              bpm: _extractNumericValue(point)?.round() ?? 0,
            ),
          )
          .where((s) => s.bpm > 0)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ── Backend writes (direct upserts; RLS scopes to auth.uid()) ──────────────

  Future<void> saveActivityMetrics(ActivityHealthMetrics metrics) async {
    // Drop nulls so the DB keeps its defaults (notably `id` / `recorded_at`)
    // instead of receiving an explicit null that overrides them.
    final json = metrics.toJson()..removeWhere((_, v) => v == null);
    await _supabase
        .from('activity_health_metrics')
        .upsert(json, onConflict: 'user_id,activity_id')
        .timeout(const Duration(seconds: 5));
  }

  /// Insert a dismissal tombstone so the detected workout isn't re-prompted.
  Future<void> dismissActivity({
    required String userId,
    required String activityId,
  }) async {
    await _supabase
        .from('activity_health_metrics')
        .upsert({
          'user_id': userId,
          'activity_id': activityId,
          'dismissed': true,
        }, onConflict: 'user_id,activity_id')
        .timeout(const Duration(seconds: 5));
  }

  Future<void> saveDailySummary(DailyHealthSummary summary) async {
    await _supabase
        .from('daily_health_summary')
        .upsert(summary.toJson(), onConflict: 'user_id,date')
        .timeout(const Duration(seconds: 5));
  }

  /// Persist a (downsampled) HR curve. Replaces any prior samples for the
  /// activity so re-capture is idempotent.
  Future<void> saveHrCurve({
    required String activityId,
    required List<HrSamplePoint> points,
  }) async {
    // Nothing new to write → leave any existing curve intact (deleting first
    // would wipe a good curve and replace it with nothing).
    if (points.isEmpty) return;
    await _supabase
        .from('activity_hr_sample')
        .delete()
        .eq('activity_id', activityId)
        .timeout(const Duration(seconds: 5));
    await _supabase
        .from('activity_hr_sample')
        .insert(
          points
              .map(
                (p) => {
                  'activity_id': activityId,
                  'timestamp': p.timestamp.toIso8601String(),
                  'bpm': p.bpm,
                },
              )
              .toList(),
        )
        .timeout(const Duration(seconds: 5));
  }

  /// Read the persisted (downsampled) HR curve for a captured activity.
  Future<List<HrSamplePoint>> loadHrCurve(String activityId) async {
    final rows = await _supabase
        .from('activity_hr_sample')
        .select('timestamp, bpm')
        .eq('activity_id', activityId)
        .order('timestamp')
        .timeout(const Duration(seconds: 5));
    return (rows as List)
        .map(
          (r) => HrSamplePoint(
            timestamp: DateTime.parse(r['timestamp'] as String),
            bpm: (r['bpm'] as num).round(),
          ),
        )
        .toList();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  double? _sumNumericValues(List<HealthDataPoint> data) {
    if (data.isEmpty) return null;
    return data.fold<double>(
      0,
      (sum, point) => sum + (_extractNumericValue(point) ?? 0),
    );
  }

  double? _sumNullable(double? a, double? b) {
    if (a == null && b == null) return null;
    return (a ?? 0) + (b ?? 0);
  }

  List<double> _extractNumericValues(List<HealthDataPoint> data) =>
      data.map(_extractNumericValue).whereType<double>().toList();

  double? _extractNumericValue(HealthDataPoint point) {
    final value = point.value;
    if (value is NumericHealthValue) return value.numericValue.toDouble();
    return null;
  }

  String? _workoutType(List<HealthDataPoint> workoutData) {
    for (final p in workoutData) {
      final v = p.value;
      if (v is WorkoutHealthValue) return v.workoutActivityType.name;
    }
    return null;
  }

  /// A continuous below-LT1 stretch with no corroborating movement this long
  /// or shorter still counts as "easy" (normal recovery between rallies/
  /// points in a stop-start sport). A *stationary* stretch beyond it is a
  /// genuine break (water/side-change/injury) and is excluded from every
  /// zone rather than counted as low effort — social sports aren't endurance
  /// sports, and long pauses shouldn't drag the effort score down the way
  /// they would for a continuous steady-state workout. See
  /// [_calculateHrZones] for why duration alone isn't enough to detect this.
  static const _pauseGraceSeconds = 90;

  /// Steps/minute below which a below-LT1 stretch is treated as stationary
  /// (a real break) rather than genuine light-intensity play. A handful of
  /// stray steps (shifting weight, fidgeting) shouldn't count as "moving".
  static const _movementStepsPerMinuteFloor = 20;

  /// Time (seconds) in each of the 3 LT zones, summed at full sample resolution.
  /// easy = HR < LT1, moderate = LT1..LT2, hard = > LT2.
  ///
  /// A sustained below-LT1 stretch isn't necessarily a break — it might be an
  /// incredibly fit player, or a genuinely light session, where HR just never
  /// climbs. Duration alone can't tell "still playing, low effort" apart from
  /// "sitting on the bench", so each below-LT1 run is cross-checked against
  /// step data from the same window: if there's corroborating movement, the
  /// whole run counts as easy; if the player is stationary, only the first
  /// [_pauseGraceSeconds] count and the rest is excluded as a pause.
  Map<String, int> _calculateHrZones(
    List<HealthDataPoint> hrData,
    List<HealthDataPoint> stepsData,
    HrThresholds t,
  ) {
    final zones = {'easy': 0, 'moderate': 0, 'hard': 0};
    var i = 0;
    while (i < hrData.length) {
      final value = _extractNumericValue(hrData[i]);
      if (value == null) {
        i++;
        continue;
      }
      final duration = _sampleDurationSeconds(hrData, i);

      if (value >= t.lt1) {
        final key = value > t.lt2 ? 'hard' : 'moderate';
        zones[key] = zones[key]! + duration;
        i++;
        continue;
      }

      // Extend the run while HR stays below LT1.
      final runStart = hrData[i].dateFrom;
      var runDuration = duration;
      var j = i + 1;
      while (j < hrData.length) {
        final v = _extractNumericValue(hrData[j]);
        if (v == null || v >= t.lt1) break;
        runDuration += _sampleDurationSeconds(hrData, j);
        j++;
      }
      final runEnd = j < hrData.length
          ? hrData[j].dateFrom
          : runStart.add(Duration(seconds: runDuration));

      final moving = _hasMovement(stepsData, runStart, runEnd);
      zones['easy'] =
          zones['easy']! +
          (moving ? runDuration : runDuration.clamp(0, _pauseGraceSeconds));
      i = j;
    }
    return zones;
  }

  int _sampleDurationSeconds(List<HealthDataPoint> hrData, int i) {
    if (i >= hrData.length - 1) return 1;
    return hrData[i + 1].dateFrom
        .difference(hrData[i].dateFrom)
        .inSeconds
        .clamp(1, 60);
  }

  /// Whether step data shows meaningful movement overlapping [start, end).
  bool _hasMovement(
    List<HealthDataPoint> stepsData,
    DateTime start,
    DateTime end,
  ) {
    final minutes = end.difference(start).inSeconds / 60.0;
    if (minutes <= 0) return false;
    final steps = stepsData
        .where((p) => p.dateFrom.isBefore(end) && p.dateTo.isAfter(start))
        .fold<double>(0, (sum, p) => sum + (_extractNumericValue(p) ?? 0));
    return steps / minutes >= _movementStepsPerMinuteFloor;
  }

  /// 0–100 from the intensity-weighted time distribution (easy=1/mod=2/hard=3)
  /// over pause-excluded zone time (see [_calculateHrZones]), so extended
  /// breaks don't count as low-effort minutes.
  double? _effortScore({
    required int easy,
    required int moderate,
    required int hard,
  }) {
    final total = easy + moderate + hard;
    if (total == 0) return null;
    final weighted = (easy * 1 + moderate * 2 + hard * 3) / total; // 1..3
    return ((weighted - 1) / 2 * 100).clamp(0, 100);
  }

  /// Reduce raw HR samples to ~1 point/minute (mean per minute bucket).
  List<HrSamplePoint> _downsampleHrToMinutes(List<HealthDataPoint> hrData) {
    final buckets = <int, List<double>>{};
    final bucketStart = <int, DateTime>{};
    for (final p in hrData) {
      final value = _extractNumericValue(p);
      if (value == null) continue;
      final minute = p.dateFrom.millisecondsSinceEpoch ~/ 60000;
      (buckets[minute] ??= []).add(value);
      bucketStart.putIfAbsent(minute, () => p.dateFrom);
    }
    final keys = buckets.keys.toList()..sort();
    return keys.map((m) {
      final vals = buckets[m]!;
      final mean = vals.reduce((a, b) => a + b) / vals.length;
      return HrSamplePoint(timestamp: bucketStart[m]!, bpm: mean.round());
    }).toList();
  }
}
