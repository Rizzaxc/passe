// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vitality_score.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VitalityScore {

 DateTime get date;@JsonKey(fromJson: _toNullableDouble) double? get score;@JsonKey(name: 'consistency_component', fromJson: _toNullableDouble) double? get consistencyComponent;@JsonKey(name: 'load_component', fromJson: _toNullableDouble) double? get loadComponent;@JsonKey(name: 'recovery_component', fromJson: _toNullableDouble) double? get recoveryComponent;@JsonKey(name: 'volume_component', fromJson: _toNullableDouble) double? get volumeComponent;@JsonKey(name: 'streak_bonus', fromJson: _toDouble) double get streakBonus;@JsonKey(fromJson: _toNullableDouble) double? get ctl;@JsonKey(fromJson: _toNullableDouble) double? get atl;
/// Create a copy of VitalityScore
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VitalityScoreCopyWith<VitalityScore> get copyWith => _$VitalityScoreCopyWithImpl<VitalityScore>(this as VitalityScore, _$identity);

  /// Serializes this VitalityScore to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VitalityScore&&(identical(other.date, date) || other.date == date)&&(identical(other.score, score) || other.score == score)&&(identical(other.consistencyComponent, consistencyComponent) || other.consistencyComponent == consistencyComponent)&&(identical(other.loadComponent, loadComponent) || other.loadComponent == loadComponent)&&(identical(other.recoveryComponent, recoveryComponent) || other.recoveryComponent == recoveryComponent)&&(identical(other.volumeComponent, volumeComponent) || other.volumeComponent == volumeComponent)&&(identical(other.streakBonus, streakBonus) || other.streakBonus == streakBonus)&&(identical(other.ctl, ctl) || other.ctl == ctl)&&(identical(other.atl, atl) || other.atl == atl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,score,consistencyComponent,loadComponent,recoveryComponent,volumeComponent,streakBonus,ctl,atl);

@override
String toString() {
  return 'VitalityScore(date: $date, score: $score, consistencyComponent: $consistencyComponent, loadComponent: $loadComponent, recoveryComponent: $recoveryComponent, volumeComponent: $volumeComponent, streakBonus: $streakBonus, ctl: $ctl, atl: $atl)';
}


}

