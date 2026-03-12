// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sport_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SoccerProfile {

 List<SoccerPosition>? get position; List<SoccerPitch>? get pitch;@JsonKey(name: 'elo_seed') EloSeed? get eloSeed;
/// Create a copy of SoccerProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SoccerProfileCopyWith<SoccerProfile> get copyWith => _$SoccerProfileCopyWithImpl<SoccerProfile>(this as SoccerProfile, _$identity);

  /// Serializes this SoccerProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SoccerProfile&&const DeepCollectionEquality().equals(other.position, position)&&const DeepCollectionEquality().equals(other.pitch, pitch)&&(identical(other.eloSeed, eloSeed) || other.eloSeed == eloSeed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(position),const DeepCollectionEquality().hash(pitch),eloSeed);

@override
String toString() {
  return 'SoccerProfile(position: $position, pitch: $pitch, eloSeed: $eloSeed)';
}


}

/// @nodoc
abstract mixin class $SoccerProfileCopyWith<$Res>  {
  factory $SoccerProfileCopyWith(SoccerProfile value, $Res Function(SoccerProfile) _then) = _$SoccerProfileCopyWithImpl;
@useResult
$Res call({
 List<SoccerPosition>? position, List<SoccerPitch>? pitch,@JsonKey(name: 'elo_seed') EloSeed? eloSeed
});




}
/// @nodoc
class _$SoccerProfileCopyWithImpl<$Res>
    implements $SoccerProfileCopyWith<$Res> {
  _$SoccerProfileCopyWithImpl(this._self, this._then);

  final SoccerProfile _self;
  final $Res Function(SoccerProfile) _then;

/// Create a copy of SoccerProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? position = freezed,Object? pitch = freezed,Object? eloSeed = freezed,}) {
  return _then(_self.copyWith(
position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as List<SoccerPosition>?,pitch: freezed == pitch ? _self.pitch : pitch // ignore: cast_nullable_to_non_nullable
as List<SoccerPitch>?,eloSeed: freezed == eloSeed ? _self.eloSeed : eloSeed // ignore: cast_nullable_to_non_nullable
as EloSeed?,
  ));
}

}


