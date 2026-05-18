import 'package:freezed_annotation/freezed_annotation.dart';

part 'activity_health_metrics.freezed.dart';
part 'activity_health_metrics.g.dart';

@freezed
abstract class ActivityHealthMetrics with _$ActivityHealthMetrics {
  const factory ActivityHealthMetrics({
    String? id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'activity_id') required String activityId,

    // Activity metrics
    int? steps,
    @JsonKey(name: 'distance_meters') double? distanceMeters,
    @JsonKey(name: 'active_calories') double? activeCalories,

    // Heart rate aggregates
    @JsonKey(name: 'avg_heart_rate') int? avgHeartRate,
    @JsonKey(name: 'max_heart_rate') int? maxHeartRate,
    @JsonKey(name: 'min_heart_rate') int? minHeartRate,

    // HRV metrics
    @JsonKey(name: 'hrv_sdnn_ms') double? hrvSdnnMs,
    @JsonKey(name: 'hrv_rmssd_ms') double? hrvRmssdMs,

    // HR Zone distribution (seconds)
    @JsonKey(name: 'hr_zone_1_seconds') int? hrZone1Seconds,
    @JsonKey(name: 'hr_zone_2_seconds') int? hrZone2Seconds,
    @JsonKey(name: 'hr_zone_3_seconds') int? hrZone3Seconds,
    @JsonKey(name: 'hr_zone_4_seconds') int? hrZone4Seconds,
    @JsonKey(name: 'hr_zone_5_seconds') int? hrZone5Seconds,

    // Derived performance metrics
    @JsonKey(name: 'training_load') double? trainingLoad,
    @JsonKey(name: 'effort_score') double? effortScore,

    // Weight snapshot
    @JsonKey(name: 'weight_kg') double? weightKg,

    // Workout type from health platform
    @JsonKey(name: 'workout_type') String? workoutType,

    @JsonKey(name: 'recorded_at') DateTime? recordedAt,
  }) = _ActivityHealthMetrics;

  factory ActivityHealthMetrics.fromJson(Map<String, dynamic> json) =>
      _$ActivityHealthMetricsFromJson(json);
}
