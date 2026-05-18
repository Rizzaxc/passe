// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hr_sample.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HrSample {

 int? get id;@JsonKey(name: 'activity_id') String get activityId; DateTime get timestamp; int get bpm;
/// Create a copy of HrSample
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HrSampleCopyWith<HrSample> get copyWith => _$HrSampleCopyWithImpl<HrSample>(this as HrSample, _$identity);

  /// Serializes this HrSample to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HrSample&&(identical(other.id, id) || other.id == id)&&(identical(other.activityId, activityId) || other.activityId == activityId)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.bpm, bpm) || other.bpm == bpm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,activityId,timestamp,bpm);

@override
String toString() {
  return 'HrSample(id: $id, activityId: $activityId, timestamp: $timestamp, bpm: $bpm)';
}


}

/// @nodoc
abstract mixin class $HrSampleCopyWith<$Res>  {
  factory $HrSampleCopyWith(HrSample value, $Res Function(HrSample) _then) = _$HrSampleCopyWithImpl;
@useResult
$Res call({
 int? id,@JsonKey(name: 'activity_id') String activityId, DateTime timestamp, int bpm
});




}
/// @nodoc
class _$HrSampleCopyWithImpl<$Res>
    implements $HrSampleCopyWith<$Res> {
  _$HrSampleCopyWithImpl(this._self, this._then);

  final HrSample _self;
  final $Res Function(HrSample) _then;

/// Create a copy of HrSample
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? activityId = null,Object? timestamp = null,Object? bpm = null,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,activityId: null == activityId ? _self.activityId : activityId // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,bpm: null == bpm ? _self.bpm : bpm // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [HrSample].
extension HrSamplePatterns on HrSample {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HrSample value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HrSample() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HrSample value)  $default,){
final _that = this;
switch (_that) {
case _HrSample():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HrSample value)?  $default,){
final _that = this;
switch (_that) {
case _HrSample() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id, @JsonKey(name: 'activity_id')  String activityId,  DateTime timestamp,  int bpm)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HrSample() when $default != null:
return $default(_that.id,_that.activityId,_that.timestamp,_that.bpm);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id, @JsonKey(name: 'activity_id')  String activityId,  DateTime timestamp,  int bpm)  $default,) {final _that = this;
switch (_that) {
case _HrSample():
return $default(_that.id,_that.activityId,_that.timestamp,_that.bpm);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id, @JsonKey(name: 'activity_id')  String activityId,  DateTime timestamp,  int bpm)?  $default,) {final _that = this;
switch (_that) {
case _HrSample() when $default != null:
return $default(_that.id,_that.activityId,_that.timestamp,_that.bpm);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HrSample implements HrSample {
  const _HrSample({this.id, @JsonKey(name: 'activity_id') required this.activityId, required this.timestamp, required this.bpm});
  factory _HrSample.fromJson(Map<String, dynamic> json) => _$HrSampleFromJson(json);

@override final  int? id;
@override@JsonKey(name: 'activity_id') final  String activityId;
@override final  DateTime timestamp;
@override final  int bpm;

/// Create a copy of HrSample
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HrSampleCopyWith<_HrSample> get copyWith => __$HrSampleCopyWithImpl<_HrSample>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HrSampleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HrSample&&(identical(other.id, id) || other.id == id)&&(identical(other.activityId, activityId) || other.activityId == activityId)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.bpm, bpm) || other.bpm == bpm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,activityId,timestamp,bpm);

@override
String toString() {
  return 'HrSample(id: $id, activityId: $activityId, timestamp: $timestamp, bpm: $bpm)';
}


}

