// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'level_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LevelSummary {

 int get level;@JsonKey(name: 'xp_total') int get xpTotal;@JsonKey(name: 'current_floor') int get currentFloor;@JsonKey(name: 'next_floor') int? get nextFloor;
/// Create a copy of LevelSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LevelSummaryCopyWith<LevelSummary> get copyWith => _$LevelSummaryCopyWithImpl<LevelSummary>(this as LevelSummary, _$identity);

  /// Serializes this LevelSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LevelSummary&&(identical(other.level, level) || other.level == level)&&(identical(other.xpTotal, xpTotal) || other.xpTotal == xpTotal)&&(identical(other.currentFloor, currentFloor) || other.currentFloor == currentFloor)&&(identical(other.nextFloor, nextFloor) || other.nextFloor == nextFloor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,level,xpTotal,currentFloor,nextFloor);

@override
String toString() {
  return 'LevelSummary(level: $level, xpTotal: $xpTotal, currentFloor: $currentFloor, nextFloor: $nextFloor)';
}


}

/// @nodoc
abstract mixin class $LevelSummaryCopyWith<$Res>  {
  factory $LevelSummaryCopyWith(LevelSummary value, $Res Function(LevelSummary) _then) = _$LevelSummaryCopyWithImpl;
@useResult
$Res call({
 int level,@JsonKey(name: 'xp_total') int xpTotal,@JsonKey(name: 'current_floor') int currentFloor,@JsonKey(name: 'next_floor') int? nextFloor
});




}
/// @nodoc
class _$LevelSummaryCopyWithImpl<$Res>
    implements $LevelSummaryCopyWith<$Res> {
  _$LevelSummaryCopyWithImpl(this._self, this._then);

  final LevelSummary _self;
  final $Res Function(LevelSummary) _then;

/// Create a copy of LevelSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? level = null,Object? xpTotal = null,Object? currentFloor = null,Object? nextFloor = freezed,}) {
  return _then(_self.copyWith(
level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,xpTotal: null == xpTotal ? _self.xpTotal : xpTotal // ignore: cast_nullable_to_non_nullable
as int,currentFloor: null == currentFloor ? _self.currentFloor : currentFloor // ignore: cast_nullable_to_non_nullable
as int,nextFloor: freezed == nextFloor ? _self.nextFloor : nextFloor // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [LevelSummary].
extension LevelSummaryPatterns on LevelSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LevelSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LevelSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LevelSummary value)  $default,){
final _that = this;
switch (_that) {
case _LevelSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LevelSummary value)?  $default,){
final _that = this;
switch (_that) {
case _LevelSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int level, @JsonKey(name: 'xp_total')  int xpTotal, @JsonKey(name: 'current_floor')  int currentFloor, @JsonKey(name: 'next_floor')  int? nextFloor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LevelSummary() when $default != null:
return $default(_that.level,_that.xpTotal,_that.currentFloor,_that.nextFloor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int level, @JsonKey(name: 'xp_total')  int xpTotal, @JsonKey(name: 'current_floor')  int currentFloor, @JsonKey(name: 'next_floor')  int? nextFloor)  $default,) {final _that = this;
switch (_that) {
case _LevelSummary():
return $default(_that.level,_that.xpTotal,_that.currentFloor,_that.nextFloor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int level, @JsonKey(name: 'xp_total')  int xpTotal, @JsonKey(name: 'current_floor')  int currentFloor, @JsonKey(name: 'next_floor')  int? nextFloor)?  $default,) {final _that = this;
switch (_that) {
case _LevelSummary() when $default != null:
return $default(_that.level,_that.xpTotal,_that.currentFloor,_that.nextFloor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LevelSummary extends LevelSummary {
  const _LevelSummary({required this.level, @JsonKey(name: 'xp_total') required this.xpTotal, @JsonKey(name: 'current_floor') required this.currentFloor, @JsonKey(name: 'next_floor') this.nextFloor}): super._();
  factory _LevelSummary.fromJson(Map<String, dynamic> json) => _$LevelSummaryFromJson(json);

@override final  int level;
@override@JsonKey(name: 'xp_total') final  int xpTotal;
@override@JsonKey(name: 'current_floor') final  int currentFloor;
@override@JsonKey(name: 'next_floor') final  int? nextFloor;

/// Create a copy of LevelSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LevelSummaryCopyWith<_LevelSummary> get copyWith => __$LevelSummaryCopyWithImpl<_LevelSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LevelSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LevelSummary&&(identical(other.level, level) || other.level == level)&&(identical(other.xpTotal, xpTotal) || other.xpTotal == xpTotal)&&(identical(other.currentFloor, currentFloor) || other.currentFloor == currentFloor)&&(identical(other.nextFloor, nextFloor) || other.nextFloor == nextFloor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,level,xpTotal,currentFloor,nextFloor);

@override
String toString() {
  return 'LevelSummary(level: $level, xpTotal: $xpTotal, currentFloor: $currentFloor, nextFloor: $nextFloor)';
}


}

/// @nodoc
abstract mixin class _$LevelSummaryCopyWith<$Res> implements $LevelSummaryCopyWith<$Res> {
  factory _$LevelSummaryCopyWith(_LevelSummary value, $Res Function(_LevelSummary) _then) = __$LevelSummaryCopyWithImpl;
@override @useResult
$Res call({
 int level,@JsonKey(name: 'xp_total') int xpTotal,@JsonKey(name: 'current_floor') int currentFloor,@JsonKey(name: 'next_floor') int? nextFloor
});




}
/// @nodoc
class __$LevelSummaryCopyWithImpl<$Res>
    implements _$LevelSummaryCopyWith<$Res> {
  __$LevelSummaryCopyWithImpl(this._self, this._then);

  final _LevelSummary _self;
  final $Res Function(_LevelSummary) _then;

/// Create a copy of LevelSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? level = null,Object? xpTotal = null,Object? currentFloor = null,Object? nextFloor = freezed,}) {
  return _then(_LevelSummary(
level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,xpTotal: null == xpTotal ? _self.xpTotal : xpTotal // ignore: cast_nullable_to_non_nullable
as int,currentFloor: null == currentFloor ? _self.currentFloor : currentFloor // ignore: cast_nullable_to_non_nullable
as int,nextFloor: freezed == nextFloor ? _self.nextFloor : nextFloor // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
