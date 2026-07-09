// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vitality_score.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VitalityScore _$VitalityScoreFromJson(Map json) => _VitalityScore(
  date: DateTime.parse(json['date'] as String),
  score: _toNullableDouble(json['score']),
  consistencyComponent: _toNullableDouble(json['consistency_component']),
  loadComponent: _toNullableDouble(json['load_component']),
  recoveryComponent: _toNullableDouble(json['recovery_component']),
  volumeComponent: _toNullableDouble(json['volume_component']),
  streakBonus: json['streak_bonus'] == null
      ? 0
      : _toDouble(json['streak_bonus']),
  ctl: _toNullableDouble(json['ctl']),
  atl: _toNullableDouble(json['atl']),
);

Map<String, dynamic> _$VitalityScoreToJson(_VitalityScore instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'score': ?instance.score,
      'consistency_component': ?instance.consistencyComponent,
      'load_component': ?instance.loadComponent,
      'recovery_component': ?instance.recoveryComponent,
      'volume_component': ?instance.volumeComponent,
      'streak_bonus': instance.streakBonus,
      'ctl': ?instance.ctl,
      'atl': ?instance.atl,
    };
