import 'package:health/health.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/model/activity.dart';
import 'model/activity_health_metrics.dart';
import 'model/daily_health_summary.dart';
import 'model/hr_sample.dart';

part 'health_data_service.g.dart';

/// Service for reading health data and syncing to backend
@riverpod
class HealthDataService extends _$HealthDataService {
  final _health = Health();
  final _supabase = Supabase.instance.client;

  @override
  void build() {
    // No-op initialization
  }

  /// Read health data for a specific activity time range
  Future<ActivityHealthMetrics?> readActivityHealthData({
    required Activity activity,
    int? userMaxHeartRate,
  }) async {
    if (activity.endTime == null) return null;

    final startTime = activity.startTime;
    final endTime = activity.endTime!;

    try {
      // Fetch all health data types in parallel
      final results = await Future.wait([
        _health.getHealthDataFromTypes(
          types: [HealthDataType.STEPS],
          startTime: startTime,
          endTime: endTime,
        ),
        _health.getHealthDataFromTypes(
          types: [HealthDataType.DISTANCE_DELTA],
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
          types: [HealthDataType.HEART_RATE_VARIABILITY_SDNN],
          startTime: startTime,
          endTime: endTime,
        ),
        _health.getHealthDataFromTypes(
          types: [HealthDataType.WEIGHT],
          startTime: startTime.subtract(const Duration(days: 7)),
          endTime: endTime,
        ),
      ]);

      final stepsData = results[0];
      final distanceData = results[1];
      final caloriesData = results[2];
      final heartRateData = results[3];
      final hrvData = results[4];
      final weightData = results[5];

      // Aggregate steps
      final steps = _sumNumericValues(stepsData);

      // Aggregate distance
      final distance = _sumNumericValues(distanceData);

      // Aggregate calories
      final calories = _sumNumericValues(caloriesData);

      // Process heart rate data
      final hrValues = _extractNumericValues(heartRateData);
      final avgHr = hrValues.isNotEmpty
          ? (hrValues.reduce((a, b) => a + b) / hrValues.length).round()
          : null;
      final maxHr = hrValues.isNotEmpty ? hrValues.reduce((a, b) => a > b ? a : b).round() : null;
      final minHr = hrValues.isNotEmpty ? hrValues.reduce((a, b) => a < b ? a : b).round() : null;

      // Calculate HR zones if we have max HR
      Map<int, int>? hrZones;
      if (userMaxHeartRate != null && heartRateData.isNotEmpty) {
        hrZones = _calculateHrZones(heartRateData, userMaxHeartRate);
      }

      // Get HRV average
      final hrvValues = _extractNumericValues(hrvData);
      final avgHrv = hrvValues.isNotEmpty
          ? hrvValues.reduce((a, b) => a + b) / hrvValues.length
          : null;

      // Get most recent weight
      final weight = weightData.isNotEmpty
          ? _extractNumericValue(weightData.last)
          : null;

      // Calculate training load (simplified TRIMP)
      double? trainingLoad;
      if (avgHr != null && userMaxHeartRate != null) {
        final durationMinutes = endTime.difference(startTime).inMinutes;
        final hrReserve = (avgHr - 60) / (userMaxHeartRate - 60);
        trainingLoad = durationMinutes * hrReserve * 0.64; // Simplified TRIMP formula
      }

      return ActivityHealthMetrics(
        userId: activity.userId,
        activityId: activity.id!,
        steps: steps?.round(),
        distanceMeters: distance,
        activeCalories: calories,
        avgHeartRate: avgHr,
        maxHeartRate: maxHr,
        minHeartRate: minHr,
        hrvSdnnMs: avgHrv,
        hrZone1Seconds: hrZones?[1],
        hrZone2Seconds: hrZones?[2],
        hrZone3Seconds: hrZones?[3],
        hrZone4Seconds: hrZones?[4],
        hrZone5Seconds: hrZones?[5],
        trainingLoad: trainingLoad,
        weightKg: weight,
        recordedAt: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Extract raw HR samples for detailed analysis
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

      return heartRateData.map((point) {
        final value = _extractNumericValue(point);
        return HrSample(
          activityId: activityId,
          timestamp: point.dateFrom,
          bpm: value?.round() ?? 0,
        );
      }).where((s) => s.bpm > 0).toList();
    } catch (e) {
      return [];
    }
  }

  /// Read daily health summary
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
          types: [HealthDataType.DISTANCE_DELTA],
          startTime: startOfDay,
          endTime: endOfDay,
        ),
        _health.getHealthDataFromTypes(
          types: [HealthDataType.ACTIVE_ENERGY_BURNED],
          startTime: startOfDay,
          endTime: endOfDay,
        ),
        _health.getHealthDataFromTypes(
          types: [HealthDataType.TOTAL_CALORIES_BURNED],
          startTime: startOfDay,
          endTime: endOfDay,
        ),
        _health.getHealthDataFromTypes(
          types: [HealthDataType.RESTING_HEART_RATE],
          startTime: startOfDay,
          endTime: endOfDay,
        ),
        _health.getHealthDataFromTypes(
          types: [HealthDataType.HEART_RATE_VARIABILITY_SDNN],
          startTime: startOfDay,
          endTime: endOfDay,
        ),
        _health.getHealthDataFromTypes(
          types: [HealthDataType.SLEEP_ASLEEP],
          startTime: startOfDay.subtract(const Duration(hours: 12)),
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
      final totalCalories = _sumNumericValues(results[3]);

      final restingHrValues = _extractNumericValues(results[4]);
      final restingHr = restingHrValues.isNotEmpty
          ? restingHrValues.reduce((a, b) => a < b ? a : b).round()
          : null;

      final hrvValues = _extractNumericValues(results[5]);
      final hrv = hrvValues.isNotEmpty
          ? hrvValues.reduce((a, b) => a + b) / hrvValues.length
          : null;

      final sleepMinutes = _sumNumericValues(results[6])?.round();

      final weightData = results[7];
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
        hrvSdnnMs: hrv,
        sleepMinutes: sleepMinutes,
        weightKg: weight,
        syncedAt: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Save activity health metrics to backend
  Future<void> saveActivityMetrics(ActivityHealthMetrics metrics) async {
    await _supabase.from('activity_health_metrics').upsert(
      metrics.toJson(),
      onConflict: 'user_id,activity_id',
    );
  }

  /// Save HR samples in batch
  Future<void> saveHrSamples(List<HrSample> samples) async {
    if (samples.isEmpty) return;

    // Batch insert in chunks of 500
    const chunkSize = 500;
    for (var i = 0; i < samples.length; i += chunkSize) {
      final chunk = samples.skip(i).take(chunkSize).toList();
      await _supabase.from('activity_hr_sample').insert(
        chunk.map((s) => {
          'activity_id': s.activityId,
          'timestamp': s.timestamp.toIso8601String(),
          'bpm': s.bpm,
        }).toList(),
      );
    }
  }

  /// Save daily health summary to backend
  Future<void> saveDailySummary(DailyHealthSummary summary) async {
    await _supabase.from('daily_health_summary').upsert(
      summary.toJson(),
      onConflict: 'user_id,date',
    );
  }

  // Helper methods

  double? _sumNumericValues(List<HealthDataPoint> data) {
    if (data.isEmpty) return null;
    return data.fold<double>(0, (sum, point) {
      final value = _extractNumericValue(point);
      return sum + (value ?? 0);
    });
  }

  List<double> _extractNumericValues(List<HealthDataPoint> data) {
    return data
        .map(_extractNumericValue)
        .whereType<double>()
        .toList();
  }

  double? _extractNumericValue(HealthDataPoint point) {
    final value = point.value;
    if (value is NumericHealthValue) {
      return value.numericValue.toDouble();
    }
    return null;
  }

  /// Calculate time spent in each HR zone (in seconds)
  /// Zones: Z1(50-60%), Z2(60-70%), Z3(70-80%), Z4(80-90%), Z5(90-100%)
  Map<int, int> _calculateHrZones(List<HealthDataPoint> hrData, int maxHr) {
    final zones = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    for (var i = 0; i < hrData.length; i++) {
      final value = _extractNumericValue(hrData[i]);
      if (value == null) continue;

      final hrPercent = value / maxHr * 100;
      final zone = hrPercent >= 90 ? 5
          : hrPercent >= 80 ? 4
          : hrPercent >= 70 ? 3
          : hrPercent >= 60 ? 2
          : 1;

      // Estimate time between samples (default to 1 second)
      int duration = 1;
      if (i < hrData.length - 1) {
        duration = hrData[i + 1].dateFrom.difference(hrData[i].dateFrom).inSeconds;
        duration = duration.clamp(1, 60); // Cap at 60 seconds to handle gaps
      }

      zones[zone] = zones[zone]! + duration;
    }

    return zones;
  }
}
