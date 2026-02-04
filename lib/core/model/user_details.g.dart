// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_details.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SportProfile _$SportProfileFromJson(Map json) =>
    _SportProfile(skill: (json['skill'] as num?)?.toInt());

Map<String, dynamic> _$SportProfileToJson(_SportProfile instance) =>
    <String, dynamic>{'skill': ?instance.skill};

_UserDetails _$UserDetailsFromJson(Map json) => _UserDetails(
  gender: $enumDecodeNullable(_$GenderEnumMap, json['gender']),
  ageGroup: $enumDecodeNullable(_$AgeGroupEnumMap, json['ageGroup']),
  playtime: (json['playtime'] as List<dynamic>?)
      ?.map((e) => Timeslot.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList(),
  location: json['location'] == null
      ? null
      : UserLocation.fromJson(
          Map<String, dynamic>.from(json['location'] as Map),
        ),
  sport: (json['sport'] as Map?)?.map(
    (k, e) => MapEntry(
      k as String,
      SportProfile.fromJson(Map<String, dynamic>.from(e as Map)),
    ),
  ),
  generatedAvatar: json['generatedAvatar'] as String?,
);

Map<String, dynamic> _$UserDetailsToJson(_UserDetails instance) =>
    <String, dynamic>{
      'gender': ?_$GenderEnumMap[instance.gender],
      'ageGroup': ?_$AgeGroupEnumMap[instance.ageGroup],
      'playtime': ?instance.playtime?.map((e) => e.toJson()).toList(),
      'location': ?instance.location?.toJson(),
      'sport': ?instance.sport?.map((k, e) => MapEntry(k, e.toJson())),
      'generatedAvatar': ?instance.generatedAvatar,
    };

const _$GenderEnumMap = {Gender.male: 'male', Gender.female: 'female'};

const _$AgeGroupEnumMap = {
  AgeGroup.student: 'student',
  AgeGroup.mature: 'mature',
  AgeGroup.middleAge: 'middleAge',
};