/// Adds pattern-matching-related methods to [SoccerProfile].
extension SoccerProfilePatterns on SoccerProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SoccerProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SoccerProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SoccerProfile value)  $default,){
final _that = this;
switch (_that) {
case _SoccerProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SoccerProfile value)?  $default,){
final _that = this;
switch (_that) {
case _SoccerProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SoccerPosition>? position,  List<SoccerPitch>? pitch, @JsonKey(name: 'elo_seed')  EloSeed? eloSeed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SoccerProfile() when $default != null:
return $default(_that.position,_that.pitch,_that.eloSeed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SoccerPosition>? position,  List<SoccerPitch>? pitch, @JsonKey(name: 'elo_seed')  EloSeed? eloSeed)  $default,) {final _that = this;
switch (_that) {
case _SoccerProfile():
return $default(_that.position,_that.pitch,_that.eloSeed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SoccerPosition>? position,  List<SoccerPitch>? pitch, @JsonKey(name: 'elo_seed')  EloSeed? eloSeed)?  $default,) {final _that = this;
switch (_that) {
case _SoccerProfile() when $default != null:
return $default(_that.position,_that.pitch,_that.eloSeed);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SoccerProfile implements SoccerProfile {
  const _SoccerProfile({final  List<SoccerPosition>? position, final  List<SoccerPitch>? pitch, @JsonKey(name: 'elo_seed') this.eloSeed}): _position = position,_pitch = pitch;
  factory _SoccerProfile.fromJson(Map<String, dynamic> json) => _$SoccerProfileFromJson(json);

 final  List<SoccerPosition>? _position;
@override List<SoccerPosition>? get position {
  final value = _position;
  if (value == null) return null;
  if (_position is EqualUnmodifiableListView) return _position;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<SoccerPitch>? _pitch;
@override List<SoccerPitch>? get pitch {
  final value = _pitch;
  if (value == null) return null;
  if (_pitch is EqualUnmodifiableListView) return _pitch;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey(name: 'elo_seed') final  EloSeed? eloSeed;

/// Create a copy of SoccerProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SoccerProfileCopyWith<_SoccerProfile> get copyWith => __$SoccerProfileCopyWithImpl<_SoccerProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SoccerProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SoccerProfile&&const DeepCollectionEquality().equals(other._position, _position)&&const DeepCollectionEquality().equals(other._pitch, _pitch)&&(identical(other.eloSeed, eloSeed) || other.eloSeed == eloSeed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_position),const DeepCollectionEquality().hash(_pitch),eloSeed);

@override
String toString() {
  return 'SoccerProfile(position: $position, pitch: $pitch, eloSeed: $eloSeed)';
}


}

/// @nodoc
abstract mixin class _$SoccerProfileCopyWith<$Res> implements $SoccerProfileCopyWith<$Res> {
  factory _$SoccerProfileCopyWith(_SoccerProfile value, $Res Function(_SoccerProfile) _then) = __$SoccerProfileCopyWithImpl;
@override @useResult
$Res call({
 List<SoccerPosition>? position, List<SoccerPitch>? pitch,@JsonKey(name: 'elo_seed') EloSeed? eloSeed
});




}
/// @nodoc
class __$SoccerProfileCopyWithImpl<$Res>
    implements _$SoccerProfileCopyWith<$Res> {
  __$SoccerProfileCopyWithImpl(this._self, this._then);

  final _SoccerProfile _self;
  final $Res Function(_SoccerProfile) _then;

/// Create a copy of SoccerProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? position = freezed,Object? pitch = freezed,Object? eloSeed = freezed,}) {
  return _then(_SoccerProfile(
position: freezed == position ? _self._position : position // ignore: cast_nullable_to_non_nullable
as List<SoccerPosition>?,pitch: freezed == pitch ? _self._pitch : pitch // ignore: cast_nullable_to_non_nullable
as List<SoccerPitch>?,eloSeed: freezed == eloSeed ? _self.eloSeed : eloSeed // ignore: cast_nullable_to_non_nullable
as EloSeed?,
  ));
}


}


/// @nodoc
mixin _$BasketballProfile {

 List<BasketballPosition>? get position; List<BasketballPitch>? get pitch;@JsonKey(name: 'elo_seed') EloSeed? get eloSeed;
/// Create a copy of BasketballProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BasketballProfileCopyWith<BasketballProfile> get copyWith => _$BasketballProfileCopyWithImpl<BasketballProfile>(this as BasketballProfile, _$identity);

  /// Serializes this BasketballProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BasketballProfile&&const DeepCollectionEquality().equals(other.position, position)&&const DeepCollectionEquality().equals(other.pitch, pitch)&&(identical(other.eloSeed, eloSeed) || other.eloSeed == eloSeed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(position),const DeepCollectionEquality().hash(pitch),eloSeed);

@override
String toString() {
  return 'BasketballProfile(position: $position, pitch: $pitch, eloSeed: $eloSeed)';
}


}

/// @nodoc
abstract mixin class $BasketballProfileCopyWith<$Res>  {
  factory $BasketballProfileCopyWith(BasketballProfile value, $Res Function(BasketballProfile) _then) = _$BasketballProfileCopyWithImpl;
@useResult
$Res call({
 List<BasketballPosition>? position, List<BasketballPitch>? pitch,@JsonKey(name: 'elo_seed') EloSeed? eloSeed
});




}
/// @nodoc
class _$BasketballProfileCopyWithImpl<$Res>
    implements $BasketballProfileCopyWith<$Res> {
  _$BasketballProfileCopyWithImpl(this._self, this._then);

  final BasketballProfile _self;
  final $Res Function(BasketballProfile) _then;

/// Create a copy of BasketballProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? position = freezed,Object? pitch = freezed,Object? eloSeed = freezed,}) {
  return _then(_self.copyWith(
position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as List<BasketballPosition>?,pitch: freezed == pitch ? _self.pitch : pitch // ignore: cast_nullable_to_non_nullable
as List<BasketballPitch>?,eloSeed: freezed == eloSeed ? _self.eloSeed : eloSeed // ignore: cast_nullable_to_non_nullable
as EloSeed?,
  ));
}

}


/// Adds pattern-matching-related methods to [BasketballProfile].
extension BasketballProfilePatterns on BasketballProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BasketballProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BasketballProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BasketballProfile value)  $default,){
final _that = this;
switch (_that) {
case _BasketballProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BasketballProfile value)?  $default,){
final _that = this;
switch (_that) {
case _BasketballProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<BasketballPosition>? position,  List<BasketballPitch>? pitch, @JsonKey(name: 'elo_seed')  EloSeed? eloSeed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BasketballProfile() when $default != null:
return $default(_that.position,_that.pitch,_that.eloSeed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<BasketballPosition>? position,  List<BasketballPitch>? pitch, @JsonKey(name: 'elo_seed')  EloSeed? eloSeed)  $default,) {final _that = this;
switch (_that) {
case _BasketballProfile():
return $default(_that.position,_that.pitch,_that.eloSeed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<BasketballPosition>? position,  List<BasketballPitch>? pitch, @JsonKey(name: 'elo_seed')  EloSeed? eloSeed)?  $default,) {final _that = this;
switch (_that) {
case _BasketballProfile() when $default != null:
return $default(_that.position,_that.pitch,_that.eloSeed);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BasketballProfile implements BasketballProfile {
  const _BasketballProfile({final  List<BasketballPosition>? position, final  List<BasketballPitch>? pitch, @JsonKey(name: 'elo_seed') this.eloSeed}): _position = position,_pitch = pitch;
  factory _BasketballProfile.fromJson(Map<String, dynamic> json) => _$BasketballProfileFromJson(json);

 final  List<BasketballPosition>? _position;
@override List<BasketballPosition>? get position {
  final value = _position;
  if (value == null) return null;
  if (_position is EqualUnmodifiableListView) return _position;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<BasketballPitch>? _pitch;
@override List<BasketballPitch>? get pitch {
  final value = _pitch;
  if (value == null) return null;
  if (_pitch is EqualUnmodifiableListView) return _pitch;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey(name: 'elo_seed') final  EloSeed? eloSeed;

/// Create a copy of BasketballProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BasketballProfileCopyWith<_BasketballProfile> get copyWith => __$BasketballProfileCopyWithImpl<_BasketballProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BasketballProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BasketballProfile&&const DeepCollectionEquality().equals(other._position, _position)&&const DeepCollectionEquality().equals(other._pitch, _pitch)&&(identical(other.eloSeed, eloSeed) || other.eloSeed == eloSeed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_position),const DeepCollectionEquality().hash(_pitch),eloSeed);

@override
String toString() {
  return 'BasketballProfile(position: $position, pitch: $pitch, eloSeed: $eloSeed)';
}


}

/// @nodoc
abstract mixin class _$BasketballProfileCopyWith<$Res> implements $BasketballProfileCopyWith<$Res> {
  factory _$BasketballProfileCopyWith(_BasketballProfile value, $Res Function(_BasketballProfile) _then) = __$BasketballProfileCopyWithImpl;
@override @useResult
$Res call({
 List<BasketballPosition>? position, List<BasketballPitch>? pitch,@JsonKey(name: 'elo_seed') EloSeed? eloSeed
});




}
/// @nodoc
class __$BasketballProfileCopyWithImpl<$Res>
    implements _$BasketballProfileCopyWith<$Res> {
  __$BasketballProfileCopyWithImpl(this._self, this._then);

  final _BasketballProfile _self;
  final $Res Function(_BasketballProfile) _then;

/// Create a copy of BasketballProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? position = freezed,Object? pitch = freezed,Object? eloSeed = freezed,}) {
  return _then(_BasketballProfile(
position: freezed == position ? _self._position : position // ignore: cast_nullable_to_non_nullable
as List<BasketballPosition>?,pitch: freezed == pitch ? _self._pitch : pitch // ignore: cast_nullable_to_non_nullable
as List<BasketballPitch>?,eloSeed: freezed == eloSeed ? _self.eloSeed : eloSeed // ignore: cast_nullable_to_non_nullable
as EloSeed?,
  ));
}


}


/// @nodoc
mixin _$BadmintonProfile {

@JsonKey(name: 'dominant_hand') DominantHand? get dominantHand; List<RacketDiscipline>? get discipline;@JsonKey(name: 'elo_seed') EloSeed? get eloSeed;
/// Create a copy of BadmintonProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BadmintonProfileCopyWith<BadmintonProfile> get copyWith => _$BadmintonProfileCopyWithImpl<BadmintonProfile>(this as BadmintonProfile, _$identity);

  /// Serializes this BadmintonProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BadmintonProfile&&(identical(other.dominantHand, dominantHand) || other.dominantHand == dominantHand)&&const DeepCollectionEquality().equals(other.discipline, discipline)&&(identical(other.eloSeed, eloSeed) || other.eloSeed == eloSeed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,dominantHand,const DeepCollectionEquality().hash(discipline),eloSeed);

@override
String toString() {
  return 'BadmintonProfile(dominantHand: $dominantHand, discipline: $discipline, eloSeed: $eloSeed)';
}


}

/// @nodoc
abstract mixin class $BadmintonProfileCopyWith<$Res>  {
  factory $BadmintonProfileCopyWith(BadmintonProfile value, $Res Function(BadmintonProfile) _then) = _$BadmintonProfileCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'dominant_hand') DominantHand? dominantHand, List<RacketDiscipline>? discipline,@JsonKey(name: 'elo_seed') EloSeed? eloSeed
});




}
/// @nodoc
class _$BadmintonProfileCopyWithImpl<$Res>
    implements $BadmintonProfileCopyWith<$Res> {
  _$BadmintonProfileCopyWithImpl(this._self, this._then);

  final BadmintonProfile _self;
  final $Res Function(BadmintonProfile) _then;

/// Create a copy of BadmintonProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dominantHand = freezed,Object? discipline = freezed,Object? eloSeed = freezed,}) {
  return _then(_self.copyWith(
dominantHand: freezed == dominantHand ? _self.dominantHand : dominantHand // ignore: cast_nullable_to_non_nullable
as DominantHand?,discipline: freezed == discipline ? _self.discipline : discipline // ignore: cast_nullable_to_non_nullable
as List<RacketDiscipline>?,eloSeed: freezed == eloSeed ? _self.eloSeed : eloSeed // ignore: cast_nullable_to_non_nullable
as EloSeed?,
  ));
}

}


/// Adds pattern-matching-related methods to [BadmintonProfile].
extension BadmintonProfilePatterns on BadmintonProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BadmintonProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BadmintonProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BadmintonProfile value)  $default,){
final _that = this;
switch (_that) {
case _BadmintonProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BadmintonProfile value)?  $default,){
final _that = this;
switch (_that) {
case _BadmintonProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'dominant_hand')  DominantHand? dominantHand,  List<RacketDiscipline>? discipline, @JsonKey(name: 'elo_seed')  EloSeed? eloSeed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BadmintonProfile() when $default != null:
return $default(_that.dominantHand,_that.discipline,_that.eloSeed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'dominant_hand')  DominantHand? dominantHand,  List<RacketDiscipline>? discipline, @JsonKey(name: 'elo_seed')  EloSeed? eloSeed)  $default,) {final _that = this;
switch (_that) {
case _BadmintonProfile():
return $default(_that.dominantHand,_that.discipline,_that.eloSeed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'dominant_hand')  DominantHand? dominantHand,  List<RacketDiscipline>? discipline, @JsonKey(name: 'elo_seed')  EloSeed? eloSeed)?  $default,) {final _that = this;
switch (_that) {
case _BadmintonProfile() when $default != null:
return $default(_that.dominantHand,_that.discipline,_that.eloSeed);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BadmintonProfile implements BadmintonProfile {
  const _BadmintonProfile({@JsonKey(name: 'dominant_hand') this.dominantHand, final  List<RacketDiscipline>? discipline, @JsonKey(name: 'elo_seed') this.eloSeed}): _discipline = discipline;
  factory _BadmintonProfile.fromJson(Map<String, dynamic> json) => _$BadmintonProfileFromJson(json);

@override@JsonKey(name: 'dominant_hand') final  DominantHand? dominantHand;
 final  List<RacketDiscipline>? _discipline;
@override List<RacketDiscipline>? get discipline {
  final value = _discipline;
  if (value == null) return null;
  if (_discipline is EqualUnmodifiableListView) return _discipline;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey(name: 'elo_seed') final  EloSeed? eloSeed;

/// Create a copy of BadmintonProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BadmintonProfileCopyWith<_BadmintonProfile> get copyWith => __$BadmintonProfileCopyWithImpl<_BadmintonProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BadmintonProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BadmintonProfile&&(identical(other.dominantHand, dominantHand) || other.dominantHand == dominantHand)&&const DeepCollectionEquality().equals(other._discipline, _discipline)&&(identical(other.eloSeed, eloSeed) || other.eloSeed == eloSeed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,dominantHand,const DeepCollectionEquality().hash(_discipline),eloSeed);

@override
String toString() {
  return 'BadmintonProfile(dominantHand: $dominantHand, discipline: $discipline, eloSeed: $eloSeed)';
}


}

/// @nodoc
abstract mixin class _$BadmintonProfileCopyWith<$Res> implements $BadmintonProfileCopyWith<$Res> {
  factory _$BadmintonProfileCopyWith(_BadmintonProfile value, $Res Function(_BadmintonProfile) _then) = __$BadmintonProfileCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'dominant_hand') DominantHand? dominantHand, List<RacketDiscipline>? discipline,@JsonKey(name: 'elo_seed') EloSeed? eloSeed
});




}
/// @nodoc
class __$BadmintonProfileCopyWithImpl<$Res>
    implements _$BadmintonProfileCopyWith<$Res> {
  __$BadmintonProfileCopyWithImpl(this._self, this._then);

  final _BadmintonProfile _self;
  final $Res Function(_BadmintonProfile) _then;

/// Create a copy of BadmintonProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? dominantHand = freezed,Object? discipline = freezed,Object? eloSeed = freezed,}) {
  return _then(_BadmintonProfile(
dominantHand: freezed == dominantHand ? _self.dominantHand : dominantHand // ignore: cast_nullable_to_non_nullable
as DominantHand?,discipline: freezed == discipline ? _self._discipline : discipline // ignore: cast_nullable_to_non_nullable
as List<RacketDiscipline>?,eloSeed: freezed == eloSeed ? _self.eloSeed : eloSeed // ignore: cast_nullable_to_non_nullable
as EloSeed?,
  ));
}


}


