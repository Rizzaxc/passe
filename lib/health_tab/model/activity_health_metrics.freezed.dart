// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'activity_health_metrics.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ActivityHealthMetrics {

 String? get id;@JsonKey(name: 'user_id') String get userId;@JsonKey(name: 'activity_id') String get activityId;// Activity metrics
 int? get steps;@JsonKey(name: 'distance_meters') double? get distanceMeters;@JsonKey(name: 'active_calories') double? get activeCalories;// Heart rate aggregates
@JsonKey(name: 'avg_heart_rate') int? get avgHeartRate;@JsonKey(name: 'max_heart_rate') int? get maxHeartRate;@JsonKey(name: 'min_heart_rate') int? get minHeartRate;// HRV metrics
@JsonKey(name: 'hrv_sdnn_ms') double? get hrvSdnnMs;@JsonKey(name: 'hrv_rmssd_ms') double? get hrvRmssdMs;// HR Zone distribution (seconds)
@JsonKey(name: 'hr_zone_1_seconds') int? get hrZone1Seconds;@JsonKey(name: 'hr_zone_2_seconds') int? get hrZone2Seconds;@JsonKey(name: 'hr_zone_3_seconds') int? get hrZone3Seconds;@JsonKey(name: 'hr_zone_4_seconds') int? get hrZone4Seconds;@JsonKey(name: 'hr_zone_5_seconds') int? get hrZone5Seconds;// Derived performance metrics
@JsonKey(name: 'training_load') double? get trainingLoad;@JsonKey(name: 'effort_score') double? get effortScore;// Weight snapshot
@JsonKey(name: 'weight_kg') double? get weightKg;// Workout type from health platform
@JsonKey(name: 'workout_type') String? get workoutType;@JsonKey(name: 'recorded_at') DateTime? get recordedAt;
/// Create a copy of ActivityHealthMetrics
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActivityHealthMetricsCopyWith<ActivityHealthMetrics> get copyWith => _$ActivityHealthMetricsCopyWithImpl<ActivityHealthMetrics>(this as ActivityHealthMetrics, _$identity);

  /// Serializes this ActivityHealthMetrics to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActivityHealthMetrics&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.activityId, activityId) || other.activityId == activityId)&&(identical(other.steps, steps) || other.steps == steps)&&(identical(other.distanceMeters, distanceMeters) || other.distanceMeters == distanceMeters)&&(identical(other.activeCalories, activeCalories) || other.activeCalories == activeCalories)&&(identical(other.avgHeartRate, avgHeartRate) || other.avgHeartRate == avgHeartRate)&&(identical(other.maxHeartRate, maxHeartRate) || other.maxHeartRate == maxHeartRate)&&(identical(other.minHeartRate, minHeartRate) || other.minHeartRate == minHeartRate)&&(identical(other.hrvSdnnMs, hrvSdnnMs) || other.hrvSdnnMs == hrvSdnnMs)&&(identical(other.hrvRmssdMs, hrvRmssdMs) || other.hrvRmssdMs == hrvRmssdMs)&&(identical(other.hrZone1Seconds, hrZone1Seconds) || other.hrZone1Seconds == hrZone1Seconds)&&(identical(other.hrZone2Seconds, hrZone2Seconds) || other.hrZone2Seconds == hrZone2Seconds)&&(identical(other.hrZone3Seconds, hrZone3Seconds) || other.hrZone3Seconds == hrZone3Seconds)&&(identical(other.hrZone4Seconds, hrZone4Seconds) || other.hrZone4Seconds == hrZone4Seconds)&&(identical(other.hrZone5Seconds, hrZone5Seconds) || other.hrZone5Seconds == hrZone5Seconds)&&(identical(other.trainingLoad, trainingLoad) || other.trainingLoad == trainingLoad)&&(identical(other.effortScore, effortScore) || other.effortScore == effortScore)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.workoutType, workoutType) || other.workoutType == workoutType)&&(identical(other.recordedAt, recordedAt) || other.recordedAt == recordedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,userId,activityId,steps,distanceMeters,activeCalories,avgHeartRate,maxHeartRate,minHeartRate,hrvSdnnMs,hrvRmssdMs,hrZone1Seconds,hrZone2Seconds,hrZone3Seconds,hrZone4Seconds,hrZone5Seconds,trainingLoad,effortScore,weightKg,workoutType,recordedAt]);

