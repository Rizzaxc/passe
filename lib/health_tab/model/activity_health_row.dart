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
    // iOS reports SDNN, Android/Health Connect reports RMSSD — only one is
    // ever populated per platform. See health_controller.dart's hrvDataType.
    @JsonKey(name: 'hrv_sdnn_ms') double? hrvSdnnMs,
    @JsonKey(name: 'hrv_rmssd_ms') double? hrvRmssdMs,
    @JsonKey(name: 'hr_zone_easy_seconds') int? hrZoneEasySeconds,
    @JsonKey(name: 'hr_zone_moderate_seconds') int? hrZoneModerateSeconds,
    @JsonKey(name: 'hr_zone_hard_seconds') int? hrZoneHardSeconds,
    @JsonKey(name: 'training_load') double? trainingLoad,
    @JsonKey(name: 'effort_score') double? effortScore,
    @JsonKey(name: 'workout_type') String? workoutType,
    @JsonKey(name: 'recorded_at') DateTime? recordedAt,
    // The lobby/coach/host name — null for a 'self' (standalone) activity,
    // where there's nothing to name.
    @JsonKey(name: 'source_name') String? sourceName,
    // Only set when source == 'lobby' — lets the recap sheet link back to it.
    @JsonKey(name: 'lobby_id') String? lobbyId,
    // Only set when source == 'professional' (a course session).
    @JsonKey(name: 'course_id') String? courseId,
    // Avatar sourcing — each set only for its matching `source`, all null
    // for 'self'. Lobby: pairs with lobbyId/sourceName for `LobbyAvatar`.
    @JsonKey(name: 'lobby_has_avatar') bool? lobbyHasAvatar,
    // Professional/course: the coach's *linked user* identity, for
    // `PUserAvatar` — null when the coach profile isn't linked to a user
    // account (falls back to the generic activity icon).
    @JsonKey(name: 'avatar_user_id') String? avatarUserId,
    @JsonKey(name: 'avatar_username') String? avatarUsername,
    @JsonKey(name: 'avatar_generated') String? avatarGenerated,
    // Freeplay: freeplay_host.avatar_url directly.
    @JsonKey(name: 'freeplay_avatar_url') String? freeplayAvatarUrl,
  }) = _ActivityHealthRow;

  factory ActivityHealthRow.fromJson(Map<String, dynamic> json) =>
      _$ActivityHealthRowFromJson(json);
}
