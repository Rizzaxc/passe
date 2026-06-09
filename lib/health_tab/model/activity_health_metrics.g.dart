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
      hrZoneEasySeconds: (json['hr_zone_easy_seconds'] as num?)?.toInt(),
      hrZoneModerateSeconds: (json['hr_zone_moderate_seconds'] as num?)
          ?.toInt(),
      hrZoneHardSeconds: (json['hr_zone_hard_seconds'] as num?)?.toInt(),
      trainingLoad: (json['training_load'] as num?)?.toDouble(),
      effortScore: (json['effort_score'] as num?)?.toDouble(),
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      workoutType: json['workout_type'] as String?,
      dismissed: json['dismissed'] as bool? ?? false,
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
  'hr_zone_easy_seconds': ?instance.hrZoneEasySeconds,
  'hr_zone_moderate_seconds': ?instance.hrZoneModerateSeconds,
  'hr_zone_hard_seconds': ?instance.hrZoneHardSeconds,
  'training_load': ?instance.trainingLoad,
  'effort_score': ?instance.effortScore,
  'weight_kg': ?instance.weightKg,
  'workout_type': ?instance.workoutType,
  'dismissed': instance.dismissed,
  'recorded_at': ?instance.recordedAt?.toIso8601String(),
};