/// @nodoc
mixin _$TennisProfile {

@JsonKey(name: 'dominant_hand') DominantHand? get dominantHand; List<RacketDiscipline>? get discipline;@JsonKey(name: 'elo_seed') EloSeed? get eloSeed;
/// Create a copy of TennisProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TennisProfileCopyWith<TennisProfile> get copyWith => _$TennisProfileCopyWithImpl<TennisProfile>(this as TennisProfile, _$identity);

  /// Serializes this TennisProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TennisProfile&&(identical(other.dominantHand, dominantHand) || other.dominantHand == dominantHand)&&const DeepCollectionEquality().equals(other.discipline, discipline)&&(identical(other.eloSeed, eloSeed) || other.eloSeed == eloSeed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,dominantHand,const DeepCollectionEquality().hash(discipline),eloSeed);

@override
String toString() {
  return 'TennisProfile(dominantHand: $dominantHand, discipline: $discipline, eloSeed: $eloSeed)';
}


}

/// @nodoc
abstract mixin class $TennisProfileCopyWith<$Res>  {
  factory $TennisProfileCopyWith(TennisProfile value, $Res Function(TennisProfile) _then) = _$TennisProfileCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'dominant_hand') DominantHand? dominantHand, List<RacketDiscipline>? discipline,@JsonKey(name: 'elo_seed') EloSeed? eloSeed
});




}
/// @nodoc
class _$TennisProfileCopyWithImpl<$Res>
    implements $TennisProfileCopyWith<$Res> {
  _$TennisProfileCopyWithImpl(this._self, this._then);

  final TennisProfile _self;
  final $Res Function(TennisProfile) _then;

/// Create a copy of TennisProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dominantHand = freezed,Object? discipline = freezed,Object? eloSeed = freezed,}) {
  return _then(_self.copyWith(
dominantHand: freezed == dominantHand ? _self.dominantHand : dominantHand // ignore: cast_nullable_to_non_nullable
as DominantHand?,discipline: freezed == discipline ? _self.discipline : discipline // ignore: cast_nullable_to_non_nullable
as List<RacketDiscipline>?,eloSeed: freezed == eloSeed ? _self.eloSeed : eloSeed // ignore: cast_nullable_to_non_nullable
as EloSeed?,
  ));
}

}


