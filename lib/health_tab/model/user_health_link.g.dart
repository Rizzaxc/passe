// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_health_link.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserHealthLink _$UserHealthLinkFromJson(Map json) => _UserHealthLink(
  userId: json['user_id'] as String,
  platform: $enumDecode(_$HealthPlatformEnumMap, json['platform']),
  linkedAt: DateTime.parse(json['linked_at'] as String),
  lastSyncAt: json['last_sync_at'] == null
      ? null
      : DateTime.parse(json['last_sync_at'] as String),
  maxHeartRate: (json['max_heart_rate'] as num?)?.toInt(),
  lt1Bpm: (json['lt1_bpm'] as num?)?.toInt(),
  lt2Bpm: (json['lt2_bpm'] as num?)?.toInt(),
);

Map<String, dynamic> _$UserHealthLinkToJson(_UserHealthLink instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'platform': _$HealthPlatformEnumMap[instance.platform]!,
      'linked_at': instance.linkedAt.toIso8601String(),
      'last_sync_at': ?instance.lastSyncAt?.toIso8601String(),
      'max_heart_rate': ?instance.maxHeartRate,
      'lt1_bpm': ?instance.lt1Bpm,
      'lt2_bpm': ?instance.lt2Bpm,
    };

const _$HealthPlatformEnumMap = {
  HealthPlatform.appleHealth: 'apple_health',
  HealthPlatform.googleFit: 'google_fit',
  HealthPlatform.healthConnect: 'health_connect',
};
