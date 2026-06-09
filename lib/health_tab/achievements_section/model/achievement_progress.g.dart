// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievement_progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AchievementProgress _$AchievementProgressFromJson(Map json) =>
    _AchievementProgress(
      achievementId: json['achievement_id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      difficulty: _toInt(json['difficulty']),
      consistency: _toInt(json['consistency']),
      xpReward: _toInt(json['xp_reward']),
      repeatable: json['repeatable'] as bool,
      currentValue: _toDouble(json['current_value']),
      threshold: _toDouble(json['threshold']),
      progress: _toDouble(json['progress']),
      state: _toState(json['state']),
      periodKey: json['period_key'] as String,
    );

Map<String, dynamic> _$AchievementProgressToJson(
  _AchievementProgress instance,
) => <String, dynamic>{
  'achievement_id': instance.achievementId,
  'code': instance.code,
  'name': instance.name,
  'description': ?instance.description,
  'difficulty': instance.difficulty,
  'consistency': instance.consistency,
  'xp_reward': instance.xpReward,
  'repeatable': instance.repeatable,
  'current_value': instance.currentValue,
  'threshold': instance.threshold,
  'progress': instance.progress,
  'state': _$AchievementStateEnumMap[instance.state]!,
  'period_key': instance.periodKey,
};

const _$AchievementStateEnumMap = {
  AchievementState.notStarted: 'notStarted',
  AchievementState.inProgress: 'inProgress',
  AchievementState.earnedPeriod: 'earnedPeriod',
  AchievementState.done: 'done',
};
