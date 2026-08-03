// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_health_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DailyHealthSummary {

@JsonKey(name: 'user_id') String get userId; DateTime get date;@JsonKey(name: 'resting_heart_rate') int? get restingHeartRate;@JsonKey(name: 'hrv_sdnn_ms') double? get hrvSdnnMs;@JsonKey(name: 'hrv_rmssd_ms') double? get hrvRmssdMs; int? get steps;@JsonKey(name: 'distance_meters') double? get distanceMeters;@JsonKey(name: 'active_calories') double? get activeCalories;@JsonKey(name: 'total_calories') double? get totalCalories;@JsonKey(name: 'sleep_minutes') int? get sleepMinutes;@JsonKey(name: 'sleep_quality_score') double? get sleepQualityScore;@JsonKey(name: 'weight_kg') double? get weightKg;@JsonKey(name: 'activity_count') int get activityCount;@JsonKey(name: 'total_activity_minutes') int get totalActivityMinutes;@JsonKey(name: 'synced_at') DateTime? get syncedAt;
/// Create a copy of DailyHealthSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyHealthSummaryCopyWith<DailyHealthSummary> get copyWith => _$DailyHealthSummaryCopyWithImpl<DailyHealthSummary>(this as DailyHealthSummary, _$identity);

  /// Serializes this DailyHealthSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyHealthSummary&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.date, date) || other.date == date)&&(identical(other.restingHeartRate, restingHeartRate) || other.restingHeartRate == restingHeartRate)&&(identical(other.hrvSdnnMs, hrvSdnnMs) || other.hrvSdnnMs == hrvSdnnMs)&&(identical(other.hrvRmssdMs, hrvRmssdMs) || other.hrvRmssdMs == hrvRmssdMs)&&(identical(other.steps, steps) || other.steps == steps)&&(identical(other.distanceMeters, distanceMeters) || other.distanceMeters == distanceMeters)&&(identical(other.activeCalories, activeCalories) || other.activeCalories == activeCalories)&&(identical(other.totalCalories, totalCalories) || other.totalCalories == totalCalories)&&(identical(other.sleepMinutes, sleepMinutes) || other.sleepMinutes == sleepMinutes)&&(identical(other.sleepQualityScore, sleepQualityScore) || other.sleepQualityScore == sleepQualityScore)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.activityCount, activityCount) || other.activityCount == activityCount)&&(identical(other.totalActivityMinutes, totalActivityMinutes) || other.totalActivityMinutes == totalActivityMinutes)&&(identical(other.syncedAt, syncedAt) || other.syncedAt == syncedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,date,restingHeartRate,hrvSdnnMs,hrvRmssdMs,steps,distanceMeters,activeCalories,totalCalories,sleepMinutes,sleepQualityScore,weightKg,activityCount,totalActivityMinutes,syncedAt);

@override
String toString() {
  return 'DailyHealthSummary(userId: $userId, date: $date, restingHeartRate: $restingHeartRate, hrvSdnnMs: $hrvSdnnMs, hrvRmssdMs: $hrvRmssdMs, steps: $steps, distanceMeters: $distanceMeters, activeCalories: $activeCalories, totalCalories: $totalCalories, sleepMinutes: $sleepMinutes, sleepQualityScore: $sleepQualityScore, weightKg: $weightKg, activityCount: $activityCount, totalActivityMinutes: $totalActivityMinutes, syncedAt: $syncedAt)';
}


}

