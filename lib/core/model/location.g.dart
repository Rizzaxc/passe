// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Location _$LocationFromJson(Map json) => _Location(
  id: json['id'] as String,
  name: json['name'] as String,
  fullAddress: json['full_address'] as String?,
  streetNumber: _streetNumberFromJson(json['street_number']),
  streetName: json['street_name'] as String?,
  district: json['district'] as String?,
  city: json['city'] as String?,
  lat: (json['lat'] as num?)?.toDouble(),
  lon: (json['lon'] as num?)?.toDouble(),
  tags: json['tags'] == null ? const <String>[] : _tagsFromJson(json['tags']),
  cityCluster: (json['city_cluster'] as num?)?.toInt(),
);

Map<String, dynamic> _$LocationToJson(_Location instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'full_address': ?instance.fullAddress,
  'street_number': ?instance.streetNumber,
  'street_name': ?instance.streetName,
  'district': ?instance.district,
  'city': ?instance.city,
  'lat': ?instance.lat,
  'lon': ?instance.lon,
  'tags': instance.tags,
  'city_cluster': ?instance.cityCluster,
};
