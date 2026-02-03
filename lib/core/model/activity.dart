import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

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
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Activity;

  factory Activity.fromJson(Map<String, dynamic> json) =>
      _$ActivityFromJson(json);
}
