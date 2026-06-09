import 'package:freezed_annotation/freezed_annotation.dart';

part 'activity_health_row.freezed.dart';
part 'activity_health_row.g.dart';

/// One captured-activity recap row, as returned by the `activity_health_data`
/// RPC (metrics joined to activity context). Read-only view model.
@freezed
abstract class ActivityHealthRow with _$ActivityHealthRow {
  const factory ActivityHealthRow({
    @JsonKey(name: 'activity_id') required String activityId,
    @JsonKey(name: 'start_time') required DateTime startTime,
    @JsonKey(name: 'end_time') DateTime? endTime,
    @JsonKey(name: 'duration_minutes') int? durationMinutes,
    @JsonKey(name: 'location_label') String? locationLabel,
    required String source,
    int? steps,
    @JsonKey(name: 'distance_meters') double? distanceMeters,
    @JsonKey(name: 'active_calories') double? activeCalories,
    @JsonKey(name: 'avg_heart_rate') int? avgHeartRate,
    @JsonKey(name: 'max_heart_rate') int? maxHeartRate,
    @JsonKey(name: 'min_heart_rate') int? minHeartRate,
    @JsonKey(name: 'hrv_sdnn_ms') double? hrvSdnnMs,
    @JsonKey(name: 'hr_zone_easy_seconds') int? hrZoneEasySeconds,
    @JsonKey(name: 'hr_zone_moderate_seconds') int? hrZoneModerateSeconds,
    @JsonKey(name: 'hr_zone_hard_seconds') int? hrZoneHardSeconds,
    @JsonKey(name: 'training_load') double? trainingLoad,
    @JsonKey(name: 'effort_score') double? effortScore,
    @JsonKey(name: 'workout_type') String? workoutType,
    @JsonKey(name: 'recorded_at') DateTime? recordedAt,
  }) = _ActivityHealthRow;

  factory ActivityHealthRow.fromJson(Map<String, dynamic> json) =>
      _$ActivityHealthRowFromJson(json);
}
