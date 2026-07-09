import 'package:freezed_annotation/freezed_annotation.dart';

part 'hr_sample.freezed.dart';
part 'hr_sample.g.dart';

@freezed
abstract class HrSample with _$HrSample {
  const factory HrSample({
    int? id,
    @JsonKey(name: 'activity_id') required String activityId,
    required DateTime timestamp,
    required int bpm,
  }) = _HrSample;

  factory HrSample.fromJson(Map<String, dynamic> json) =>
      _$HrSampleFromJson(json);
}

/// Batch of HR samples for efficient upload
@freezed
abstract class HrSampleBatch with _$HrSampleBatch {
  const factory HrSampleBatch({
    @JsonKey(name: 'activity_id') required String activityId,
    required List<HrSamplePoint> samples,
  }) = _HrSampleBatch;

  factory HrSampleBatch.fromJson(Map<String, dynamic> json) =>
      _$HrSampleBatchFromJson(json);
}

@freezed
abstract class HrSamplePoint with _$HrSamplePoint {
  const factory HrSamplePoint({required DateTime timestamp, required int bpm}) =
      _HrSamplePoint;

  factory HrSamplePoint.fromJson(Map<String, dynamic> json) =>
      _$HrSamplePointFromJson(json);
}