/// Adds pattern-matching-related methods to [TennisProfile].
extension TennisProfilePatterns on TennisProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TennisProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TennisProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TennisProfile value)  $default,){
final _that = this;
switch (_that) {
case _TennisProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TennisProfile value)?  $default,){
final _that = this;
switch (_that) {
case _TennisProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'dominant_hand')  DominantHand? dominantHand,  List<RacketDiscipline>? discipline, @JsonKey(name: 'elo_seed')  EloSeed? eloSeed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TennisProfile() when $default != null:
return $default(_that.dominantHand,_that.discipline,_that.eloSeed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'dominant_hand')  DominantHand? dominantHand,  List<RacketDiscipline>? discipline, @JsonKey(name: 'elo_seed')  EloSeed? eloSeed)  $default,) {final _that = this;
switch (_that) {
case _TennisProfile():
return $default(_that.dominantHand,_that.discipline,_that.eloSeed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'dominant_hand')  DominantHand? dominantHand,  List<RacketDiscipline>? discipline, @JsonKey(name: 'elo_seed')  EloSeed? eloSeed)?  $default,) {final _that = this;
switch (_that) {
case _TennisProfile() when $default != null:
return $default(_that.dominantHand,_that.discipline,_that.eloSeed);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TennisProfile implements TennisProfile {
  const _TennisProfile({@JsonKey(name: 'dominant_hand') this.dominantHand, final  List<RacketDiscipline>? discipline, @JsonKey(name: 'elo_seed') this.eloSeed}): _discipline = discipline;
  factory _TennisProfile.fromJson(Map<String, dynamic> json) => _$TennisProfileFromJson(json);

@override@JsonKey(name: 'dominant_hand') final  DominantHand? dominantHand;
 final  List<RacketDiscipline>? _discipline;
@override List<RacketDiscipline>? get discipline {
  final value = _discipline;
  if (value == null) return null;
  if (_discipline is EqualUnmodifiableListView) return _discipline;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey(name: 'elo_seed') final  EloSeed? eloSeed;

/// Create a copy of TennisProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TennisProfileCopyWith<_TennisProfile> get copyWith => __$TennisProfileCopyWithImpl<_TennisProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TennisProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TennisProfile&&(identical(other.dominantHand, dominantHand) || other.dominantHand == dominantHand)&&const DeepCollectionEquality().equals(other._discipline, _discipline)&&(identical(other.eloSeed, eloSeed) || other.eloSeed == eloSeed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,dominantHand,const DeepCollectionEquality().hash(_discipline),eloSeed);

@override
String toString() {
  return 'TennisProfile(dominantHand: $dominantHand, discipline: $discipline, eloSeed: $eloSeed)';
}


}

/// @nodoc
abstract mixin class _$TennisProfileCopyWith<$Res> implements $TennisProfileCopyWith<$Res> {
  factory _$TennisProfileCopyWith(_TennisProfile value, $Res Function(_TennisProfile) _then) = __$TennisProfileCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'dominant_hand') DominantHand? dominantHand, List<RacketDiscipline>? discipline,@JsonKey(name: 'elo_seed') EloSeed? eloSeed
});




}
/// @nodoc
class __$TennisProfileCopyWithImpl<$Res>
    implements _$TennisProfileCopyWith<$Res> {
  __$TennisProfileCopyWithImpl(this._self, this._then);

  final _TennisProfile _self;
  final $Res Function(_TennisProfile) _then;

/// Create a copy of TennisProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? dominantHand = freezed,Object? discipline = freezed,Object? eloSeed = freezed,}) {
  return _then(_TennisProfile(
dominantHand: freezed == dominantHand ? _self.dominantHand : dominantHand // ignore: cast_nullable_to_non_nullable
as DominantHand?,discipline: freezed == discipline ? _self._discipline : discipline // ignore: cast_nullable_to_non_nullable
as List<RacketDiscipline>?,eloSeed: freezed == eloSeed ? _self.eloSeed : eloSeed // ignore: cast_nullable_to_non_nullable
as EloSeed?,
  ));
}


}


