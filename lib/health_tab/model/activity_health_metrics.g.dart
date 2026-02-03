// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_health_metrics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ActivityHealthMetrics _$ActivityHealthMetricsFromJson(Map json) =>
    _ActivityHealthMetrics(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      activityId: json['activity_id'] as String,
      steps: (json['steps'] as num?)?.toInt(),
      distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
      activeCalories: (json['active_calories'] as num?)?.toDouble(),
      avgHeartRate: (json['avg_heart_rate'] as num?)?.toInt(),
      maxHeartRate: (json['max_heart_rate'] as num?)?.toInt(),
      minHeartRate: (json['min_heart_rate'] as num?)?.toInt(),
      hrvSdnnMs: (json['hrv_sdnn_ms'] as num?)?.toDouble(),
      hrvRmssdMs: (json['hrv_rmssd_ms'] as num?)?.toDouble(),
      hrZone1Seconds: (json['hr_zone_1_seconds'] as num?)?.toInt(),
      hrZone2Seconds: (json['hr_zone_2_seconds'] as num?)?.toInt(),
      hrZone3Seconds: (json['hr_zone_3_seconds'] as num?)?.toInt(),
      hrZone4Seconds: (json['hr_zone_4_seconds'] as num?)?.toInt(),
      hrZone5Seconds: (json['hr_zone_5_seconds'] as num?)?.toInt(),
      trainingLoad: (json['training_load'] as num?)?.toDouble(),
      effortScore: (json['effort_score'] as num?)?.toDouble(),
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      workoutType: json['workout_type'] as String?,
      recordedAt: json['recorded_at'] == null
          ? null
          : DateTime.parse(json['recorded_at'] as String),
    );

Map<String, dynamic> _$ActivityHealthMetricsToJson(
  _ActivityHealthMetrics instance,
) => <String, dynamic>{
  'id': ?instance.id,
  'user_id': instance.userId,
  'activity_id': instance.activityId,
  'steps': ?instance.steps,
  'distance_meters': ?instance.distanceMeters,
  'active_calories': ?instance.activeCalories,
  'avg_heart_rate': ?instance.avgHeartRate,
  'max_heart_rate': ?instance.maxHeartRate,
  'min_heart_rate': ?instance.minHeartRate,
  'hrv_sdnn_ms': ?instance.hrvSdnnMs,
  'hrv_rmssd_ms': ?instance.hrvRmssdMs,
  'hr_zone_1_seconds': ?instance.hrZone1Seconds,
  'hr_zone_2_seconds': ?instance.hrZone2Seconds,
  'hr_zone_3_seconds': ?instance.hrZone3Seconds,
  'hr_zone_4_seconds': ?instance.hrZone4Seconds,
  'hr_zone_5_seconds': ?instance.hrZone5Seconds,
  'training_load': ?instance.trainingLoad,
  'effort_score': ?instance.effortScore,
  'weight_kg': ?instance.weightKg,
  'workout_type': ?instance.workoutType,
  'recorded_at': ?instance.recordedAt?.toIso8601String(),
};
