// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'achievement_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AchievementProgress {

@JsonKey(name: 'achievement_id') String get achievementId; String get code; String get name; String? get description;@JsonKey(fromJson: _toInt) int get difficulty;@JsonKey(fromJson: _toInt) int get consistency;@JsonKey(name: 'xp_reward', fromJson: _toInt) int get xpReward; bool get repeatable;@JsonKey(name: 'current_value', fromJson: _toDouble) double get currentValue;@JsonKey(fromJson: _toDouble) double get threshold;@JsonKey(fromJson: _toDouble) double get progress;@JsonKey(fromJson: _toState) AchievementState get state;@JsonKey(name: 'period_key') String get periodKey;
/// Create a copy of AchievementProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AchievementProgressCopyWith<AchievementProgress> get copyWith => _$AchievementProgressCopyWithImpl<AchievementProgress>(this as AchievementProgress, _$identity);

  /// Serializes this AchievementProgress to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AchievementProgress&&(identical(other.achievementId, achievementId) || other.achievementId == achievementId)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.difficulty, difficulty) || other.difficulty == difficulty)&&(identical(other.consistency, consistency) || other.consistency == consistency)&&(identical(other.xpReward, xpReward) || other.xpReward == xpReward)&&(identical(other.repeatable, repeatable) || other.repeatable == repeatable)&&(identical(other.currentValue, currentValue) || other.currentValue == currentValue)&&(identical(other.threshold, threshold) || other.threshold == threshold)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.state, state) || other.state == state)&&(identical(other.periodKey, periodKey) || other.periodKey == periodKey));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,achievementId,code,name,description,difficulty,consistency,xpReward,repeatable,currentValue,threshold,progress,state,periodKey);

@override
String toString() {
  return 'AchievementProgress(achievementId: $achievementId, code: $code, name: $name, description: $description, difficulty: $difficulty, consistency: $consistency, xpReward: $xpReward, repeatable: $repeatable, currentValue: $currentValue, threshold: $threshold, progress: $progress, state: $state, periodKey: $periodKey)';
}


}