/// @nodoc
mixin _$PickleballProfile {

@JsonKey(name: 'dominant_hand') DominantHand? get dominantHand; List<RacketDiscipline>? get discipline;@JsonKey(name: 'elo_seed') EloSeed? get eloSeed;
/// Create a copy of PickleballProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PickleballProfileCopyWith<PickleballProfile> get copyWith => _$PickleballProfileCopyWithImpl<PickleballProfile>(this as PickleballProfile, _$identity);

  /// Serializes this PickleballProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PickleballProfile&&(identical(other.dominantHand, dominantHand) || other.dominantHand == dominantHand)&&const DeepCollectionEquality().equals(other.discipline, discipline)&&(identical(other.eloSeed, eloSeed) || other.eloSeed == eloSeed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,dominantHand,const DeepCollectionEquality().hash(discipline),eloSeed);

@override
String toString() {
  return 'PickleballProfile(dominantHand: $dominantHand, discipline: $discipline, eloSeed: $eloSeed)';
}


}

/// @nodoc
abstract mixin class $PickleballProfileCopyWith<$Res>  {
  factory $PickleballProfileCopyWith(PickleballProfile value, $Res Function(PickleballProfile) _then) = _$PickleballProfileCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'dominant_hand') DominantHand? dominantHand, List<RacketDiscipline>? discipline,@JsonKey(name: 'elo_seed') EloSeed? eloSeed
});




}
/// @nodoc
class _$PickleballProfileCopyWithImpl<$Res>
    implements $PickleballProfileCopyWith<$Res> {
  _$PickleballProfileCopyWithImpl(this._self, this._then);

  final PickleballProfile _self;
  final $Res Function(PickleballProfile) _then;

/// Create a copy of PickleballProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dominantHand = freezed,Object? discipline = freezed,Object? eloSeed = freezed,}) {
  return _then(_self.copyWith(
dominantHand: freezed == dominantHand ? _self.dominantHand : dominantHand // ignore: cast_nullable_to_non_nullable
as DominantHand?,discipline: freezed == discipline ? _self.discipline : discipline // ignore: cast_nullable_to_non_nullable
as List<RacketDiscipline>?,eloSeed: freezed == eloSeed ? _self.eloSeed : eloSeed // ignore: cast_nullable_to_non_nullable
as EloSeed?,
  ));
}

}


