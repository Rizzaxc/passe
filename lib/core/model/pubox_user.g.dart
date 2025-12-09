// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pubox_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PuboxUser _$PuboxUserFromJson(Map<String, dynamic> json) => _PuboxUser(
  id: json['id'] as String?,
  displayName: json['displayName'] as String? ?? 'Guest',
  email: json['email'] as String?,
  details: json['details'] == null
      ? null
      : UserDetails.fromJson(json['details'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PuboxUserToJson(_PuboxUser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'displayName': instance.displayName,
      'email': instance.email,
      'details': instance.details,
    };