/// @nodoc
abstract mixin class $VitalityScoreCopyWith<$Res>  {
  factory $VitalityScoreCopyWith(VitalityScore value, $Res Function(VitalityScore) _then) = _$VitalityScoreCopyWithImpl;
@useResult
$Res call({
 DateTime date,@JsonKey(fromJson: _toNullableDouble) double? score,@JsonKey(name: 'consistency_component', fromJson: _toNullableDouble) double? consistencyComponent,@JsonKey(name: 'load_component', fromJson: _toNullableDouble) double? loadComponent,@JsonKey(name: 'recovery_component', fromJson: _toNullableDouble) double? recoveryComponent,@JsonKey(name: 'volume_component', fromJson: _toNullableDouble) double? volumeComponent,@JsonKey(name: 'streak_bonus', fromJson: _toDouble) double streakBonus,@JsonKey(fromJson: _toNullableDouble) double? ctl,@JsonKey(fromJson: _toNullableDouble) double? atl
});




}
/// @nodoc
class _$VitalityScoreCopyWithImpl<$Res>
    implements $VitalityScoreCopyWith<$Res> {
  _$VitalityScoreCopyWithImpl(this._self, this._then);

  final VitalityScore _self;
  final $Res Function(VitalityScore) _then;

/// Create a copy of VitalityScore
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? score = freezed,Object? consistencyComponent = freezed,Object? loadComponent = freezed,Object? recoveryComponent = freezed,Object? volumeComponent = freezed,Object? streakBonus = null,Object? ctl = freezed,Object? atl = freezed,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,score: freezed == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double?,consistencyComponent: freezed == consistencyComponent ? _self.consistencyComponent : consistencyComponent // ignore: cast_nullable_to_non_nullable
as double?,loadComponent: freezed == loadComponent ? _self.loadComponent : loadComponent // ignore: cast_nullable_to_non_nullable
as double?,recoveryComponent: freezed == recoveryComponent ? _self.recoveryComponent : recoveryComponent // ignore: cast_nullable_to_non_nullable
as double?,volumeComponent: freezed == volumeComponent ? _self.volumeComponent : volumeComponent // ignore: cast_nullable_to_non_nullable
as double?,streakBonus: null == streakBonus ? _self.streakBonus : streakBonus // ignore: cast_nullable_to_non_nullable
as double,ctl: freezed == ctl ? _self.ctl : ctl // ignore: cast_nullable_to_non_nullable
as double?,atl: freezed == atl ? _self.atl : atl // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [VitalityScore].
extension VitalityScorePatterns on VitalityScore {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VitalityScore value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VitalityScore() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VitalityScore value)  $default,){
final _that = this;
switch (_that) {
case _VitalityScore():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VitalityScore value)?  $default,){
final _that = this;
switch (_that) {
case _VitalityScore() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime date, @JsonKey(fromJson: _toNullableDouble)  double? score, @JsonKey(name: 'consistency_component', fromJson: _toNullableDouble)  double? consistencyComponent, @JsonKey(name: 'load_component', fromJson: _toNullableDouble)  double? loadComponent, @JsonKey(name: 'recovery_component', fromJson: _toNullableDouble)  double? recoveryComponent, @JsonKey(name: 'volume_component', fromJson: _toNullableDouble)  double? volumeComponent, @JsonKey(name: 'streak_bonus', fromJson: _toDouble)  double streakBonus, @JsonKey(fromJson: _toNullableDouble)  double? ctl, @JsonKey(fromJson: _toNullableDouble)  double? atl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VitalityScore() when $default != null:
return $default(_that.date,_that.score,_that.consistencyComponent,_that.loadComponent,_that.recoveryComponent,_that.volumeComponent,_that.streakBonus,_that.ctl,_that.atl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime date, @JsonKey(fromJson: _toNullableDouble)  double? score, @JsonKey(name: 'consistency_component', fromJson: _toNullableDouble)  double? consistencyComponent, @JsonKey(name: 'load_component', fromJson: _toNullableDouble)  double? loadComponent, @JsonKey(name: 'recovery_component', fromJson: _toNullableDouble)  double? recoveryComponent, @JsonKey(name: 'volume_component', fromJson: _toNullableDouble)  double? volumeComponent, @JsonKey(name: 'streak_bonus', fromJson: _toDouble)  double streakBonus, @JsonKey(fromJson: _toNullableDouble)  double? ctl, @JsonKey(fromJson: _toNullableDouble)  double? atl)  $default,) {final _that = this;
switch (_that) {
case _VitalityScore():
return $default(_that.date,_that.score,_that.consistencyComponent,_that.loadComponent,_that.recoveryComponent,_that.volumeComponent,_that.streakBonus,_that.ctl,_that.atl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime date, @JsonKey(fromJson: _toNullableDouble)  double? score, @JsonKey(name: 'consistency_component', fromJson: _toNullableDouble)  double? consistencyComponent, @JsonKey(name: 'load_component', fromJson: _toNullableDouble)  double? loadComponent, @JsonKey(name: 'recovery_component', fromJson: _toNullableDouble)  double? recoveryComponent, @JsonKey(name: 'volume_component', fromJson: _toNullableDouble)  double? volumeComponent, @JsonKey(name: 'streak_bonus', fromJson: _toDouble)  double streakBonus, @JsonKey(fromJson: _toNullableDouble)  double? ctl, @JsonKey(fromJson: _toNullableDouble)  double? atl)?  $default,) {final _that = this;
switch (_that) {
case _VitalityScore() when $default != null:
return $default(_that.date,_that.score,_that.consistencyComponent,_that.loadComponent,_that.recoveryComponent,_that.volumeComponent,_that.streakBonus,_that.ctl,_that.atl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VitalityScore extends VitalityScore {
  const _VitalityScore({required this.date, @JsonKey(fromJson: _toNullableDouble) this.score, @JsonKey(name: 'consistency_component', fromJson: _toNullableDouble) this.consistencyComponent, @JsonKey(name: 'load_component', fromJson: _toNullableDouble) this.loadComponent, @JsonKey(name: 'recovery_component', fromJson: _toNullableDouble) this.recoveryComponent, @JsonKey(name: 'volume_component', fromJson: _toNullableDouble) this.volumeComponent, @JsonKey(name: 'streak_bonus', fromJson: _toDouble) this.streakBonus = 0, @JsonKey(fromJson: _toNullableDouble) this.ctl, @JsonKey(fromJson: _toNullableDouble) this.atl}): super._();
  factory _VitalityScore.fromJson(Map<String, dynamic> json) => _$VitalityScoreFromJson(json);

@override final  DateTime date;
@override@JsonKey(fromJson: _toNullableDouble) final  double? score;
@override@JsonKey(name: 'consistency_component', fromJson: _toNullableDouble) final  double? consistencyComponent;
@override@JsonKey(name: 'load_component', fromJson: _toNullableDouble) final  double? loadComponent;
@override@JsonKey(name: 'recovery_component', fromJson: _toNullableDouble) final  double? recoveryComponent;
@override@JsonKey(name: 'volume_component', fromJson: _toNullableDouble) final  double? volumeComponent;
@override@JsonKey(name: 'streak_bonus', fromJson: _toDouble) final  double streakBonus;
@override@JsonKey(fromJson: _toNullableDouble) final  double? ctl;
@override@JsonKey(fromJson: _toNullableDouble) final  double? atl;

/// Create a copy of VitalityScore
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VitalityScoreCopyWith<_VitalityScore> get copyWith => __$VitalityScoreCopyWithImpl<_VitalityScore>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VitalityScoreToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VitalityScore&&(identical(other.date, date) || other.date == date)&&(identical(other.score, score) || other.score == score)&&(identical(other.consistencyComponent, consistencyComponent) || other.consistencyComponent == consistencyComponent)&&(identical(other.loadComponent, loadComponent) || other.loadComponent == loadComponent)&&(identical(other.recoveryComponent, recoveryComponent) || other.recoveryComponent == recoveryComponent)&&(identical(other.volumeComponent, volumeComponent) || other.volumeComponent == volumeComponent)&&(identical(other.streakBonus, streakBonus) || other.streakBonus == streakBonus)&&(identical(other.ctl, ctl) || other.ctl == ctl)&&(identical(other.atl, atl) || other.atl == atl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,score,consistencyComponent,loadComponent,recoveryComponent,volumeComponent,streakBonus,ctl,atl);

@override
String toString() {
  return 'VitalityScore(date: $date, score: $score, consistencyComponent: $consistencyComponent, loadComponent: $loadComponent, recoveryComponent: $recoveryComponent, volumeComponent: $volumeComponent, streakBonus: $streakBonus, ctl: $ctl, atl: $atl)';
}


}

/// @nodoc
abstract mixin class _$VitalityScoreCopyWith<$Res> implements $VitalityScoreCopyWith<$Res> {
  factory _$VitalityScoreCopyWith(_VitalityScore value, $Res Function(_VitalityScore) _then) = __$VitalityScoreCopyWithImpl;
@override @useResult
$Res call({
 DateTime date,@JsonKey(fromJson: _toNullableDouble) double? score,@JsonKey(name: 'consistency_component', fromJson: _toNullableDouble) double? consistencyComponent,@JsonKey(name: 'load_component', fromJson: _toNullableDouble) double? loadComponent,@JsonKey(name: 'recovery_component', fromJson: _toNullableDouble) double? recoveryComponent,@JsonKey(name: 'volume_component', fromJson: _toNullableDouble) double? volumeComponent,@JsonKey(name: 'streak_bonus', fromJson: _toDouble) double streakBonus,@JsonKey(fromJson: _toNullableDouble) double? ctl,@JsonKey(fromJson: _toNullableDouble) double? atl
});




}
/// @nodoc
class __$VitalityScoreCopyWithImpl<$Res>
    implements _$VitalityScoreCopyWith<$Res> {
  __$VitalityScoreCopyWithImpl(this._self, this._then);

  final _VitalityScore _self;
  final $Res Function(_VitalityScore) _then;

/// Create a copy of VitalityScore
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? score = freezed,Object? consistencyComponent = freezed,Object? loadComponent = freezed,Object? recoveryComponent = freezed,Object? volumeComponent = freezed,Object? streakBonus = null,Object? ctl = freezed,Object? atl = freezed,}) {
  return _then(_VitalityScore(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,score: freezed == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double?,consistencyComponent: freezed == consistencyComponent ? _self.consistencyComponent : consistencyComponent // ignore: cast_nullable_to_non_nullable
as double?,loadComponent: freezed == loadComponent ? _self.loadComponent : loadComponent // ignore: cast_nullable_to_non_nullable
as double?,recoveryComponent: freezed == recoveryComponent ? _self.recoveryComponent : recoveryComponent // ignore: cast_nullable_to_non_nullable
as double?,volumeComponent: freezed == volumeComponent ? _self.volumeComponent : volumeComponent // ignore: cast_nullable_to_non_nullable
as double?,streakBonus: null == streakBonus ? _self.streakBonus : streakBonus // ignore: cast_nullable_to_non_nullable
as double,ctl: freezed == ctl ? _self.ctl : ctl // ignore: cast_nullable_to_non_nullable
as double?,atl: freezed == atl ? _self.atl : atl // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
