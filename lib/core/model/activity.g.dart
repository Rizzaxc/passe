// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Activity _$ActivityFromJson(Map json) => _Activity(
  id: json['id'] as String?,
  userId: json['user_id'] as String,
  sportId: (json['sport_id'] as num).toInt(),
  startTime: DateTime.parse(json['start_time'] as String),
  endTime: json['end_time'] == null
      ? null
      : DateTime.parse(json['end_time'] as String),
  lobbyId: json['lobby_id'] as String?,
  courseId: json['course_id'] as String?,
  proposalStatus: json['proposal_status'] as String?,
  refereeBookingId: json['referee_booking_id'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$ActivityToJson(_Activity instance) => <String, dynamic>{
  'id': ?instance.id,
  'user_id': instance.userId,
  'sport_id': instance.sportId,
  'start_time': instance.startTime.toIso8601String(),
  'end_time': ?instance.endTime?.toIso8601String(),
  'lobby_id': ?instance.lobbyId,
  'course_id': ?instance.courseId,
  'proposal_status': ?instance.proposalStatus,
  'referee_booking_id': ?instance.refereeBookingId,
  'created_at': ?instance.createdAt?.toIso8601String(),
};
