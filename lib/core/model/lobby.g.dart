// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lobby.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LobbyDetails _$LobbyDetailsFromJson(Map json) => _LobbyDetails(
  ageGroup: $enumDecodeNullable(_$AgeGroupEnumMap, json['ageGroup']),
  skill: (json['skill'] as num?)?.toInt(),
);

Map<String, dynamic> _$LobbyDetailsToJson(_LobbyDetails instance) =>
    <String, dynamic>{
      'ageGroup': ?_$AgeGroupEnumMap[instance.ageGroup],
      'skill': ?instance.skill,
    };

const _$AgeGroupEnumMap = {
  AgeGroup.student: 'student',
  AgeGroup.mature: 'mature',
  AgeGroup.middleAge: 'middleAge',
};

_Lobby _$LobbyFromJson(Map json) => _Lobby(
  id: json['id'] as String?,
  captainId: json['captain_id'] as String?,
  searchableId: json['searchable_id'] as String?,
  name: json['name'] as String,
  sport: _sportFromJson(json['sport_id']),
  playtime: (json['playtime'] as List<dynamic>?)
      ?.map((e) => Timeslot.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList(),
  details: json['details'] == null
      ? null
      : LobbyDetails.fromJson(
          Map<String, dynamic>.from(json['details'] as Map),
        ),
  homeGround: json['home_ground'] as String?,
  visibility:
      $enumDecodeNullable(_$LobbyVisibilityEnumMap, json['visibility']) ??
      LobbyVisibility.discoverable,
);

Map<String, dynamic> _$LobbyToJson(_Lobby instance) => <String, dynamic>{
  'id': ?instance.id,
  'captain_id': ?instance.captainId,
  'searchable_id': ?instance.searchableId,
  'name': instance.name,
  'sport_id': _sportToJson(instance.sport),
  'playtime': ?instance.playtime?.map((e) => e.toJson()).toList(),
  'details': ?instance.details?.toJson(),
  'home_ground': ?instance.homeGround,
  'visibility': _$LobbyVisibilityEnumMap[instance.visibility]!,
};

const _$LobbyVisibilityEnumMap = {
  LobbyVisibility.private: 'private',
  LobbyVisibility.discoverable: 'discoverable',
  LobbyVisibility.public: 'public',
};
