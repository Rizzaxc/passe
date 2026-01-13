// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timeslot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Timeslot _$TimeslotFromJson(Map json) => Timeslot(
  $enumDecode(_$DayOfWeekEnumMap, json['dayOfWeek']),
  $enumDecode(_$DayChunkEnumMap, json['dayChunk']),
);

Map<String, dynamic> _$TimeslotToJson(Timeslot instance) => <String, dynamic>{
  'dayOfWeek': _$DayOfWeekEnumMap[instance.dayOfWeek]!,
  'dayChunk': _$DayChunkEnumMap[instance.dayChunk]!,
};

const _$DayOfWeekEnumMap = {
  DayOfWeek.everyday: 'all',
  DayOfWeek.monday: 'mon',
  DayOfWeek.tuesday: 'tue',
  DayOfWeek.wednesday: 'wed',
  DayOfWeek.thursday: 'thu',
  DayOfWeek.friday: 'fri',
  DayOfWeek.saturday: 'sat',
  DayOfWeek.sunday: 'sun',
  DayOfWeek.even: 'mwf',
  DayOfWeek.odd: 'tts',
  DayOfWeek.weekend: 'wkn',
};

const _$DayChunkEnumMap = {
  DayChunk.early: 'early',
  DayChunk.midday: 'midday',
  DayChunk.noon: 'noon',
  DayChunk.night: 'night',
};
