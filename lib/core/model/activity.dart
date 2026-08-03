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
    @JsonKey(name: 'professional_booking_id') String? professionalBookingId,
    // A coach and/or referee hired for this (lobby) activity — distinct from
    // professional_booking_id, and allowed to coexist with lobby_id. See
    // schema/activity_professional_attachment.sql.
    @JsonKey(name: 'coach_booking_id') String? coachBookingId,
    @JsonKey(name: 'referee_booking_id') String? refereeBookingId,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Activity;

  factory Activity.fromJson(Map<String, dynamic> json) =>
      _$ActivityFromJson(json);
}
