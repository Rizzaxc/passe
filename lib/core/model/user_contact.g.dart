// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_contact.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserContact _$UserContactFromJson(Map json) => _UserContact(
  zalo: json['zalo'] as String?,
  zaloPublic: json['zalo_public'] as bool? ?? false,
);

Map<String, dynamic> _$UserContactToJson(_UserContact instance) =>
    <String, dynamic>{
      'zalo': ?instance.zalo,
      'zalo_public': instance.zaloPublic,
    };