/// @nodoc
abstract mixin class $DailyHealthSummaryCopyWith<$Res>  {
  factory $DailyHealthSummaryCopyWith(DailyHealthSummary value, $Res Function(DailyHealthSummary) _then) = _$DailyHealthSummaryCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'user_id') String userId, DateTime date,@JsonKey(name: 'resting_heart_rate') int? restingHeartRate,@JsonKey(name: 'hrv_sdnn_ms') double? hrvSdnnMs,@JsonKey(name: 'hrv_rmssd_ms') double? hrvRmssdMs, int? steps,@JsonKey(name: 'distance_meters') double? distanceMeters,@JsonKey(name: 'active_calories') double? activeCalories,@JsonKey(name: 'total_calories') double? totalCalories,@JsonKey(name: 'sleep_minutes') int? sleepMinutes,@JsonKey(name: 'sleep_quality_score') double? sleepQualityScore,@JsonKey(name: 'weight_kg') double? weightKg,@JsonKey(name: 'activity_count') int activityCount,@JsonKey(name: 'total_activity_minutes') int totalActivityMinutes,@JsonKey(name: 'synced_at') DateTime? syncedAt
});




}
/// @nodoc
class _$DailyHealthSummaryCopyWithImpl<$Res>
    implements $DailyHealthSummaryCopyWith<$Res> {
  _$DailyHealthSummaryCopyWithImpl(this._self, this._then);

  final DailyHealthSummary _self;
  final $Res Function(DailyHealthSummary) _then;

/// Create a copy of DailyHealthSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? date = null,Object? restingHeartRate = freezed,Object? hrvSdnnMs = freezed,Object? hrvRmssdMs = freezed,Object? steps = freezed,Object? distanceMeters = freezed,Object? activeCalories = freezed,Object? totalCalories = freezed,Object? sleepMinutes = freezed,Object? sleepQualityScore = freezed,Object? weightKg = freezed,Object? activityCount = null,Object? totalActivityMinutes = null,Object? syncedAt = freezed,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,restingHeartRate: freezed == restingHeartRate ? _self.restingHeartRate : restingHeartRate // ignore: cast_nullable_to_non_nullable
as int?,hrvSdnnMs: freezed == hrvSdnnMs ? _self.hrvSdnnMs : hrvSdnnMs // ignore: cast_nullable_to_non_nullable
as double?,hrvRmssdMs: freezed == hrvRmssdMs ? _self.hrvRmssdMs : hrvRmssdMs // ignore: cast_nullable_to_non_nullable
as double?,steps: freezed == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as int?,distanceMeters: freezed == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as double?,activeCalories: freezed == activeCalories ? _self.activeCalories : activeCalories // ignore: cast_nullable_to_non_nullable
as double?,totalCalories: freezed == totalCalories ? _self.totalCalories : totalCalories // ignore: cast_nullable_to_non_nullable
as double?,sleepMinutes: freezed == sleepMinutes ? _self.sleepMinutes : sleepMinutes // ignore: cast_nullable_to_non_nullable
as int?,sleepQualityScore: freezed == sleepQualityScore ? _self.sleepQualityScore : sleepQualityScore // ignore: cast_nullable_to_non_nullable
as double?,weightKg: freezed == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double?,activityCount: null == activityCount ? _self.activityCount : activityCount // ignore: cast_nullable_to_non_nullable
as int,totalActivityMinutes: null == totalActivityMinutes ? _self.totalActivityMinutes : totalActivityMinutes // ignore: cast_nullable_to_non_nullable
as int,syncedAt: freezed == syncedAt ? _self.syncedAt : syncedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [DailyHealthSummary].
extension DailyHealthSummaryPatterns on DailyHealthSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DailyHealthSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DailyHealthSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DailyHealthSummary value)  $default,){
final _that = this;
switch (_that) {
case _DailyHealthSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DailyHealthSummary value)?  $default,){
final _that = this;
switch (_that) {
case _DailyHealthSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'user_id')  String userId,  DateTime date, @JsonKey(name: 'resting_heart_rate')  int? restingHeartRate, @JsonKey(name: 'hrv_sdnn_ms')  double? hrvSdnnMs, @JsonKey(name: 'hrv_rmssd_ms')  double? hrvRmssdMs,  int? steps, @JsonKey(name: 'distance_meters')  double? distanceMeters, @JsonKey(name: 'active_calories')  double? activeCalories, @JsonKey(name: 'total_calories')  double? totalCalories, @JsonKey(name: 'sleep_minutes')  int? sleepMinutes, @JsonKey(name: 'sleep_quality_score')  double? sleepQualityScore, @JsonKey(name: 'weight_kg')  double? weightKg, @JsonKey(name: 'activity_count')  int activityCount, @JsonKey(name: 'total_activity_minutes')  int totalActivityMinutes, @JsonKey(name: 'synced_at')  DateTime? syncedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DailyHealthSummary() when $default != null:
return $default(_that.userId,_that.date,_that.restingHeartRate,_that.hrvSdnnMs,_that.hrvRmssdMs,_that.steps,_that.distanceMeters,_that.activeCalories,_that.totalCalories,_that.sleepMinutes,_that.sleepQualityScore,_that.weightKg,_that.activityCount,_that.totalActivityMinutes,_that.syncedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'user_id')  String userId,  DateTime date, @JsonKey(name: 'resting_heart_rate')  int? restingHeartRate, @JsonKey(name: 'hrv_sdnn_ms')  double? hrvSdnnMs, @JsonKey(name: 'hrv_rmssd_ms')  double? hrvRmssdMs,  int? steps, @JsonKey(name: 'distance_meters')  double? distanceMeters, @JsonKey(name: 'active_calories')  double? activeCalories, @JsonKey(name: 'total_calories')  double? totalCalories, @JsonKey(name: 'sleep_minutes')  int? sleepMinutes, @JsonKey(name: 'sleep_quality_score')  double? sleepQualityScore, @JsonKey(name: 'weight_kg')  double? weightKg, @JsonKey(name: 'activity_count')  int activityCount, @JsonKey(name: 'total_activity_minutes')  int totalActivityMinutes, @JsonKey(name: 'synced_at')  DateTime? syncedAt)  $default,) {final _that = this;
switch (_that) {
case _DailyHealthSummary():
return $default(_that.userId,_that.date,_that.restingHeartRate,_that.hrvSdnnMs,_that.hrvRmssdMs,_that.steps,_that.distanceMeters,_that.activeCalories,_that.totalCalories,_that.sleepMinutes,_that.sleepQualityScore,_that.weightKg,_that.activityCount,_that.totalActivityMinutes,_that.syncedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'user_id')  String userId,  DateTime date, @JsonKey(name: 'resting_heart_rate')  int? restingHeartRate, @JsonKey(name: 'hrv_sdnn_ms')  double? hrvSdnnMs, @JsonKey(name: 'hrv_rmssd_ms')  double? hrvRmssdMs,  int? steps, @JsonKey(name: 'distance_meters')  double? distanceMeters, @JsonKey(name: 'active_calories')  double? activeCalories, @JsonKey(name: 'total_calories')  double? totalCalories, @JsonKey(name: 'sleep_minutes')  int? sleepMinutes, @JsonKey(name: 'sleep_quality_score')  double? sleepQualityScore, @JsonKey(name: 'weight_kg')  double? weightKg, @JsonKey(name: 'activity_count')  int activityCount, @JsonKey(name: 'total_activity_minutes')  int totalActivityMinutes, @JsonKey(name: 'synced_at')  DateTime? syncedAt)?  $default,) {final _that = this;
switch (_that) {
case _DailyHealthSummary() when $default != null:
return $default(_that.userId,_that.date,_that.restingHeartRate,_that.hrvSdnnMs,_that.hrvRmssdMs,_that.steps,_that.distanceMeters,_that.activeCalories,_that.totalCalories,_that.sleepMinutes,_that.sleepQualityScore,_that.weightKg,_that.activityCount,_that.totalActivityMinutes,_that.syncedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DailyHealthSummary implements DailyHealthSummary {
  const _DailyHealthSummary({@JsonKey(name: 'user_id') required this.userId, required this.date, @JsonKey(name: 'resting_heart_rate') this.restingHeartRate, @JsonKey(name: 'hrv_sdnn_ms') this.hrvSdnnMs, @JsonKey(name: 'hrv_rmssd_ms') this.hrvRmssdMs, this.steps, @JsonKey(name: 'distance_meters') this.distanceMeters, @JsonKey(name: 'active_calories') this.activeCalories, @JsonKey(name: 'total_calories') this.totalCalories, @JsonKey(name: 'sleep_minutes') this.sleepMinutes, @JsonKey(name: 'sleep_quality_score') this.sleepQualityScore, @JsonKey(name: 'weight_kg') this.weightKg, @JsonKey(name: 'activity_count') this.activityCount = 0, @JsonKey(name: 'total_activity_minutes') this.totalActivityMinutes = 0, @JsonKey(name: 'synced_at') this.syncedAt});
  factory _DailyHealthSummary.fromJson(Map<String, dynamic> json) => _$DailyHealthSummaryFromJson(json);

@override@JsonKey(name: 'user_id') final  String userId;
@override final  DateTime date;
@override@JsonKey(name: 'resting_heart_rate') final  int? restingHeartRate;
@override@JsonKey(name: 'hrv_sdnn_ms') final  double? hrvSdnnMs;
@override@JsonKey(name: 'hrv_rmssd_ms') final  double? hrvRmssdMs;
@override final  int? steps;
@override@JsonKey(name: 'distance_meters') final  double? distanceMeters;
@override@JsonKey(name: 'active_calories') final  double? activeCalories;
@override@JsonKey(name: 'total_calories') final  double? totalCalories;
@override@JsonKey(name: 'sleep_minutes') final  int? sleepMinutes;
@override@JsonKey(name: 'sleep_quality_score') final  double? sleepQualityScore;
@override@JsonKey(name: 'weight_kg') final  double? weightKg;
@override@JsonKey(name: 'activity_count') final  int activityCount;
@override@JsonKey(name: 'total_activity_minutes') final  int totalActivityMinutes;
@override@JsonKey(name: 'synced_at') final  DateTime? syncedAt;

/// Create a copy of DailyHealthSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DailyHealthSummaryCopyWith<_DailyHealthSummary> get copyWith => __$DailyHealthSummaryCopyWithImpl<_DailyHealthSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DailyHealthSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DailyHealthSummary&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.date, date) || other.date == date)&&(identical(other.restingHeartRate, restingHeartRate) || other.restingHeartRate == restingHeartRate)&&(identical(other.hrvSdnnMs, hrvSdnnMs) || other.hrvSdnnMs == hrvSdnnMs)&&(identical(other.hrvRmssdMs, hrvRmssdMs) || other.hrvRmssdMs == hrvRmssdMs)&&(identical(other.steps, steps) || other.steps == steps)&&(identical(other.distanceMeters, distanceMeters) || other.distanceMeters == distanceMeters)&&(identical(other.activeCalories, activeCalories) || other.activeCalories == activeCalories)&&(identical(other.totalCalories, totalCalories) || other.totalCalories == totalCalories)&&(identical(other.sleepMinutes, sleepMinutes) || other.sleepMinutes == sleepMinutes)&&(identical(other.sleepQualityScore, sleepQualityScore) || other.sleepQualityScore == sleepQualityScore)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.activityCount, activityCount) || other.activityCount == activityCount)&&(identical(other.totalActivityMinutes, totalActivityMinutes) || other.totalActivityMinutes == totalActivityMinutes)&&(identical(other.syncedAt, syncedAt) || other.syncedAt == syncedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,date,restingHeartRate,hrvSdnnMs,hrvRmssdMs,steps,distanceMeters,activeCalories,totalCalories,sleepMinutes,sleepQualityScore,weightKg,activityCount,totalActivityMinutes,syncedAt);

@override
String toString() {
  return 'DailyHealthSummary(userId: $userId, date: $date, restingHeartRate: $restingHeartRate, hrvSdnnMs: $hrvSdnnMs, hrvRmssdMs: $hrvRmssdMs, steps: $steps, distanceMeters: $distanceMeters, activeCalories: $activeCalories, totalCalories: $totalCalories, sleepMinutes: $sleepMinutes, sleepQualityScore: $sleepQualityScore, weightKg: $weightKg, activityCount: $activityCount, totalActivityMinutes: $totalActivityMinutes, syncedAt: $syncedAt)';
}


}

/// @nodoc
abstract mixin class _$DailyHealthSummaryCopyWith<$Res> implements $DailyHealthSummaryCopyWith<$Res> {
  factory _$DailyHealthSummaryCopyWith(_DailyHealthSummary value, $Res Function(_DailyHealthSummary) _then) = __$DailyHealthSummaryCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'user_id') String userId, DateTime date,@JsonKey(name: 'resting_heart_rate') int? restingHeartRate,@JsonKey(name: 'hrv_sdnn_ms') double? hrvSdnnMs,@JsonKey(name: 'hrv_rmssd_ms') double? hrvRmssdMs, int? steps,@JsonKey(name: 'distance_meters') double? distanceMeters,@JsonKey(name: 'active_calories') double? activeCalories,@JsonKey(name: 'total_calories') double? totalCalories,@JsonKey(name: 'sleep_minutes') int? sleepMinutes,@JsonKey(name: 'sleep_quality_score') double? sleepQualityScore,@JsonKey(name: 'weight_kg') double? weightKg,@JsonKey(name: 'activity_count') int activityCount,@JsonKey(name: 'total_activity_minutes') int totalActivityMinutes,@JsonKey(name: 'synced_at') DateTime? syncedAt
});




}
/// @nodoc
class __$DailyHealthSummaryCopyWithImpl<$Res>
    implements _$DailyHealthSummaryCopyWith<$Res> {
  __$DailyHealthSummaryCopyWithImpl(this._self, this._then);

  final _DailyHealthSummary _self;
  final $Res Function(_DailyHealthSummary) _then;

/// Create a copy of DailyHealthSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? date = null,Object? restingHeartRate = freezed,Object? hrvSdnnMs = freezed,Object? hrvRmssdMs = freezed,Object? steps = freezed,Object? distanceMeters = freezed,Object? activeCalories = freezed,Object? totalCalories = freezed,Object? sleepMinutes = freezed,Object? sleepQualityScore = freezed,Object? weightKg = freezed,Object? activityCount = null,Object? totalActivityMinutes = null,Object? syncedAt = freezed,}) {
  return _then(_DailyHealthSummary(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,restingHeartRate: freezed == restingHeartRate ? _self.restingHeartRate : restingHeartRate // ignore: cast_nullable_to_non_nullable
as int?,hrvSdnnMs: freezed == hrvSdnnMs ? _self.hrvSdnnMs : hrvSdnnMs // ignore: cast_nullable_to_non_nullable
as double?,hrvRmssdMs: freezed == hrvRmssdMs ? _self.hrvRmssdMs : hrvRmssdMs // ignore: cast_nullable_to_non_nullable
as double?,steps: freezed == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as int?,distanceMeters: freezed == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as double?,activeCalories: freezed == activeCalories ? _self.activeCalories : activeCalories // ignore: cast_nullable_to_non_nullable
as double?,totalCalories: freezed == totalCalories ? _self.totalCalories : totalCalories // ignore: cast_nullable_to_non_nullable
as double?,sleepMinutes: freezed == sleepMinutes ? _self.sleepMinutes : sleepMinutes // ignore: cast_nullable_to_non_nullable
as int?,sleepQualityScore: freezed == sleepQualityScore ? _self.sleepQualityScore : sleepQualityScore // ignore: cast_nullable_to_non_nullable
as double?,weightKg: freezed == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double?,activityCount: null == activityCount ? _self.activityCount : activityCount // ignore: cast_nullable_to_non_nullable
as int,totalActivityMinutes: null == totalActivityMinutes ? _self.totalActivityMinutes : totalActivityMinutes // ignore: cast_nullable_to_non_nullable
as int,syncedAt: freezed == syncedAt ? _self.syncedAt : syncedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