/// Adds pattern-matching-related methods to [PickleballProfile].
extension PickleballProfilePatterns on PickleballProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PickleballProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PickleballProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PickleballProfile value)  $default,){
final _that = this;
switch (_that) {
case _PickleballProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PickleballProfile value)?  $default,){
final _that = this;
switch (_that) {
case _PickleballProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'dominant_hand')  DominantHand? dominantHand,  List<RacketDiscipline>? discipline, @JsonKey(name: 'elo_seed')  EloSeed? eloSeed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PickleballProfile() when $default != null:
return $default(_that.dominantHand,_that.discipline,_that.eloSeed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'dominant_hand')  DominantHand? dominantHand,  List<RacketDiscipline>? discipline, @JsonKey(name: 'elo_seed')  EloSeed? eloSeed)  $default,) {final _that = this;
switch (_that) {
case _PickleballProfile():
return $default(_that.dominantHand,_that.discipline,_that.eloSeed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'dominant_hand')  DominantHand? dominantHand,  List<RacketDiscipline>? discipline, @JsonKey(name: 'elo_seed')  EloSeed? eloSeed)?  $default,) {final _that = this;
switch (_that) {
case _PickleballProfile() when $default != null:
return $default(_that.dominantHand,_that.discipline,_that.eloSeed);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PickleballProfile implements PickleballProfile {
  const _PickleballProfile({@JsonKey(name: 'dominant_hand') this.dominantHand, final  List<RacketDiscipline>? discipline, @JsonKey(name: 'elo_seed') this.eloSeed}): _discipline = discipline;
  factory _PickleballProfile.fromJson(Map<String, dynamic> json) => _$PickleballProfileFromJson(json);

@override@JsonKey(name: 'dominant_hand') final  DominantHand? dominantHand;
 final  List<RacketDiscipline>? _discipline;
@override List<RacketDiscipline>? get discipline {
  final value = _discipline;
  if (value == null) return null;
  if (_discipline is EqualUnmodifiableListView) return _discipline;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey(name: 'elo_seed') final  EloSeed? eloSeed;

/// Create a copy of PickleballProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PickleballProfileCopyWith<_PickleballProfile> get copyWith => __$PickleballProfileCopyWithImpl<_PickleballProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PickleballProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PickleballProfile&&(identical(other.dominantHand, dominantHand) || other.dominantHand == dominantHand)&&const DeepCollectionEquality().equals(other._discipline, _discipline)&&(identical(other.eloSeed, eloSeed) || other.eloSeed == eloSeed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,dominantHand,const DeepCollectionEquality().hash(_discipline),eloSeed);

@override
String toString() {
  return 'PickleballProfile(dominantHand: $dominantHand, discipline: $discipline, eloSeed: $eloSeed)';
}


}

/// @nodoc
abstract mixin class _$PickleballProfileCopyWith<$Res> implements $PickleballProfileCopyWith<$Res> {
  factory _$PickleballProfileCopyWith(_PickleballProfile value, $Res Function(_PickleballProfile) _then) = __$PickleballProfileCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'dominant_hand') DominantHand? dominantHand, List<RacketDiscipline>? discipline,@JsonKey(name: 'elo_seed') EloSeed? eloSeed
});




}
/// @nodoc
class __$PickleballProfileCopyWithImpl<$Res>
    implements _$PickleballProfileCopyWith<$Res> {
  __$PickleballProfileCopyWithImpl(this._self, this._then);

  final _PickleballProfile _self;
  final $Res Function(_PickleballProfile) _then;

/// Create a copy of PickleballProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? dominantHand = freezed,Object? discipline = freezed,Object? eloSeed = freezed,}) {
  return _then(_PickleballProfile(
dominantHand: freezed == dominantHand ? _self.dominantHand : dominantHand // ignore: cast_nullable_to_non_nullable
as DominantHand?,discipline: freezed == discipline ? _self._discipline : discipline // ignore: cast_nullable_to_non_nullable
as List<RacketDiscipline>?,eloSeed: freezed == eloSeed ? _self.eloSeed : eloSeed // ignore: cast_nullable_to_non_nullable
as EloSeed?,
  ));
}


}

// dart format on
