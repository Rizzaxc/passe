// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_details.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserDetails _$UserDetailsFromJson(Map<String, dynamic> json) => _UserDetails(
  gender: $enumDecodeNullable(_$GenderEnumMap, json['gender']),
  ageGroup: $enumDecodeNullable(_$AgeGroupEnumMap, json['ageGroup']),
  playtime:
      (json['playtime'] as List<dynamic>?)
          ?.map((e) => Timeslot.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  location: json['location'] == null
      ? null
      : UserLocation.fromJson(json['location'] as Map<String, dynamic>),
);

Map<String, dynamic> _$UserDetailsToJson(_UserDetails instance) =>
    <String, dynamic>{
      'gender': _$GenderEnumMap[instance.gender],
      'ageGroup': _$AgeGroupEnumMap[instance.ageGroup],
      'playtime': instance.playtime,
      'location': instance.location,
    };

const _$GenderEnumMap = {Gender.male: 'male', Gender.female: 'female'};

const _$AgeGroupEnumMap = {
  AgeGroup.student: 'student',
  AgeGroup.mature: 'mature',
  AgeGroup.middleAge: 'middleAge',
};
