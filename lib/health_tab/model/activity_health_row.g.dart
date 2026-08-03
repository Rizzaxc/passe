// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_health_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ActivityHealthRow _$ActivityHealthRowFromJson(Map json) => _ActivityHealthRow(
  activityId: json['activity_id'] as String,
  startTime: DateTime.parse(json['start_time'] as String),
  endTime: json['end_time'] == null
      ? null
      : DateTime.parse(json['end_time'] as String),
  durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
  locationLabel: json['location_label'] as String?,
  source: json['source'] as String,
  steps: (json['steps'] as num?)?.toInt(),
  distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
  activeCalories: (json['active_calories'] as num?)?.toDouble(),
  avgHeartRate: (json['avg_heart_rate'] as num?)?.toInt(),
  maxHeartRate: (json['max_heart_rate'] as num?)?.toInt(),
  minHeartRate: (json['min_heart_rate'] as num?)?.toInt(),
  hrvSdnnMs: (json['hrv_sdnn_ms'] as num?)?.toDouble(),
  hrvRmssdMs: (json['hrv_rmssd_ms'] as num?)?.toDouble(),
  hrZoneEasySeconds: (json['hr_zone_easy_seconds'] as num?)?.toInt(),
  hrZoneModerateSeconds: (json['hr_zone_moderate_seconds'] as num?)?.toInt(),
  hrZoneHardSeconds: (json['hr_zone_hard_seconds'] as num?)?.toInt(),
  trainingLoad: (json['training_load'] as num?)?.toDouble(),
  effortScore: (json['effort_score'] as num?)?.toDouble(),
  workoutType: json['workout_type'] as String?,
  recordedAt: json['recorded_at'] == null
      ? null
      : DateTime.parse(json['recorded_at'] as String),
);

Map<String, dynamic> _$ActivityHealthRowToJson(_ActivityHealthRow instance) =>
    <String, dynamic>{
      'activity_id': instance.activityId,
      'start_time': instance.startTime.toIso8601String(),
      'end_time': ?instance.endTime?.toIso8601String(),
      'duration_minutes': ?instance.durationMinutes,
      'location_label': ?instance.locationLabel,
      'source': instance.source,
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
      'workout_type': ?instance.workoutType,
      'recorded_at': ?instance.recordedAt?.toIso8601String(),
    };