/// @nodoc
abstract mixin class _$HrSampleCopyWith<$Res> implements $HrSampleCopyWith<$Res> {
  factory _$HrSampleCopyWith(_HrSample value, $Res Function(_HrSample) _then) = __$HrSampleCopyWithImpl;
@override @useResult
$Res call({
 int? id,@JsonKey(name: 'activity_id') String activityId, DateTime timestamp, int bpm
});




}
/// @nodoc
class __$HrSampleCopyWithImpl<$Res>
    implements _$HrSampleCopyWith<$Res> {
  __$HrSampleCopyWithImpl(this._self, this._then);

  final _HrSample _self;
  final $Res Function(_HrSample) _then;

/// Create a copy of HrSample
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? activityId = null,Object? timestamp = null,Object? bpm = null,}) {
  return _then(_HrSample(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,activityId: null == activityId ? _self.activityId : activityId // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,bpm: null == bpm ? _self.bpm : bpm // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$HrSampleBatch {

@JsonKey(name: 'activity_id') String get activityId; List<HrSamplePoint> get samples;
/// Create a copy of HrSampleBatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HrSampleBatchCopyWith<HrSampleBatch> get copyWith => _$HrSampleBatchCopyWithImpl<HrSampleBatch>(this as HrSampleBatch, _$identity);

  /// Serializes this HrSampleBatch to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HrSampleBatch&&(identical(other.activityId, activityId) || other.activityId == activityId)&&const DeepCollectionEquality().equals(other.samples, samples));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,activityId,const DeepCollectionEquality().hash(samples));

@override
String toString() {
  return 'HrSampleBatch(activityId: $activityId, samples: $samples)';
}


}

/// @nodoc
abstract mixin class $HrSampleBatchCopyWith<$Res>  {
  factory $HrSampleBatchCopyWith(HrSampleBatch value, $Res Function(HrSampleBatch) _then) = _$HrSampleBatchCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'activity_id') String activityId, List<HrSamplePoint> samples
});




}
/// @nodoc
class _$HrSampleBatchCopyWithImpl<$Res>
    implements $HrSampleBatchCopyWith<$Res> {
  _$HrSampleBatchCopyWithImpl(this._self, this._then);

  final HrSampleBatch _self;
  final $Res Function(HrSampleBatch) _then;

/// Create a copy of HrSampleBatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? activityId = null,Object? samples = null,}) {
  return _then(_self.copyWith(
activityId: null == activityId ? _self.activityId : activityId // ignore: cast_nullable_to_non_nullable
as String,samples: null == samples ? _self.samples : samples // ignore: cast_nullable_to_non_nullable
as List<HrSamplePoint>,
  ));
}

}


/// Adds pattern-matching-related methods to [HrSampleBatch].
extension HrSampleBatchPatterns on HrSampleBatch {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HrSampleBatch value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HrSampleBatch() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HrSampleBatch value)  $default,){
final _that = this;
switch (_that) {
case _HrSampleBatch():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HrSampleBatch value)?  $default,){
final _that = this;
switch (_that) {
case _HrSampleBatch() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'activity_id')  String activityId,  List<HrSamplePoint> samples)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HrSampleBatch() when $default != null:
return $default(_that.activityId,_that.samples);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'activity_id')  String activityId,  List<HrSamplePoint> samples)  $default,) {final _that = this;
switch (_that) {
case _HrSampleBatch():
return $default(_that.activityId,_that.samples);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'activity_id')  String activityId,  List<HrSamplePoint> samples)?  $default,) {final _that = this;
switch (_that) {
case _HrSampleBatch() when $default != null:
return $default(_that.activityId,_that.samples);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HrSampleBatch implements HrSampleBatch {
  const _HrSampleBatch({@JsonKey(name: 'activity_id') required this.activityId, required final  List<HrSamplePoint> samples}): _samples = samples;
  factory _HrSampleBatch.fromJson(Map<String, dynamic> json) => _$HrSampleBatchFromJson(json);

@override@JsonKey(name: 'activity_id') final  String activityId;
 final  List<HrSamplePoint> _samples;
@override List<HrSamplePoint> get samples {
  if (_samples is EqualUnmodifiableListView) return _samples;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_samples);
}


/// Create a copy of HrSampleBatch
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HrSampleBatchCopyWith<_HrSampleBatch> get copyWith => __$HrSampleBatchCopyWithImpl<_HrSampleBatch>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HrSampleBatchToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HrSampleBatch&&(identical(other.activityId, activityId) || other.activityId == activityId)&&const DeepCollectionEquality().equals(other._samples, _samples));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,activityId,const DeepCollectionEquality().hash(_samples));

@override
String toString() {
  return 'HrSampleBatch(activityId: $activityId, samples: $samples)';
}


}

