// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserLocation _$UserLocationFromJson(Map<String, dynamic> json) =>
    _UserLocation(
      city: $enumDecodeNullable(_$CityEnumMap, json['city']),
      districts:
          (json['districts'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$UserLocationToJson(_UserLocation instance) =>
    <String, dynamic>{
      'city': _$CityEnumMap[instance.city],
      'districts': instance.districts,
    };

const _$CityEnumMap = {City.hochiminh: '1', City.hanoi: '2'};