/// @nodoc
abstract mixin class $AchievementProgressCopyWith<$Res>  {
  factory $AchievementProgressCopyWith(AchievementProgress value, $Res Function(AchievementProgress) _then) = _$AchievementProgressCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'achievement_id') String achievementId, String code, String name, String? description,@JsonKey(fromJson: _toInt) int difficulty,@JsonKey(fromJson: _toInt) int consistency,@JsonKey(name: 'xp_reward', fromJson: _toInt) int xpReward, bool repeatable,@JsonKey(name: 'current_value', fromJson: _toDouble) double currentValue,@JsonKey(fromJson: _toDouble) double threshold,@JsonKey(fromJson: _toDouble) double progress,@JsonKey(fromJson: _toState) AchievementState state,@JsonKey(name: 'period_key') String periodKey
});




}
/// @nodoc
class _$AchievementProgressCopyWithImpl<$Res>
    implements $AchievementProgressCopyWith<$Res> {
  _$AchievementProgressCopyWithImpl(this._self, this._then);

  final AchievementProgress _self;
  final $Res Function(AchievementProgress) _then;

/// Create a copy of AchievementProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? achievementId = null,Object? code = null,Object? name = null,Object? description = freezed,Object? difficulty = null,Object? consistency = null,Object? xpReward = null,Object? repeatable = null,Object? currentValue = null,Object? threshold = null,Object? progress = null,Object? state = null,Object? periodKey = null,}) {
  return _then(_self.copyWith(
achievementId: null == achievementId ? _self.achievementId : achievementId // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,difficulty: null == difficulty ? _self.difficulty : difficulty // ignore: cast_nullable_to_non_nullable
as int,consistency: null == consistency ? _self.consistency : consistency // ignore: cast_nullable_to_non_nullable
as int,xpReward: null == xpReward ? _self.xpReward : xpReward // ignore: cast_nullable_to_non_nullable
as int,repeatable: null == repeatable ? _self.repeatable : repeatable // ignore: cast_nullable_to_non_nullable
as bool,currentValue: null == currentValue ? _self.currentValue : currentValue // ignore: cast_nullable_to_non_nullable
as double,threshold: null == threshold ? _self.threshold : threshold // ignore: cast_nullable_to_non_nullable
as double,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as AchievementState,periodKey: null == periodKey ? _self.periodKey : periodKey // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AchievementProgress].
extension AchievementProgressPatterns on AchievementProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AchievementProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AchievementProgress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AchievementProgress value)  $default,){
final _that = this;
switch (_that) {
case _AchievementProgress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AchievementProgress value)?  $default,){
final _that = this;
switch (_that) {
case _AchievementProgress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'achievement_id')  String achievementId,  String code,  String name,  String? description, @JsonKey(fromJson: _toInt)  int difficulty, @JsonKey(fromJson: _toInt)  int consistency, @JsonKey(name: 'xp_reward', fromJson: _toInt)  int xpReward,  bool repeatable, @JsonKey(name: 'current_value', fromJson: _toDouble)  double currentValue, @JsonKey(fromJson: _toDouble)  double threshold, @JsonKey(fromJson: _toDouble)  double progress, @JsonKey(fromJson: _toState)  AchievementState state, @JsonKey(name: 'period_key')  String periodKey)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AchievementProgress() when $default != null:
return $default(_that.achievementId,_that.code,_that.name,_that.description,_that.difficulty,_that.consistency,_that.xpReward,_that.repeatable,_that.currentValue,_that.threshold,_that.progress,_that.state,_that.periodKey);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'achievement_id')  String achievementId,  String code,  String name,  String? description, @JsonKey(fromJson: _toInt)  int difficulty, @JsonKey(fromJson: _toInt)  int consistency, @JsonKey(name: 'xp_reward', fromJson: _toInt)  int xpReward,  bool repeatable, @JsonKey(name: 'current_value', fromJson: _toDouble)  double currentValue, @JsonKey(fromJson: _toDouble)  double threshold, @JsonKey(fromJson: _toDouble)  double progress, @JsonKey(fromJson: _toState)  AchievementState state, @JsonKey(name: 'period_key')  String periodKey)  $default,) {final _that = this;
switch (_that) {
case _AchievementProgress():
return $default(_that.achievementId,_that.code,_that.name,_that.description,_that.difficulty,_that.consistency,_that.xpReward,_that.repeatable,_that.currentValue,_that.threshold,_that.progress,_that.state,_that.periodKey);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'achievement_id')  String achievementId,  String code,  String name,  String? description, @JsonKey(fromJson: _toInt)  int difficulty, @JsonKey(fromJson: _toInt)  int consistency, @JsonKey(name: 'xp_reward', fromJson: _toInt)  int xpReward,  bool repeatable, @JsonKey(name: 'current_value', fromJson: _toDouble)  double currentValue, @JsonKey(fromJson: _toDouble)  double threshold, @JsonKey(fromJson: _toDouble)  double progress, @JsonKey(fromJson: _toState)  AchievementState state, @JsonKey(name: 'period_key')  String periodKey)?  $default,) {final _that = this;
switch (_that) {
case _AchievementProgress() when $default != null:
return $default(_that.achievementId,_that.code,_that.name,_that.description,_that.difficulty,_that.consistency,_that.xpReward,_that.repeatable,_that.currentValue,_that.threshold,_that.progress,_that.state,_that.periodKey);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AchievementProgress extends AchievementProgress {
  const _AchievementProgress({@JsonKey(name: 'achievement_id') required this.achievementId, required this.code, required this.name, this.description, @JsonKey(fromJson: _toInt) required this.difficulty, @JsonKey(fromJson: _toInt) required this.consistency, @JsonKey(name: 'xp_reward', fromJson: _toInt) required this.xpReward, required this.repeatable, @JsonKey(name: 'current_value', fromJson: _toDouble) required this.currentValue, @JsonKey(fromJson: _toDouble) required this.threshold, @JsonKey(fromJson: _toDouble) required this.progress, @JsonKey(fromJson: _toState) required this.state, @JsonKey(name: 'period_key') required this.periodKey}): super._();
  factory _AchievementProgress.fromJson(Map<String, dynamic> json) => _$AchievementProgressFromJson(json);

@override@JsonKey(name: 'achievement_id') final  String achievementId;
@override final  String code;
@override final  String name;
@override final  String? description;
@override@JsonKey(fromJson: _toInt) final  int difficulty;
@override@JsonKey(fromJson: _toInt) final  int consistency;
@override@JsonKey(name: 'xp_reward', fromJson: _toInt) final  int xpReward;
@override final  bool repeatable;
@override@JsonKey(name: 'current_value', fromJson: _toDouble) final  double currentValue;
@override@JsonKey(fromJson: _toDouble) final  double threshold;
@override@JsonKey(fromJson: _toDouble) final  double progress;
@override@JsonKey(fromJson: _toState) final  AchievementState state;
@override@JsonKey(name: 'period_key') final  String periodKey;

/// Create a copy of AchievementProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AchievementProgressCopyWith<_AchievementProgress> get copyWith => __$AchievementProgressCopyWithImpl<_AchievementProgress>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AchievementProgressToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AchievementProgress&&(identical(other.achievementId, achievementId) || other.achievementId == achievementId)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.difficulty, difficulty) || other.difficulty == difficulty)&&(identical(other.consistency, consistency) || other.consistency == consistency)&&(identical(other.xpReward, xpReward) || other.xpReward == xpReward)&&(identical(other.repeatable, repeatable) || other.repeatable == repeatable)&&(identical(other.currentValue, currentValue) || other.currentValue == currentValue)&&(identical(other.threshold, threshold) || other.threshold == threshold)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.state, state) || other.state == state)&&(identical(other.periodKey, periodKey) || other.periodKey == periodKey));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,achievementId,code,name,description,difficulty,consistency,xpReward,repeatable,currentValue,threshold,progress,state,periodKey);

@override
String toString() {
  return 'AchievementProgress(achievementId: $achievementId, code: $code, name: $name, description: $description, difficulty: $difficulty, consistency: $consistency, xpReward: $xpReward, repeatable: $repeatable, currentValue: $currentValue, threshold: $threshold, progress: $progress, state: $state, periodKey: $periodKey)';
}


}

/// @nodoc
abstract mixin class _$AchievementProgressCopyWith<$Res> implements $AchievementProgressCopyWith<$Res> {
  factory _$AchievementProgressCopyWith(_AchievementProgress value, $Res Function(_AchievementProgress) _then) = __$AchievementProgressCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'achievement_id') String achievementId, String code, String name, String? description,@JsonKey(fromJson: _toInt) int difficulty,@JsonKey(fromJson: _toInt) int consistency,@JsonKey(name: 'xp_reward', fromJson: _toInt) int xpReward, bool repeatable,@JsonKey(name: 'current_value', fromJson: _toDouble) double currentValue,@JsonKey(fromJson: _toDouble) double threshold,@JsonKey(fromJson: _toDouble) double progress,@JsonKey(fromJson: _toState) AchievementState state,@JsonKey(name: 'period_key') String periodKey
});




}
/// @nodoc
class __$AchievementProgressCopyWithImpl<$Res>
    implements _$AchievementProgressCopyWith<$Res> {
  __$AchievementProgressCopyWithImpl(this._self, this._then);

  final _AchievementProgress _self;
  final $Res Function(_AchievementProgress) _then;

/// Create a copy of AchievementProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? achievementId = null,Object? code = null,Object? name = null,Object? description = freezed,Object? difficulty = null,Object? consistency = null,Object? xpReward = null,Object? repeatable = null,Object? currentValue = null,Object? threshold = null,Object? progress = null,Object? state = null,Object? periodKey = null,}) {
  return _then(_AchievementProgress(
achievementId: null == achievementId ? _self.achievementId : achievementId // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,difficulty: null == difficulty ? _self.difficulty : difficulty // ignore: cast_nullable_to_non_nullable
as int,consistency: null == consistency ? _self.consistency : consistency // ignore: cast_nullable_to_non_nullable
as int,xpReward: null == xpReward ? _self.xpReward : xpReward // ignore: cast_nullable_to_non_nullable
as int,repeatable: null == repeatable ? _self.repeatable : repeatable // ignore: cast_nullable_to_non_nullable
as bool,currentValue: null == currentValue ? _self.currentValue : currentValue // ignore: cast_nullable_to_non_nullable
as double,threshold: null == threshold ? _self.threshold : threshold // ignore: cast_nullable_to_non_nullable
as double,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as AchievementState,periodKey: null == periodKey ? _self.periodKey : periodKey // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
