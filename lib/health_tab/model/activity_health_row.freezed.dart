// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'activity_health_row.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ActivityHealthRow {

@JsonKey(name: 'activity_id') String get activityId;@JsonKey(name: 'start_time') DateTime get startTime;@JsonKey(name: 'end_time') DateTime? get endTime;@JsonKey(name: 'duration_minutes') int? get durationMinutes;@JsonKey(name: 'location_label') String? get locationLabel; String get source; int? get steps;@JsonKey(name: 'distance_meters') double? get distanceMeters;@JsonKey(name: 'active_calories') double? get activeCalories;@JsonKey(name: 'avg_heart_rate') int? get avgHeartRate;@JsonKey(name: 'max_heart_rate') int? get maxHeartRate;@JsonKey(name: 'min_heart_rate') int? get minHeartRate;@JsonKey(name: 'hrv_sdnn_ms') double? get hrvSdnnMs;@JsonKey(name: 'hrv_rmssd_ms') double? get hrvRmssdMs;@JsonKey(name: 'hr_zone_easy_seconds') int? get hrZoneEasySeconds;@JsonKey(name: 'hr_zone_moderate_seconds') int? get hrZoneModerateSeconds;@JsonKey(name: 'hr_zone_hard_seconds') int? get hrZoneHardSeconds;@JsonKey(name: 'training_load') double? get trainingLoad;@JsonKey(name: 'effort_score') double? get effortScore;@JsonKey(name: 'workout_type') String? get workoutType;@JsonKey(name: 'recorded_at') DateTime? get recordedAt;
/// Create a copy of ActivityHealthRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActivityHealthRowCopyWith<ActivityHealthRow> get copyWith => _$ActivityHealthRowCopyWithImpl<ActivityHealthRow>(this as ActivityHealthRow, _$identity);

  /// Serializes this ActivityHealthRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActivityHealthRow&&(identical(other.activityId, activityId) || other.activityId == activityId)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.durationMinutes, durationMinutes) || other.durationMinutes == durationMinutes)&&(identical(other.locationLabel, locationLabel) || other.locationLabel == locationLabel)&&(identical(other.source, source) || other.source == source)&&(identical(other.steps, steps) || other.steps == steps)&&(identical(other.distanceMeters, distanceMeters) || other.distanceMeters == distanceMeters)&&(identical(other.activeCalories, activeCalories) || other.activeCalories == activeCalories)&&(identical(other.avgHeartRate, avgHeartRate) || other.avgHeartRate == avgHeartRate)&&(identical(other.maxHeartRate, maxHeartRate) || other.maxHeartRate == maxHeartRate)&&(identical(other.minHeartRate, minHeartRate) || other.minHeartRate == minHeartRate)&&(identical(other.hrvSdnnMs, hrvSdnnMs) || other.hrvSdnnMs == hrvSdnnMs)&&(identical(other.hrvRmssdMs, hrvRmssdMs) || other.hrvRmssdMs == hrvRmssdMs)&&(identical(other.hrZoneEasySeconds, hrZoneEasySeconds) || other.hrZoneEasySeconds == hrZoneEasySeconds)&&(identical(other.hrZoneModerateSeconds, hrZoneModerateSeconds) || other.hrZoneModerateSeconds == hrZoneModerateSeconds)&&(identical(other.hrZoneHardSeconds, hrZoneHardSeconds) || other.hrZoneHardSeconds == hrZoneHardSeconds)&&(identical(other.trainingLoad, trainingLoad) || other.trainingLoad == trainingLoad)&&(identical(other.effortScore, effortScore) || other.effortScore == effortScore)&&(identical(other.workoutType, workoutType) || other.workoutType == workoutType)&&(identical(other.recordedAt, recordedAt) || other.recordedAt == recordedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,activityId,startTime,endTime,durationMinutes,locationLabel,source,steps,distanceMeters,activeCalories,avgHeartRate,maxHeartRate,minHeartRate,hrvSdnnMs,hrvRmssdMs,hrZoneEasySeconds,hrZoneModerateSeconds,hrZoneHardSeconds,trainingLoad,effortScore,workoutType,recordedAt]);

