// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'passe_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PasseUser _$PasseUserFromJson(Map json) => _PasseUser(
  id: json['id'] as String?,
  username: json['username'] as String? ?? 'Guest',
  tagNumber: json['tagNumber'] as String? ?? '0000',
  email: json['email'] as String?,
  details: json['details'] == null
      ? null
      : UserDetails.fromJson(Map<String, dynamic>.from(json['details'] as Map)),
);

Map<String, dynamic> _$PasseUserToJson(_PasseUser instance) =>
    <String, dynamic>{
      'id': ?instance.id,
      'username': instance.username,
      'tagNumber': instance.tagNumber,
      'email': ?instance.email,
      'details': ?instance.details?.toJson(),
    };
