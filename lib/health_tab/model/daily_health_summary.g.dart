// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_health_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DailyHealthSummary _$DailyHealthSummaryFromJson(Map json) =>
    _DailyHealthSummary(
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      restingHeartRate: (json['resting_heart_rate'] as num?)?.toInt(),
      hrvSdnnMs: (json['hrv_sdnn_ms'] as num?)?.toDouble(),
      steps: (json['steps'] as num?)?.toInt(),
      distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
      activeCalories: (json['active_calories'] as num?)?.toDouble(),
      totalCalories: (json['total_calories'] as num?)?.toDouble(),
      sleepMinutes: (json['sleep_minutes'] as num?)?.toInt(),
      sleepQualityScore: (json['sleep_quality_score'] as num?)?.toDouble(),
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      activityCount: (json['activity_count'] as num?)?.toInt() ?? 0,
      totalActivityMinutes:
          (json['total_activity_minutes'] as num?)?.toInt() ?? 0,
      syncedAt: json['synced_at'] == null
          ? null
          : DateTime.parse(json['synced_at'] as String),
    );

Map<String, dynamic> _$DailyHealthSummaryToJson(_DailyHealthSummary instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'date': instance.date.toIso8601String(),
      'resting_heart_rate': ?instance.restingHeartRate,
      'hrv_sdnn_ms': ?instance.hrvSdnnMs,
      'steps': ?instance.steps,
      'distance_meters': ?instance.distanceMeters,
      'active_calories': ?instance.activeCalories,
      'total_calories': ?instance.totalCalories,
      'sleep_minutes': ?instance.sleepMinutes,
      'sleep_quality_score': ?instance.sleepQualityScore,
      'weight_kg': ?instance.weightKg,
      'activity_count': instance.activityCount,
      'total_activity_minutes': instance.totalActivityMinutes,
      'synced_at': ?instance.syncedAt?.toIso8601String(),
    };
