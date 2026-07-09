import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_health_summary.freezed.dart';
part 'daily_health_summary.g.dart';

@freezed
abstract class DailyHealthSummary with _$DailyHealthSummary {
  const factory DailyHealthSummary({
    @JsonKey(name: 'user_id') required String userId,
    required DateTime date,

    // Resting vitals
    @JsonKey(name: 'resting_heart_rate') int? restingHeartRate,
    @JsonKey(name: 'hrv_sdnn_ms') double? hrvSdnnMs,

    // Daily totals
    int? steps,
    @JsonKey(name: 'distance_meters') double? distanceMeters,
    @JsonKey(name: 'active_calories') double? activeCalories,
    @JsonKey(name: 'total_calories') double? totalCalories,

    // Sleep
    @JsonKey(name: 'sleep_minutes') int? sleepMinutes,
    @JsonKey(name: 'sleep_quality_score') double? sleepQualityScore,

    // Weight
    @JsonKey(name: 'weight_kg') double? weightKg,

    // Activity summary
    @Default(0) @JsonKey(name: 'activity_count') int activityCount,
    @Default(0)
    @JsonKey(name: 'total_activity_minutes')
    int totalActivityMinutes,

    @JsonKey(name: 'synced_at') DateTime? syncedAt,
  }) = _DailyHealthSummary;

  factory DailyHealthSummary.fromJson(Map<String, dynamic> json) =>
      _$DailyHealthSummaryFromJson(json);
}