@override
String toString() {
  return 'ActivityHealthRow(activityId: $activityId, startTime: $startTime, endTime: $endTime, durationMinutes: $durationMinutes, locationLabel: $locationLabel, source: $source, steps: $steps, distanceMeters: $distanceMeters, activeCalories: $activeCalories, avgHeartRate: $avgHeartRate, maxHeartRate: $maxHeartRate, minHeartRate: $minHeartRate, hrvSdnnMs: $hrvSdnnMs, hrvRmssdMs: $hrvRmssdMs, hrZoneEasySeconds: $hrZoneEasySeconds, hrZoneModerateSeconds: $hrZoneModerateSeconds, hrZoneHardSeconds: $hrZoneHardSeconds, trainingLoad: $trainingLoad, effortScore: $effortScore, workoutType: $workoutType, recordedAt: $recordedAt)';
}


}

/// @nodoc
abstract mixin class $ActivityHealthRowCopyWith<$Res>  {
  factory $ActivityHealthRowCopyWith(ActivityHealthRow value, $Res Function(ActivityHealthRow) _then) = _$ActivityHealthRowCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'activity_id') String activityId,@JsonKey(name: 'start_time') DateTime startTime,@JsonKey(name: 'end_time') DateTime? endTime,@JsonKey(name: 'duration_minutes') int? durationMinutes,@JsonKey(name: 'location_label') String? locationLabel, String source, int? steps,@JsonKey(name: 'distance_meters') double? distanceMeters,@JsonKey(name: 'active_calories') double? activeCalories,@JsonKey(name: 'avg_heart_rate') int? avgHeartRate,@JsonKey(name: 'max_heart_rate') int? maxHeartRate,@JsonKey(name: 'min_heart_rate') int? minHeartRate,@JsonKey(name: 'hrv_sdnn_ms') double? hrvSdnnMs,@JsonKey(name: 'hrv_rmssd_ms') double? hrvRmssdMs,@JsonKey(name: 'hr_zone_easy_seconds') int? hrZoneEasySeconds,@JsonKey(name: 'hr_zone_moderate_seconds') int? hrZoneModerateSeconds,@JsonKey(name: 'hr_zone_hard_seconds') int? hrZoneHardSeconds,@JsonKey(name: 'training_load') double? trainingLoad,@JsonKey(name: 'effort_score') double? effortScore,@JsonKey(name: 'workout_type') String? workoutType,@JsonKey(name: 'recorded_at') DateTime? recordedAt
});




}
/// @nodoc
class _$ActivityHealthRowCopyWithImpl<$Res>
    implements $ActivityHealthRowCopyWith<$Res> {
  _$ActivityHealthRowCopyWithImpl(this._self, this._then);

  final ActivityHealthRow _self;
  final $Res Function(ActivityHealthRow) _then;

/// Create a copy of ActivityHealthRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? activityId = null,Object? startTime = null,Object? endTime = freezed,Object? durationMinutes = freezed,Object? locationLabel = freezed,Object? source = null,Object? steps = freezed,Object? distanceMeters = freezed,Object? activeCalories = freezed,Object? avgHeartRate = freezed,Object? maxHeartRate = freezed,Object? minHeartRate = freezed,Object? hrvSdnnMs = freezed,Object? hrvRmssdMs = freezed,Object? hrZoneEasySeconds = freezed,Object? hrZoneModerateSeconds = freezed,Object? hrZoneHardSeconds = freezed,Object? trainingLoad = freezed,Object? effortScore = freezed,Object? workoutType = freezed,Object? recordedAt = freezed,}) {
  return _then(_self.copyWith(
activityId: null == activityId ? _self.activityId : activityId // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,endTime: freezed == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as DateTime?,durationMinutes: freezed == durationMinutes ? _self.durationMinutes : durationMinutes // ignore: cast_nullable_to_non_nullable
as int?,locationLabel: freezed == locationLabel ? _self.locationLabel : locationLabel // ignore: cast_nullable_to_non_nullable
as String?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,steps: freezed == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as int?,distanceMeters: freezed == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as double?,activeCalories: freezed == activeCalories ? _self.activeCalories : activeCalories // ignore: cast_nullable_to_non_nullable
as double?,avgHeartRate: freezed == avgHeartRate ? _self.avgHeartRate : avgHeartRate // ignore: cast_nullable_to_non_nullable
as int?,maxHeartRate: freezed == maxHeartRate ? _self.maxHeartRate : maxHeartRate // ignore: cast_nullable_to_non_nullable
as int?,minHeartRate: freezed == minHeartRate ? _self.minHeartRate : minHeartRate // ignore: cast_nullable_to_non_nullable
as int?,hrvSdnnMs: freezed == hrvSdnnMs ? _self.hrvSdnnMs : hrvSdnnMs // ignore: cast_nullable_to_non_nullable
as double?,hrvRmssdMs: freezed == hrvRmssdMs ? _self.hrvRmssdMs : hrvRmssdMs // ignore: cast_nullable_to_non_nullable
as double?,hrZoneEasySeconds: freezed == hrZoneEasySeconds ? _self.hrZoneEasySeconds : hrZoneEasySeconds // ignore: cast_nullable_to_non_nullable
as int?,hrZoneModerateSeconds: freezed == hrZoneModerateSeconds ? _self.hrZoneModerateSeconds : hrZoneModerateSeconds // ignore: cast_nullable_to_non_nullable
as int?,hrZoneHardSeconds: freezed == hrZoneHardSeconds ? _self.hrZoneHardSeconds : hrZoneHardSeconds // ignore: cast_nullable_to_non_nullable
as int?,trainingLoad: freezed == trainingLoad ? _self.trainingLoad : trainingLoad // ignore: cast_nullable_to_non_nullable
as double?,effortScore: freezed == effortScore ? _self.effortScore : effortScore // ignore: cast_nullable_to_non_nullable
as double?,workoutType: freezed == workoutType ? _self.workoutType : workoutType // ignore: cast_nullable_to_non_nullable
as String?,recordedAt: freezed == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ActivityHealthRow].
extension ActivityHealthRowPatterns on ActivityHealthRow {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActivityHealthRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActivityHealthRow() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActivityHealthRow value)  $default,){
final _that = this;
switch (_that) {
case _ActivityHealthRow():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActivityHealthRow value)?  $default,){
final _that = this;
switch (_that) {
case _ActivityHealthRow() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'activity_id')  String activityId, @JsonKey(name: 'start_time')  DateTime startTime, @JsonKey(name: 'end_time')  DateTime? endTime, @JsonKey(name: 'duration_minutes')  int? durationMinutes, @JsonKey(name: 'location_label')  String? locationLabel,  String source,  int? steps, @JsonKey(name: 'distance_meters')  double? distanceMeters, @JsonKey(name: 'active_calories')  double? activeCalories, @JsonKey(name: 'avg_heart_rate')  int? avgHeartRate, @JsonKey(name: 'max_heart_rate')  int? maxHeartRate, @JsonKey(name: 'min_heart_rate')  int? minHeartRate, @JsonKey(name: 'hrv_sdnn_ms')  double? hrvSdnnMs, @JsonKey(name: 'hrv_rmssd_ms')  double? hrvRmssdMs, @JsonKey(name: 'hr_zone_easy_seconds')  int? hrZoneEasySeconds, @JsonKey(name: 'hr_zone_moderate_seconds')  int? hrZoneModerateSeconds, @JsonKey(name: 'hr_zone_hard_seconds')  int? hrZoneHardSeconds, @JsonKey(name: 'training_load')  double? trainingLoad, @JsonKey(name: 'effort_score')  double? effortScore, @JsonKey(name: 'workout_type')  String? workoutType, @JsonKey(name: 'recorded_at')  DateTime? recordedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActivityHealthRow() when $default != null:
return $default(_that.activityId,_that.startTime,_that.endTime,_that.durationMinutes,_that.locationLabel,_that.source,_that.steps,_that.distanceMeters,_that.activeCalories,_that.avgHeartRate,_that.maxHeartRate,_that.minHeartRate,_that.hrvSdnnMs,_that.hrvRmssdMs,_that.hrZoneEasySeconds,_that.hrZoneModerateSeconds,_that.hrZoneHardSeconds,_that.trainingLoad,_that.effortScore,_that.workoutType,_that.recordedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'activity_id')  String activityId, @JsonKey(name: 'start_time')  DateTime startTime, @JsonKey(name: 'end_time')  DateTime? endTime, @JsonKey(name: 'duration_minutes')  int? durationMinutes, @JsonKey(name: 'location_label')  String? locationLabel,  String source,  int? steps, @JsonKey(name: 'distance_meters')  double? distanceMeters, @JsonKey(name: 'active_calories')  double? activeCalories, @JsonKey(name: 'avg_heart_rate')  int? avgHeartRate, @JsonKey(name: 'max_heart_rate')  int? maxHeartRate, @JsonKey(name: 'min_heart_rate')  int? minHeartRate, @JsonKey(name: 'hrv_sdnn_ms')  double? hrvSdnnMs, @JsonKey(name: 'hrv_rmssd_ms')  double? hrvRmssdMs, @JsonKey(name: 'hr_zone_easy_seconds')  int? hrZoneEasySeconds, @JsonKey(name: 'hr_zone_moderate_seconds')  int? hrZoneModerateSeconds, @JsonKey(name: 'hr_zone_hard_seconds')  int? hrZoneHardSeconds, @JsonKey(name: 'training_load')  double? trainingLoad, @JsonKey(name: 'effort_score')  double? effortScore, @JsonKey(name: 'workout_type')  String? workoutType, @JsonKey(name: 'recorded_at')  DateTime? recordedAt)  $default,) {final _that = this;
switch (_that) {
case _ActivityHealthRow():
return $default(_that.activityId,_that.startTime,_that.endTime,_that.durationMinutes,_that.locationLabel,_that.source,_that.steps,_that.distanceMeters,_that.activeCalories,_that.avgHeartRate,_that.maxHeartRate,_that.minHeartRate,_that.hrvSdnnMs,_that.hrvRmssdMs,_that.hrZoneEasySeconds,_that.hrZoneModerateSeconds,_that.hrZoneHardSeconds,_that.trainingLoad,_that.effortScore,_that.workoutType,_that.recordedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'activity_id')  String activityId, @JsonKey(name: 'start_time')  DateTime startTime, @JsonKey(name: 'end_time')  DateTime? endTime, @JsonKey(name: 'duration_minutes')  int? durationMinutes, @JsonKey(name: 'location_label')  String? locationLabel,  String source,  int? steps, @JsonKey(name: 'distance_meters')  double? distanceMeters, @JsonKey(name: 'active_calories')  double? activeCalories, @JsonKey(name: 'avg_heart_rate')  int? avgHeartRate, @JsonKey(name: 'max_heart_rate')  int? maxHeartRate, @JsonKey(name: 'min_heart_rate')  int? minHeartRate, @JsonKey(name: 'hrv_sdnn_ms')  double? hrvSdnnMs, @JsonKey(name: 'hrv_rmssd_ms')  double? hrvRmssdMs, @JsonKey(name: 'hr_zone_easy_seconds')  int? hrZoneEasySeconds, @JsonKey(name: 'hr_zone_moderate_seconds')  int? hrZoneModerateSeconds, @JsonKey(name: 'hr_zone_hard_seconds')  int? hrZoneHardSeconds, @JsonKey(name: 'training_load')  double? trainingLoad, @JsonKey(name: 'effort_score')  double? effortScore, @JsonKey(name: 'workout_type')  String? workoutType, @JsonKey(name: 'recorded_at')  DateTime? recordedAt)?  $default,) {final _that = this;
switch (_that) {
case _ActivityHealthRow() when $default != null:
return $default(_that.activityId,_that.startTime,_that.endTime,_that.durationMinutes,_that.locationLabel,_that.source,_that.steps,_that.distanceMeters,_that.activeCalories,_that.avgHeartRate,_that.maxHeartRate,_that.minHeartRate,_that.hrvSdnnMs,_that.hrvRmssdMs,_that.hrZoneEasySeconds,_that.hrZoneModerateSeconds,_that.hrZoneHardSeconds,_that.trainingLoad,_that.effortScore,_that.workoutType,_that.recordedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ActivityHealthRow implements ActivityHealthRow {
  const _ActivityHealthRow({@JsonKey(name: 'activity_id') required this.activityId, @JsonKey(name: 'start_time') required this.startTime, @JsonKey(name: 'end_time') this.endTime, @JsonKey(name: 'duration_minutes') this.durationMinutes, @JsonKey(name: 'location_label') this.locationLabel, required this.source, this.steps, @JsonKey(name: 'distance_meters') this.distanceMeters, @JsonKey(name: 'active_calories') this.activeCalories, @JsonKey(name: 'avg_heart_rate') this.avgHeartRate, @JsonKey(name: 'max_heart_rate') this.maxHeartRate, @JsonKey(name: 'min_heart_rate') this.minHeartRate, @JsonKey(name: 'hrv_sdnn_ms') this.hrvSdnnMs, @JsonKey(name: 'hrv_rmssd_ms') this.hrvRmssdMs, @JsonKey(name: 'hr_zone_easy_seconds') this.hrZoneEasySeconds, @JsonKey(name: 'hr_zone_moderate_seconds') this.hrZoneModerateSeconds, @JsonKey(name: 'hr_zone_hard_seconds') this.hrZoneHardSeconds, @JsonKey(name: 'training_load') this.trainingLoad, @JsonKey(name: 'effort_score') this.effortScore, @JsonKey(name: 'workout_type') this.workoutType, @JsonKey(name: 'recorded_at') this.recordedAt});
  factory _ActivityHealthRow.fromJson(Map<String, dynamic> json) => _$ActivityHealthRowFromJson(json);

@override@JsonKey(name: 'activity_id') final  String activityId;
@override@JsonKey(name: 'start_time') final  DateTime startTime;
@override@JsonKey(name: 'end_time') final  DateTime? endTime;
@override@JsonKey(name: 'duration_minutes') final  int? durationMinutes;
@override@JsonKey(name: 'location_label') final  String? locationLabel;
@override final  String source;
@override final  int? steps;
@override@JsonKey(name: 'distance_meters') final  double? distanceMeters;
@override@JsonKey(name: 'active_calories') final  double? activeCalories;
@override@JsonKey(name: 'avg_heart_rate') final  int? avgHeartRate;
@override@JsonKey(name: 'max_heart_rate') final  int? maxHeartRate;
@override@JsonKey(name: 'min_heart_rate') final  int? minHeartRate;
@override@JsonKey(name: 'hrv_sdnn_ms') final  double? hrvSdnnMs;
@override@JsonKey(name: 'hrv_rmssd_ms') final  double? hrvRmssdMs;
@override@JsonKey(name: 'hr_zone_easy_seconds') final  int? hrZoneEasySeconds;
@override@JsonKey(name: 'hr_zone_moderate_seconds') final  int? hrZoneModerateSeconds;
@override@JsonKey(name: 'hr_zone_hard_seconds') final  int? hrZoneHardSeconds;
@override@JsonKey(name: 'training_load') final  double? trainingLoad;
@override@JsonKey(name: 'effort_score') final  double? effortScore;
@override@JsonKey(name: 'workout_type') final  String? workoutType;
@override@JsonKey(name: 'recorded_at') final  DateTime? recordedAt;

/// Create a copy of ActivityHealthRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActivityHealthRowCopyWith<_ActivityHealthRow> get copyWith => __$ActivityHealthRowCopyWithImpl<_ActivityHealthRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ActivityHealthRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActivityHealthRow&&(identical(other.activityId, activityId) || other.activityId == activityId)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.durationMinutes, durationMinutes) || other.durationMinutes == durationMinutes)&&(identical(other.locationLabel, locationLabel) || other.locationLabel == locationLabel)&&(identical(other.source, source) || other.source == source)&&(identical(other.steps, steps) || other.steps == steps)&&(identical(other.distanceMeters, distanceMeters) || other.distanceMeters == distanceMeters)&&(identical(other.activeCalories, activeCalories) || other.activeCalories == activeCalories)&&(identical(other.avgHeartRate, avgHeartRate) || other.avgHeartRate == avgHeartRate)&&(identical(other.maxHeartRate, maxHeartRate) || other.maxHeartRate == maxHeartRate)&&(identical(other.minHeartRate, minHeartRate) || other.minHeartRate == minHeartRate)&&(identical(other.hrvSdnnMs, hrvSdnnMs) || other.hrvSdnnMs == hrvSdnnMs)&&(identical(other.hrvRmssdMs, hrvRmssdMs) || other.hrvRmssdMs == hrvRmssdMs)&&(identical(other.hrZoneEasySeconds, hrZoneEasySeconds) || other.hrZoneEasySeconds == hrZoneEasySeconds)&&(identical(other.hrZoneModerateSeconds, hrZoneModerateSeconds) || other.hrZoneModerateSeconds == hrZoneModerateSeconds)&&(identical(other.hrZoneHardSeconds, hrZoneHardSeconds) || other.hrZoneHardSeconds == hrZoneHardSeconds)&&(identical(other.trainingLoad, trainingLoad) || other.trainingLoad == trainingLoad)&&(identical(other.effortScore, effortScore) || other.effortScore == effortScore)&&(identical(other.workoutType, workoutType) || other.workoutType == workoutType)&&(identical(other.recordedAt, recordedAt) || other.recordedAt == recordedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,activityId,startTime,endTime,durationMinutes,locationLabel,source,steps,distanceMeters,activeCalories,avgHeartRate,maxHeartRate,minHeartRate,hrvSdnnMs,hrvRmssdMs,hrZoneEasySeconds,hrZoneModerateSeconds,hrZoneHardSeconds,trainingLoad,effortScore,workoutType,recordedAt]);

@override
String toString() {
  return 'ActivityHealthRow(activityId: $activityId, startTime: $startTime, endTime: $endTime, durationMinutes: $durationMinutes, locationLabel: $locationLabel, source: $source, steps: $steps, distanceMeters: $distanceMeters, activeCalories: $activeCalories, avgHeartRate: $avgHeartRate, maxHeartRate: $maxHeartRate, minHeartRate: $minHeartRate, hrvSdnnMs: $hrvSdnnMs, hrvRmssdMs: $hrvRmssdMs, hrZoneEasySeconds: $hrZoneEasySeconds, hrZoneModerateSeconds: $hrZoneModerateSeconds, hrZoneHardSeconds: $hrZoneHardSeconds, trainingLoad: $trainingLoad, effortScore: $effortScore, workoutType: $workoutType, recordedAt: $recordedAt)';
}


}

/// @nodoc
abstract mixin class _$ActivityHealthRowCopyWith<$Res> implements $ActivityHealthRowCopyWith<$Res> {
  factory _$ActivityHealthRowCopyWith(_ActivityHealthRow value, $Res Function(_ActivityHealthRow) _then) = __$ActivityHealthRowCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'activity_id') String activityId,@JsonKey(name: 'start_time') DateTime startTime,@JsonKey(name: 'end_time') DateTime? endTime,@JsonKey(name: 'duration_minutes') int? durationMinutes,@JsonKey(name: 'location_label') String? locationLabel, String source, int? steps,@JsonKey(name: 'distance_meters') double? distanceMeters,@JsonKey(name: 'active_calories') double? activeCalories,@JsonKey(name: 'avg_heart_rate') int? avgHeartRate,@JsonKey(name: 'max_heart_rate') int? maxHeartRate,@JsonKey(name: 'min_heart_rate') int? minHeartRate,@JsonKey(name: 'hrv_sdnn_ms') double? hrvSdnnMs,@JsonKey(name: 'hrv_rmssd_ms') double? hrvRmssdMs,@JsonKey(name: 'hr_zone_easy_seconds') int? hrZoneEasySeconds,@JsonKey(name: 'hr_zone_moderate_seconds') int? hrZoneModerateSeconds,@JsonKey(name: 'hr_zone_hard_seconds') int? hrZoneHardSeconds,@JsonKey(name: 'training_load') double? trainingLoad,@JsonKey(name: 'effort_score') double? effortScore,@JsonKey(name: 'workout_type') String? workoutType,@JsonKey(name: 'recorded_at') DateTime? recordedAt
});




}
/// @nodoc
class __$ActivityHealthRowCopyWithImpl<$Res>
    implements _$ActivityHealthRowCopyWith<$Res> {
  __$ActivityHealthRowCopyWithImpl(this._self, this._then);

  final _ActivityHealthRow _self;
  final $Res Function(_ActivityHealthRow) _then;

/// Create a copy of ActivityHealthRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? activityId = null,Object? startTime = null,Object? endTime = freezed,Object? durationMinutes = freezed,Object? locationLabel = freezed,Object? source = null,Object? steps = freezed,Object? distanceMeters = freezed,Object? activeCalories = freezed,Object? avgHeartRate = freezed,Object? maxHeartRate = freezed,Object? minHeartRate = freezed,Object? hrvSdnnMs = freezed,Object? hrvRmssdMs = freezed,Object? hrZoneEasySeconds = freezed,Object? hrZoneModerateSeconds = freezed,Object? hrZoneHardSeconds = freezed,Object? trainingLoad = freezed,Object? effortScore = freezed,Object? workoutType = freezed,Object? recordedAt = freezed,}) {
  return _then(_ActivityHealthRow(
activityId: null == activityId ? _self.activityId : activityId // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,endTime: freezed == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as DateTime?,durationMinutes: freezed == durationMinutes ? _self.durationMinutes : durationMinutes // ignore: cast_nullable_to_non_nullable
as int?,locationLabel: freezed == locationLabel ? _self.locationLabel : locationLabel // ignore: cast_nullable_to_non_nullable
as String?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,steps: freezed == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as int?,distanceMeters: freezed == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as double?,activeCalories: freezed == activeCalories ? _self.activeCalories : activeCalories // ignore: cast_nullable_to_non_nullable
as double?,avgHeartRate: freezed == avgHeartRate ? _self.avgHeartRate : avgHeartRate // ignore: cast_nullable_to_non_nullable
as int?,maxHeartRate: freezed == maxHeartRate ? _self.maxHeartRate : maxHeartRate // ignore: cast_nullable_to_non_nullable
as int?,minHeartRate: freezed == minHeartRate ? _self.minHeartRate : minHeartRate // ignore: cast_nullable_to_non_nullable
as int?,hrvSdnnMs: freezed == hrvSdnnMs ? _self.hrvSdnnMs : hrvSdnnMs // ignore: cast_nullable_to_non_nullable
as double?,hrvRmssdMs: freezed == hrvRmssdMs ? _self.hrvRmssdMs : hrvRmssdMs // ignore: cast_nullable_to_non_nullable
as double?,hrZoneEasySeconds: freezed == hrZoneEasySeconds ? _self.hrZoneEasySeconds : hrZoneEasySeconds // ignore: cast_nullable_to_non_nullable
as int?,hrZoneModerateSeconds: freezed == hrZoneModerateSeconds ? _self.hrZoneModerateSeconds : hrZoneModerateSeconds // ignore: cast_nullable_to_non_nullable
as int?,hrZoneHardSeconds: freezed == hrZoneHardSeconds ? _self.hrZoneHardSeconds : hrZoneHardSeconds // ignore: cast_nullable_to_non_nullable
as int?,trainingLoad: freezed == trainingLoad ? _self.trainingLoad : trainingLoad // ignore: cast_nullable_to_non_nullable
as double?,effortScore: freezed == effortScore ? _self.effortScore : effortScore // ignore: cast_nullable_to_non_nullable
as double?,workoutType: freezed == workoutType ? _self.workoutType : workoutType // ignore: cast_nullable_to_non_nullable
as String?,recordedAt: freezed == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
