// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hr_sample.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HrSample _$HrSampleFromJson(Map json) => _HrSample(
  id: (json['id'] as num?)?.toInt(),
  activityId: json['activity_id'] as String,
  timestamp: DateTime.parse(json['timestamp'] as String),
  bpm: (json['bpm'] as num).toInt(),
);

Map<String, dynamic> _$HrSampleToJson(_HrSample instance) => <String, dynamic>{
  'id': ?instance.id,
  'activity_id': instance.activityId,
  'timestamp': instance.timestamp.toIso8601String(),
  'bpm': instance.bpm,
};

_HrSampleBatch _$HrSampleBatchFromJson(Map json) => _HrSampleBatch(
  activityId: json['activity_id'] as String,
  samples: (json['samples'] as List<dynamic>)
      .map((e) => HrSamplePoint.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList(),
);

Map<String, dynamic> _$HrSampleBatchToJson(_HrSampleBatch instance) =>
    <String, dynamic>{
      'activity_id': instance.activityId,
      'samples': instance.samples.map((e) => e.toJson()).toList(),
    };

_HrSamplePoint _$HrSamplePointFromJson(Map json) => _HrSamplePoint(
  timestamp: DateTime.parse(json['timestamp'] as String),
  bpm: (json['bpm'] as num).toInt(),
);

Map<String, dynamic> _$HrSamplePointToJson(_HrSamplePoint instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp.toIso8601String(),
      'bpm': instance.bpm,
    };
