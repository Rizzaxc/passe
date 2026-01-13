// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Network _$NetworkFromJson(Map json) => _Network(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  isAlumni: json['isAlumni'] as bool,
  category: $enumDecode(_$NetworkCategoryEnumMap, json['category']),
  city: $enumDecodeNullable(_$CityEnumMap, json['city']),
);

Map<String, dynamic> _$NetworkToJson(_Network instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'isAlumni': instance.isAlumni,
  'category': _$NetworkCategoryEnumMap[instance.category]!,
  'city': ?_$CityEnumMap[instance.city],
};

const _$NetworkCategoryEnumMap = {
  NetworkCategory.highSchool: 'high school',
  NetworkCategory.giftedHighSchool: 'gifted high school',
  NetworkCategory.university: 'university',
  NetworkCategory.company: 'company',
};

const _$CityEnumMap = {City.hochiminh: 1, City.hanoi: 2};
