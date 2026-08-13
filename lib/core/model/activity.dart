import 'package:freezed_annotation/freezed_annotation.dart';

part 'activity.freezed.dart';
part 'activity.g.dart';

@freezed
abstract class Activity with _$Activity {
  const factory Activity({
    String? id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'sport_id') required int sportId,
    @JsonKey(name: 'start_time') required DateTime startTime,
    @JsonKey(name: 'end_time') DateTime? endTime,
    @JsonKey(name: 'lobby_id') String? lobbyId,
    // A coach session, mutually exclusive with lobby_id / freeplay_host_id.
    // Replaced the old professional_booking_id: coaching is a course now, not a
    // booking. See schema/course.sql.
    @JsonKey(name: 'course_id') String? courseId,
    // pending | approved | rejected | withdrawn — set iff course_id is set.
    // Only the coach approves; nothing else in the app carries a proposal state.
    @JsonKey(name: 'proposal_status') String? proposalStatus,
    // A referee hired for this (lobby) activity — allowed to coexist with
    // lobby_id. See schema/activity_professional_attachment.sql.
    @JsonKey(name: 'referee_booking_id') String? refereeBookingId,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Activity;

  factory Activity.fromJson(Map<String, dynamic> json) =>
      _$ActivityFromJson(json);
}