@override
String toString() {
  return 'ActivityHealthMetrics(id: $id, userId: $userId, activityId: $activityId, steps: $steps, distanceMeters: $distanceMeters, activeCalories: $activeCalories, avgHeartRate: $avgHeartRate, maxHeartRate: $maxHeartRate, minHeartRate: $minHeartRate, hrvSdnnMs: $hrvSdnnMs, hrvRmssdMs: $hrvRmssdMs, hrZone1Seconds: $hrZone1Seconds, hrZone2Seconds: $hrZone2Seconds, hrZone3Seconds: $hrZone3Seconds, hrZone4Seconds: $hrZone4Seconds, hrZone5Seconds: $hrZone5Seconds, trainingLoad: $trainingLoad, effortScore: $effortScore, weightKg: $weightKg, workoutType: $workoutType, recordedAt: $recordedAt)';
}


}

/// @nodoc
abstract mixin class $ActivityHealthMetricsCopyWith<$Res>  {
  factory $ActivityHealthMetricsCopyWith(ActivityHealthMetrics value, $Res Function(ActivityHealthMetrics) _then) = _$ActivityHealthMetricsCopyWithImpl;
@useResult
$Res call({
 String? id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'activity_id') String activityId, int? steps,@JsonKey(name: 'distance_meters') double? distanceMeters,@JsonKey(name: 'active_calories') double? activeCalories,@JsonKey(name: 'avg_heart_rate') int? avgHeartRate,@JsonKey(name: 'max_heart_rate') int? maxHeartRate,@JsonKey(name: 'min_heart_rate') int? minHeartRate,@JsonKey(name: 'hrv_sdnn_ms') double? hrvSdnnMs,@JsonKey(name: 'hrv_rmssd_ms') double? hrvRmssdMs,@JsonKey(name: 'hr_zone_1_seconds') int? hrZone1Seconds,@JsonKey(name: 'hr_zone_2_seconds') int? hrZone2Seconds,@JsonKey(name: 'hr_zone_3_seconds') int? hrZone3Seconds,@JsonKey(name: 'hr_zone_4_seconds') int? hrZone4Seconds,@JsonKey(name: 'hr_zone_5_seconds') int? hrZone5Seconds,@JsonKey(name: 'training_load') double? trainingLoad,@JsonKey(name: 'effort_score') double? effortScore,@JsonKey(name: 'weight_kg') double? weightKg,@JsonKey(name: 'workout_type') String? workoutType,@JsonKey(name: 'recorded_at') DateTime? recordedAt
});




}
/// @nodoc
class _$ActivityHealthMetricsCopyWithImpl<$Res>
    implements $ActivityHealthMetricsCopyWith<$Res> {
  _$ActivityHealthMetricsCopyWithImpl(this._self, this._then);

  final ActivityHealthMetrics _self;
  final $Res Function(ActivityHealthMetrics) _then;

/// Create a copy of ActivityHealthMetrics
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? userId = null,Object? activityId = null,Object? steps = freezed,Object? distanceMeters = freezed,Object? activeCalories = freezed,Object? avgHeartRate = freezed,Object? maxHeartRate = freezed,Object? minHeartRate = freezed,Object? hrvSdnnMs = freezed,Object? hrvRmssdMs = freezed,Object? hrZone1Seconds = freezed,Object? hrZone2Seconds = freezed,Object? hrZone3Seconds = freezed,Object? hrZone4Seconds = freezed,Object? hrZone5Seconds = freezed,Object? trainingLoad = freezed,Object? effortScore = freezed,Object? weightKg = freezed,Object? workoutType = freezed,Object? recordedAt = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,activityId: null == activityId ? _self.activityId : activityId // ignore: cast_nullable_to_non_nullable
as String,steps: freezed == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as int?,distanceMeters: freezed == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as double?,activeCalories: freezed == activeCalories ? _self.activeCalories : activeCalories // ignore: cast_nullable_to_non_nullable
as double?,avgHeartRate: freezed == avgHeartRate ? _self.avgHeartRate : avgHeartRate // ignore: cast_nullable_to_non_nullable
as int?,maxHeartRate: freezed == maxHeartRate ? _self.maxHeartRate : maxHeartRate // ignore: cast_nullable_to_non_nullable
as int?,minHeartRate: freezed == minHeartRate ? _self.minHeartRate : minHeartRate // ignore: cast_nullable_to_non_nullable
as int?,hrvSdnnMs: freezed == hrvSdnnMs ? _self.hrvSdnnMs : hrvSdnnMs // ignore: cast_nullable_to_non_nullable
as double?,hrvRmssdMs: freezed == hrvRmssdMs ? _self.hrvRmssdMs : hrvRmssdMs // ignore: cast_nullable_to_non_nullable
as double?,hrZone1Seconds: freezed == hrZone1Seconds ? _self.hrZone1Seconds : hrZone1Seconds // ignore: cast_nullable_to_non_nullable
as int?,hrZone2Seconds: freezed == hrZone2Seconds ? _self.hrZone2Seconds : hrZone2Seconds // ignore: cast_nullable_to_non_nullable
as int?,hrZone3Seconds: freezed == hrZone3Seconds ? _self.hrZone3Seconds : hrZone3Seconds // ignore: cast_nullable_to_non_nullable
as int?,hrZone4Seconds: freezed == hrZone4Seconds ? _self.hrZone4Seconds : hrZone4Seconds // ignore: cast_nullable_to_non_nullable
as int?,hrZone5Seconds: freezed == hrZone5Seconds ? _self.hrZone5Seconds : hrZone5Seconds // ignore: cast_nullable_to_non_nullable
as int?,trainingLoad: freezed == trainingLoad ? _self.trainingLoad : trainingLoad // ignore: cast_nullable_to_non_nullable
as double?,effortScore: freezed == effortScore ? _self.effortScore : effortScore // ignore: cast_nullable_to_non_nullable
as double?,weightKg: freezed == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double?,workoutType: freezed == workoutType ? _self.workoutType : workoutType // ignore: cast_nullable_to_non_nullable
as String?,recordedAt: freezed == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ActivityHealthMetrics].
extension ActivityHealthMetricsPatterns on ActivityHealthMetrics {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActivityHealthMetrics value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActivityHealthMetrics() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActivityHealthMetrics value)  $default,){
final _that = this;
switch (_that) {
case _ActivityHealthMetrics():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActivityHealthMetrics value)?  $default,){
final _that = this;
switch (_that) {
case _ActivityHealthMetrics() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'activity_id')  String activityId,  int? steps, @JsonKey(name: 'distance_meters')  double? distanceMeters, @JsonKey(name: 'active_calories')  double? activeCalories, @JsonKey(name: 'avg_heart_rate')  int? avgHeartRate, @JsonKey(name: 'max_heart_rate')  int? maxHeartRate, @JsonKey(name: 'min_heart_rate')  int? minHeartRate, @JsonKey(name: 'hrv_sdnn_ms')  double? hrvSdnnMs, @JsonKey(name: 'hrv_rmssd_ms')  double? hrvRmssdMs, @JsonKey(name: 'hr_zone_1_seconds')  int? hrZone1Seconds, @JsonKey(name: 'hr_zone_2_seconds')  int? hrZone2Seconds, @JsonKey(name: 'hr_zone_3_seconds')  int? hrZone3Seconds, @JsonKey(name: 'hr_zone_4_seconds')  int? hrZone4Seconds, @JsonKey(name: 'hr_zone_5_seconds')  int? hrZone5Seconds, @JsonKey(name: 'training_load')  double? trainingLoad, @JsonKey(name: 'effort_score')  double? effortScore, @JsonKey(name: 'weight_kg')  double? weightKg, @JsonKey(name: 'workout_type')  String? workoutType, @JsonKey(name: 'recorded_at')  DateTime? recordedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActivityHealthMetrics() when $default != null:
return $default(_that.id,_that.userId,_that.activityId,_that.steps,_that.distanceMeters,_that.activeCalories,_that.avgHeartRate,_that.maxHeartRate,_that.minHeartRate,_that.hrvSdnnMs,_that.hrvRmssdMs,_that.hrZone1Seconds,_that.hrZone2Seconds,_that.hrZone3Seconds,_that.hrZone4Seconds,_that.hrZone5Seconds,_that.trainingLoad,_that.effortScore,_that.weightKg,_that.workoutType,_that.recordedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'activity_id')  String activityId,  int? steps, @JsonKey(name: 'distance_meters')  double? distanceMeters, @JsonKey(name: 'active_calories')  double? activeCalories, @JsonKey(name: 'avg_heart_rate')  int? avgHeartRate, @JsonKey(name: 'max_heart_rate')  int? maxHeartRate, @JsonKey(name: 'min_heart_rate')  int? minHeartRate, @JsonKey(name: 'hrv_sdnn_ms')  double? hrvSdnnMs, @JsonKey(name: 'hrv_rmssd_ms')  double? hrvRmssdMs, @JsonKey(name: 'hr_zone_1_seconds')  int? hrZone1Seconds, @JsonKey(name: 'hr_zone_2_seconds')  int? hrZone2Seconds, @JsonKey(name: 'hr_zone_3_seconds')  int? hrZone3Seconds, @JsonKey(name: 'hr_zone_4_seconds')  int? hrZone4Seconds, @JsonKey(name: 'hr_zone_5_seconds')  int? hrZone5Seconds, @JsonKey(name: 'training_load')  double? trainingLoad, @JsonKey(name: 'effort_score')  double? effortScore, @JsonKey(name: 'weight_kg')  double? weightKg, @JsonKey(name: 'workout_type')  String? workoutType, @JsonKey(name: 'recorded_at')  DateTime? recordedAt)  $default,) {final _that = this;
switch (_that) {
case _ActivityHealthMetrics():
return $default(_that.id,_that.userId,_that.activityId,_that.steps,_that.distanceMeters,_that.activeCalories,_that.avgHeartRate,_that.maxHeartRate,_that.minHeartRate,_that.hrvSdnnMs,_that.hrvRmssdMs,_that.hrZone1Seconds,_that.hrZone2Seconds,_that.hrZone3Seconds,_that.hrZone4Seconds,_that.hrZone5Seconds,_that.trainingLoad,_that.effortScore,_that.weightKg,_that.workoutType,_that.recordedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'activity_id')  String activityId,  int? steps, @JsonKey(name: 'distance_meters')  double? distanceMeters, @JsonKey(name: 'active_calories')  double? activeCalories, @JsonKey(name: 'avg_heart_rate')  int? avgHeartRate, @JsonKey(name: 'max_heart_rate')  int? maxHeartRate, @JsonKey(name: 'min_heart_rate')  int? minHeartRate, @JsonKey(name: 'hrv_sdnn_ms')  double? hrvSdnnMs, @JsonKey(name: 'hrv_rmssd_ms')  double? hrvRmssdMs, @JsonKey(name: 'hr_zone_1_seconds')  int? hrZone1Seconds, @JsonKey(name: 'hr_zone_2_seconds')  int? hrZone2Seconds, @JsonKey(name: 'hr_zone_3_seconds')  int? hrZone3Seconds, @JsonKey(name: 'hr_zone_4_seconds')  int? hrZone4Seconds, @JsonKey(name: 'hr_zone_5_seconds')  int? hrZone5Seconds, @JsonKey(name: 'training_load')  double? trainingLoad, @JsonKey(name: 'effort_score')  double? effortScore, @JsonKey(name: 'weight_kg')  double? weightKg, @JsonKey(name: 'workout_type')  String? workoutType, @JsonKey(name: 'recorded_at')  DateTime? recordedAt)?  $default,) {final _that = this;
switch (_that) {
case _ActivityHealthMetrics() when $default != null:
return $default(_that.id,_that.userId,_that.activityId,_that.steps,_that.distanceMeters,_that.activeCalories,_that.avgHeartRate,_that.maxHeartRate,_that.minHeartRate,_that.hrvSdnnMs,_that.hrvRmssdMs,_that.hrZone1Seconds,_that.hrZone2Seconds,_that.hrZone3Seconds,_that.hrZone4Seconds,_that.hrZone5Seconds,_that.trainingLoad,_that.effortScore,_that.weightKg,_that.workoutType,_that.recordedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ActivityHealthMetrics implements ActivityHealthMetrics {
  const _ActivityHealthMetrics({this.id, @JsonKey(name: 'user_id') required this.userId, @JsonKey(name: 'activity_id') required this.activityId, this.steps, @JsonKey(name: 'distance_meters') this.distanceMeters, @JsonKey(name: 'active_calories') this.activeCalories, @JsonKey(name: 'avg_heart_rate') this.avgHeartRate, @JsonKey(name: 'max_heart_rate') this.maxHeartRate, @JsonKey(name: 'min_heart_rate') this.minHeartRate, @JsonKey(name: 'hrv_sdnn_ms') this.hrvSdnnMs, @JsonKey(name: 'hrv_rmssd_ms') this.hrvRmssdMs, @JsonKey(name: 'hr_zone_1_seconds') this.hrZone1Seconds, @JsonKey(name: 'hr_zone_2_seconds') this.hrZone2Seconds, @JsonKey(name: 'hr_zone_3_seconds') this.hrZone3Seconds, @JsonKey(name: 'hr_zone_4_seconds') this.hrZone4Seconds, @JsonKey(name: 'hr_zone_5_seconds') this.hrZone5Seconds, @JsonKey(name: 'training_load') this.trainingLoad, @JsonKey(name: 'effort_score') this.effortScore, @JsonKey(name: 'weight_kg') this.weightKg, @JsonKey(name: 'workout_type') this.workoutType, @JsonKey(name: 'recorded_at') this.recordedAt});
  factory _ActivityHealthMetrics.fromJson(Map<String, dynamic> json) => _$ActivityHealthMetricsFromJson(json);

@override final  String? id;
@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey(name: 'activity_id') final  String activityId;
// Activity metrics
@override final  int? steps;
@override@JsonKey(name: 'distance_meters') final  double? distanceMeters;
@override@JsonKey(name: 'active_calories') final  double? activeCalories;
// Heart rate aggregates
@override@JsonKey(name: 'avg_heart_rate') final  int? avgHeartRate;
@override@JsonKey(name: 'max_heart_rate') final  int? maxHeartRate;
@override@JsonKey(name: 'min_heart_rate') final  int? minHeartRate;
// HRV metrics
@override@JsonKey(name: 'hrv_sdnn_ms') final  double? hrvSdnnMs;
@override@JsonKey(name: 'hrv_rmssd_ms') final  double? hrvRmssdMs;
// HR Zone distribution (seconds)
@override@JsonKey(name: 'hr_zone_1_seconds') final  int? hrZone1Seconds;
@override@JsonKey(name: 'hr_zone_2_seconds') final  int? hrZone2Seconds;
@override@JsonKey(name: 'hr_zone_3_seconds') final  int? hrZone3Seconds;
@override@JsonKey(name: 'hr_zone_4_seconds') final  int? hrZone4Seconds;
@override@JsonKey(name: 'hr_zone_5_seconds') final  int? hrZone5Seconds;
// Derived performance metrics
@override@JsonKey(name: 'training_load') final  double? trainingLoad;
@override@JsonKey(name: 'effort_score') final  double? effortScore;
// Weight snapshot
@override@JsonKey(name: 'weight_kg') final  double? weightKg;
// Workout type from health platform
@override@JsonKey(name: 'workout_type') final  String? workoutType;
@override@JsonKey(name: 'recorded_at') final  DateTime? recordedAt;

/// Create a copy of ActivityHealthMetrics
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActivityHealthMetricsCopyWith<_ActivityHealthMetrics> get copyWith => __$ActivityHealthMetricsCopyWithImpl<_ActivityHealthMetrics>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ActivityHealthMetricsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActivityHealthMetrics&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.activityId, activityId) || other.activityId == activityId)&&(identical(other.steps, steps) || other.steps == steps)&&(identical(other.distanceMeters, distanceMeters) || other.distanceMeters == distanceMeters)&&(identical(other.activeCalories, activeCalories) || other.activeCalories == activeCalories)&&(identical(other.avgHeartRate, avgHeartRate) || other.avgHeartRate == avgHeartRate)&&(identical(other.maxHeartRate, maxHeartRate) || other.maxHeartRate == maxHeartRate)&&(identical(other.minHeartRate, minHeartRate) || other.minHeartRate == minHeartRate)&&(identical(other.hrvSdnnMs, hrvSdnnMs) || other.hrvSdnnMs == hrvSdnnMs)&&(identical(other.hrvRmssdMs, hrvRmssdMs) || other.hrvRmssdMs == hrvRmssdMs)&&(identical(other.hrZone1Seconds, hrZone1Seconds) || other.hrZone1Seconds == hrZone1Seconds)&&(identical(other.hrZone2Seconds, hrZone2Seconds) || other.hrZone2Seconds == hrZone2Seconds)&&(identical(other.hrZone3Seconds, hrZone3Seconds) || other.hrZone3Seconds == hrZone3Seconds)&&(identical(other.hrZone4Seconds, hrZone4Seconds) || other.hrZone4Seconds == hrZone4Seconds)&&(identical(other.hrZone5Seconds, hrZone5Seconds) || other.hrZone5Seconds == hrZone5Seconds)&&(identical(other.trainingLoad, trainingLoad) || other.trainingLoad == trainingLoad)&&(identical(other.effortScore, effortScore) || other.effortScore == effortScore)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.workoutType, workoutType) || other.workoutType == workoutType)&&(identical(other.recordedAt, recordedAt) || other.recordedAt == recordedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,userId,activityId,steps,distanceMeters,activeCalories,avgHeartRate,maxHeartRate,minHeartRate,hrvSdnnMs,hrvRmssdMs,hrZone1Seconds,hrZone2Seconds,hrZone3Seconds,hrZone4Seconds,hrZone5Seconds,trainingLoad,effortScore,weightKg,workoutType,recordedAt]);

