// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'level_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LevelSummary _$LevelSummaryFromJson(Map json) => _LevelSummary(
  level: (json['level'] as num).toInt(),
  xpTotal: (json['xp_total'] as num).toInt(),
  currentFloor: (json['current_floor'] as num).toInt(),
  nextFloor: (json['next_floor'] as num?)?.toInt(),
);

Map<String, dynamic> _$LevelSummaryToJson(_LevelSummary instance) =>
    <String, dynamic>{
      'level': instance.level,
      'xp_total': instance.xpTotal,
      'current_floor': instance.currentFloor,
      'next_floor': ?instance.nextFloor,
    };