/// @nodoc
abstract mixin class _$HrSampleBatchCopyWith<$Res> implements $HrSampleBatchCopyWith<$Res> {
  factory _$HrSampleBatchCopyWith(_HrSampleBatch value, $Res Function(_HrSampleBatch) _then) = __$HrSampleBatchCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'activity_id') String activityId, List<HrSamplePoint> samples
});




}
/// @nodoc
class __$HrSampleBatchCopyWithImpl<$Res>
    implements _$HrSampleBatchCopyWith<$Res> {
  __$HrSampleBatchCopyWithImpl(this._self, this._then);

  final _HrSampleBatch _self;
  final $Res Function(_HrSampleBatch) _then;

/// Create a copy of HrSampleBatch
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? activityId = null,Object? samples = null,}) {
  return _then(_HrSampleBatch(
activityId: null == activityId ? _self.activityId : activityId // ignore: cast_nullable_to_non_nullable
as String,samples: null == samples ? _self._samples : samples // ignore: cast_nullable_to_non_nullable
as List<HrSamplePoint>,
  ));
}


}


/// @nodoc
mixin _$HrSamplePoint {

 DateTime get timestamp; int get bpm;
/// Create a copy of HrSamplePoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HrSamplePointCopyWith<HrSamplePoint> get copyWith => _$HrSamplePointCopyWithImpl<HrSamplePoint>(this as HrSamplePoint, _$identity);

  /// Serializes this HrSamplePoint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HrSamplePoint&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.bpm, bpm) || other.bpm == bpm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,timestamp,bpm);

@override
String toString() {
  return 'HrSamplePoint(timestamp: $timestamp, bpm: $bpm)';
}


}

/// @nodoc
abstract mixin class $HrSamplePointCopyWith<$Res>  {
  factory $HrSamplePointCopyWith(HrSamplePoint value, $Res Function(HrSamplePoint) _then) = _$HrSamplePointCopyWithImpl;
@useResult
$Res call({
 DateTime timestamp, int bpm
});




}
/// @nodoc
class _$HrSamplePointCopyWithImpl<$Res>
    implements $HrSamplePointCopyWith<$Res> {
  _$HrSamplePointCopyWithImpl(this._self, this._then);

  final HrSamplePoint _self;
  final $Res Function(HrSamplePoint) _then;

/// Create a copy of HrSamplePoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? timestamp = null,Object? bpm = null,}) {
  return _then(_self.copyWith(
timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,bpm: null == bpm ? _self.bpm : bpm // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [HrSamplePoint].
extension HrSamplePointPatterns on HrSamplePoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HrSamplePoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HrSamplePoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HrSamplePoint value)  $default,){
final _that = this;
switch (_that) {
case _HrSamplePoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HrSamplePoint value)?  $default,){
final _that = this;
switch (_that) {
case _HrSamplePoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime timestamp,  int bpm)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HrSamplePoint() when $default != null:
return $default(_that.timestamp,_that.bpm);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime timestamp,  int bpm)  $default,) {final _that = this;
switch (_that) {
case _HrSamplePoint():
return $default(_that.timestamp,_that.bpm);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime timestamp,  int bpm)?  $default,) {final _that = this;
switch (_that) {
case _HrSamplePoint() when $default != null:
return $default(_that.timestamp,_that.bpm);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HrSamplePoint implements HrSamplePoint {
  const _HrSamplePoint({required this.timestamp, required this.bpm});
  factory _HrSamplePoint.fromJson(Map<String, dynamic> json) => _$HrSamplePointFromJson(json);

@override final  DateTime timestamp;
@override final  int bpm;

/// Create a copy of HrSamplePoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HrSamplePointCopyWith<_HrSamplePoint> get copyWith => __$HrSamplePointCopyWithImpl<_HrSamplePoint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HrSamplePointToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HrSamplePoint&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.bpm, bpm) || other.bpm == bpm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,timestamp,bpm);

@override
String toString() {
  return 'HrSamplePoint(timestamp: $timestamp, bpm: $bpm)';
}


}

/// @nodoc
abstract mixin class _$HrSamplePointCopyWith<$Res> implements $HrSamplePointCopyWith<$Res> {
  factory _$HrSamplePointCopyWith(_HrSamplePoint value, $Res Function(_HrSamplePoint) _then) = __$HrSamplePointCopyWithImpl;
@override @useResult
$Res call({
 DateTime timestamp, int bpm
});




}
/// @nodoc
class __$HrSamplePointCopyWithImpl<$Res>
    implements _$HrSamplePointCopyWith<$Res> {
  __$HrSamplePointCopyWithImpl(this._self, this._then);

  final _HrSamplePoint _self;
  final $Res Function(_HrSamplePoint) _then;

/// Create a copy of HrSamplePoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? timestamp = null,Object? bpm = null,}) {
  return _then(_HrSamplePoint(
timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,bpm: null == bpm ? _self.bpm : bpm // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