@override
String toString() {
  return 'ActivityHealthMetrics(id: $id, userId: $userId, activityId: $activityId, steps: $steps, distanceMeters: $distanceMeters, activeCalories: $activeCalories, avgHeartRate: $avgHeartRate, maxHeartRate: $maxHeartRate, minHeartRate: $minHeartRate, hrvSdnnMs: $hrvSdnnMs, hrvRmssdMs: $hrvRmssdMs, hrZone1Seconds: $hrZone1Seconds, hrZone2Seconds: $hrZone2Seconds, hrZone3Seconds: $hrZone3Seconds, hrZone4Seconds: $hrZone4Seconds, hrZone5Seconds: $hrZone5Seconds, trainingLoad: $trainingLoad, effortScore: $effortScore, weightKg: $weightKg, workoutType: $workoutType, recordedAt: $recordedAt)';
}


}

/// @nodoc
abstract mixin class _$ActivityHealthMetricsCopyWith<$Res> implements $ActivityHealthMetricsCopyWith<$Res> {
  factory _$ActivityHealthMetricsCopyWith(_ActivityHealthMetrics value, $Res Function(_ActivityHealthMetrics) _then) = __$ActivityHealthMetricsCopyWithImpl;
@override @useResult
$Res call({
 String? id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'activity_id') String activityId, int? steps,@JsonKey(name: 'distance_meters') double? distanceMeters,@JsonKey(name: 'active_calories') double? activeCalories,@JsonKey(name: 'avg_heart_rate') int? avgHeartRate,@JsonKey(name: 'max_heart_rate') int? maxHeartRate,@JsonKey(name: 'min_heart_rate') int? minHeartRate,@JsonKey(name: 'hrv_sdnn_ms') double? hrvSdnnMs,@JsonKey(name: 'hrv_rmssd_ms') double? hrvRmssdMs,@JsonKey(name: 'hr_zone_1_seconds') int? hrZone1Seconds,@JsonKey(name: 'hr_zone_2_seconds') int? hrZone2Seconds,@JsonKey(name: 'hr_zone_3_seconds') int? hrZone3Seconds,@JsonKey(name: 'hr_zone_4_seconds') int? hrZone4Seconds,@JsonKey(name: 'hr_zone_5_seconds') int? hrZone5Seconds,@JsonKey(name: 'training_load') double? trainingLoad,@JsonKey(name: 'effort_score') double? effortScore,@JsonKey(name: 'weight_kg') double? weightKg,@JsonKey(name: 'workout_type') String? workoutType,@JsonKey(name: 'recorded_at') DateTime? recordedAt
});




}
/// @nodoc
class __$ActivityHealthMetricsCopyWithImpl<$Res>
    implements _$ActivityHealthMetricsCopyWith<$Res> {
  __$ActivityHealthMetricsCopyWithImpl(this._self, this._then);

  final _ActivityHealthMetrics _self;
  final $Res Function(_ActivityHealthMetrics) _then;

/// Create a copy of ActivityHealthMetrics
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? userId = null,Object? activityId = null,Object? steps = freezed,Object? distanceMeters = freezed,Object? activeCalories = freezed,Object? avgHeartRate = freezed,Object? maxHeartRate = freezed,Object? minHeartRate = freezed,Object? hrvSdnnMs = freezed,Object? hrvRmssdMs = freezed,Object? hrZone1Seconds = freezed,Object? hrZone2Seconds = freezed,Object? hrZone3Seconds = freezed,Object? hrZone4Seconds = freezed,Object? hrZone5Seconds = freezed,Object? trainingLoad = freezed,Object? effortScore = freezed,Object? weightKg = freezed,Object? workoutType = freezed,Object? recordedAt = freezed,}) {
  return _then(_ActivityHealthMetrics(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,activityId: null == activityId ? _self.activityId : activityId // ignore: cast_nullable_to_non_nullable
as String,steps: freezed == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as int?,distanceMeters: freezed == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as double?,activeCalories: freezed == activeCalories ? _self.activeCalories : activeCalories // ignore: cast_nullable_to_non_nullable
as double?,avgHeartRate: freezed == avgHeartRate ? _self.avgHeartRate : avgHeartRate // ignore: cast_nullable_to_non_nullable
as int?,maxHeartRate: freezed == maxHeartRate ? _self.maxHeartRate : maxHeartRate // ignore: cast_nullable_to_non_nullable
as int?,minHeartRate: freezed == minHeartRate ? _self.minHeartRate : minHeartRate // ignore: cast_nullable_to_non_nullable
as int?,hrvSdnnMs: freezed == hrvSdnnMs ? _self.hrvSdnnMs : hrvSdnnMs // ignore: cast_nullable_to_non_nullable
as double?,hrvRmssdMs: freezed == hrvRmssdMs ? _self.hrvRmssdMs : hrvRmssdMs // ignore: cast_nullable_to_non_nullable
as double?,hrZone1Seconds: freezed == hrZone1Seconds ? _self.hrZone1Seconds : hrZone1Seconds // ignore: cast_nullable_to_non_nullable
as int?,hrZone2Seconds: freezed == hrZone2Seconds ? _self.hrZone2Seconds : hrZone2Seconds // ignore: cast_nullable_to_non_nullable
as int?,hrZone3Seconds: freezed == hrZone3Seconds ? _self.hrZone3Seconds : hrZone3Seconds // ignore: cast_nullable_to_non_nullable
as int?,hrZone4Seconds: freezed == hrZone4Seconds ? _self.hrZone4Seconds : hrZone4Seconds // ignore: cast_nullable_to_non_nullable
as int?,hrZone5Seconds: freezed == hrZone5Seconds ? _self.hrZone5Seconds : hrZone5Seconds // ignore: cast_nullable_to_non_nullable
as int?,trainingLoad: freezed == trainingLoad ? _self.trainingLoad : trainingLoad // ignore: cast_nullable_to_non_nullable
as double?,effortScore: freezed == effortScore ? _self.effortScore : effortScore // ignore: cast_nullable_to_non_nullable
as double?,weightKg: freezed == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double?,workoutType: freezed == workoutType ? _self.workoutType : workoutType // ignore: cast_nullable_to_non_nullable
as String?,recordedAt: freezed == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
