// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_details.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SportProfile {

 int? get skill;
/// Create a copy of SportProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SportProfileCopyWith<SportProfile> get copyWith => _$SportProfileCopyWithImpl<SportProfile>(this as SportProfile, _$identity);

  /// Serializes this SportProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SportProfile&&(identical(other.skill, skill) || other.skill == skill));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,skill);

@override
String toString() {
  return 'SportProfile(skill: $skill)';
}


}

/// @nodoc
abstract mixin class $SportProfileCopyWith<$Res>  {
  factory $SportProfileCopyWith(SportProfile value, $Res Function(SportProfile) _then) = _$SportProfileCopyWithImpl;
@useResult
$Res call({
 int? skill
});




}
/// @nodoc
class _$SportProfileCopyWithImpl<$Res>
    implements $SportProfileCopyWith<$Res> {
  _$SportProfileCopyWithImpl(this._self, this._then);

  final SportProfile _self;
  final $Res Function(SportProfile) _then;

/// Create a copy of SportProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? skill = freezed,}) {
  return _then(_self.copyWith(
skill: freezed == skill ? _self.skill : skill // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [SportProfile].
extension SportProfilePatterns on SportProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SportProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SportProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SportProfile value)  $default,){
final _that = this;
switch (_that) {
case _SportProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SportProfile value)?  $default,){
final _that = this;
switch (_that) {
case _SportProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? skill)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SportProfile() when $default != null:
return $default(_that.skill);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? skill)  $default,) {final _that = this;
switch (_that) {
case _SportProfile():
return $default(_that.skill);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? skill)?  $default,) {final _that = this;
switch (_that) {
case _SportProfile() when $default != null:
return $default(_that.skill);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SportProfile implements SportProfile {
  const _SportProfile({this.skill});
  factory _SportProfile.fromJson(Map<String, dynamic> json) => _$SportProfileFromJson(json);

@override final  int? skill;

/// Create a copy of SportProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SportProfileCopyWith<_SportProfile> get copyWith => __$SportProfileCopyWithImpl<_SportProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SportProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SportProfile&&(identical(other.skill, skill) || other.skill == skill));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,skill);

@override
String toString() {
  return 'SportProfile(skill: $skill)';
}


}

/// @nodoc
abstract mixin class _$SportProfileCopyWith<$Res> implements $SportProfileCopyWith<$Res> {
  factory _$SportProfileCopyWith(_SportProfile value, $Res Function(_SportProfile) _then) = __$SportProfileCopyWithImpl;
@override @useResult
$Res call({
 int? skill
});




}
/// @nodoc
class __$SportProfileCopyWithImpl<$Res>
    implements _$SportProfileCopyWith<$Res> {
  __$SportProfileCopyWithImpl(this._self, this._then);

  final _SportProfile _self;
  final $Res Function(_SportProfile) _then;

/// Create a copy of SportProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? skill = freezed,}) {
  return _then(_SportProfile(
skill: freezed == skill ? _self.skill : skill // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$UserDetails {

 Gender? get gender; AgeGroup? get ageGroup; List<Timeslot>? get playtime; UserLocation? get location; Map<String, SportProfile>? get sport;
/// Create a copy of UserDetails
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserDetailsCopyWith<UserDetails> get copyWith => _$UserDetailsCopyWithImpl<UserDetails>(this as UserDetails, _$identity);

  /// Serializes this UserDetails to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserDetails&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.ageGroup, ageGroup) || other.ageGroup == ageGroup)&&const DeepCollectionEquality().equals(other.playtime, playtime)&&(identical(other.location, location) || other.location == location)&&const DeepCollectionEquality().equals(other.sport, sport));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,gender,ageGroup,const DeepCollectionEquality().hash(playtime),location,const DeepCollectionEquality().hash(sport));

@override
String toString() {
  return 'UserDetails(gender: $gender, ageGroup: $ageGroup, playtime: $playtime, location: $location, sport: $sport)';
}


}

/// @nodoc
abstract mixin class $UserDetailsCopyWith<$Res>  {
  factory $UserDetailsCopyWith(UserDetails value, $Res Function(UserDetails) _then) = _$UserDetailsCopyWithImpl;
@useResult
$Res call({
 Gender? gender, AgeGroup? ageGroup, List<Timeslot>? playtime, UserLocation? location, Map<String, SportProfile>? sport
});


$UserLocationCopyWith<$Res>? get location;

}
/// @nodoc
class _$UserDetailsCopyWithImpl<$Res>
    implements $UserDetailsCopyWith<$Res> {
  _$UserDetailsCopyWithImpl(this._self, this._then);

  final UserDetails _self;
  final $Res Function(UserDetails) _then;

/// Create a copy of UserDetails
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? gender = freezed,Object? ageGroup = freezed,Object? playtime = freezed,Object? location = freezed,Object? sport = freezed,}) {
  return _then(_self.copyWith(
gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as Gender?,ageGroup: freezed == ageGroup ? _self.ageGroup : ageGroup // ignore: cast_nullable_to_non_nullable
as AgeGroup?,playtime: freezed == playtime ? _self.playtime : playtime // ignore: cast_nullable_to_non_nullable
as List<Timeslot>?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as UserLocation?,sport: freezed == sport ? _self.sport : sport // ignore: cast_nullable_to_non_nullable
as Map<String, SportProfile>?,
  ));
}
/// Create a copy of UserDetails
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserLocationCopyWith<$Res>? get location {
    if (_self.location == null) {
    return null;
  }

  return $UserLocationCopyWith<$Res>(_self.location!, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}


/// Adds pattern-matching-related methods to [UserDetails].
extension UserDetailsPatterns on UserDetails {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserDetails value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserDetails() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserDetails value)  $default,){
final _that = this;
switch (_that) {
case _UserDetails():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserDetails value)?  $default,){
final _that = this;
switch (_that) {
case _UserDetails() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Gender? gender,  AgeGroup? ageGroup,  List<Timeslot>? playtime,  UserLocation? location,  Map<String, SportProfile>? sport)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserDetails() when $default != null:
return $default(_that.gender,_that.ageGroup,_that.playtime,_that.location,_that.sport);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Gender? gender,  AgeGroup? ageGroup,  List<Timeslot>? playtime,  UserLocation? location,  Map<String, SportProfile>? sport)  $default,) {final _that = this;
switch (_that) {
case _UserDetails():
return $default(_that.gender,_that.ageGroup,_that.playtime,_that.location,_that.sport);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Gender? gender,  AgeGroup? ageGroup,  List<Timeslot>? playtime,  UserLocation? location,  Map<String, SportProfile>? sport)?  $default,) {final _that = this;
switch (_that) {
case _UserDetails() when $default != null:
return $default(_that.gender,_that.ageGroup,_that.playtime,_that.location,_that.sport);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserDetails implements UserDetails {
  const _UserDetails({this.gender, this.ageGroup, final  List<Timeslot>? playtime, this.location, final  Map<String, SportProfile>? sport}): _playtime = playtime,_sport = sport;
  factory _UserDetails.fromJson(Map<String, dynamic> json) => _$UserDetailsFromJson(json);

@override final  Gender? gender;
@override final  AgeGroup? ageGroup;
 final  List<Timeslot>? _playtime;
@override List<Timeslot>? get playtime {
  final value = _playtime;
  if (value == null) return null;
  if (_playtime is EqualUnmodifiableListView) return _playtime;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  UserLocation? location;
 final  Map<String, SportProfile>? _sport;
@override Map<String, SportProfile>? get sport {
  final value = _sport;
  if (value == null) return null;
  if (_sport is EqualUnmodifiableMapView) return _sport;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of UserDetails
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserDetailsCopyWith<_UserDetails> get copyWith => __$UserDetailsCopyWithImpl<_UserDetails>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserDetailsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserDetails&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.ageGroup, ageGroup) || other.ageGroup == ageGroup)&&const DeepCollectionEquality().equals(other._playtime, _playtime)&&(identical(other.location, location) || other.location == location)&&const DeepCollectionEquality().equals(other._sport, _sport));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,gender,ageGroup,const DeepCollectionEquality().hash(_playtime),location,const DeepCollectionEquality().hash(_sport));

@override
String toString() {
  return 'UserDetails(gender: $gender, ageGroup: $ageGroup, playtime: $playtime, location: $location, sport: $sport)';
}


}

/// @nodoc
abstract mixin class _$UserDetailsCopyWith<$Res> implements $UserDetailsCopyWith<$Res> {
  factory _$UserDetailsCopyWith(_UserDetails value, $Res Function(_UserDetails) _then) = __$UserDetailsCopyWithImpl;
@override @useResult
$Res call({
 Gender? gender, AgeGroup? ageGroup, List<Timeslot>? playtime, UserLocation? location, Map<String, SportProfile>? sport
});


@override $UserLocationCopyWith<$Res>? get location;

}
/// @nodoc
class __$UserDetailsCopyWithImpl<$Res>
    implements _$UserDetailsCopyWith<$Res> {
  __$UserDetailsCopyWithImpl(this._self, this._then);

  final _UserDetails _self;
  final $Res Function(_UserDetails) _then;

/// Create a copy of UserDetails
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? gender = freezed,Object? ageGroup = freezed,Object? playtime = freezed,Object? location = freezed,Object? sport = freezed,}) {
  return _then(_UserDetails(
gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as Gender?,ageGroup: freezed == ageGroup ? _self.ageGroup : ageGroup // ignore: cast_nullable_to_non_nullable
as AgeGroup?,playtime: freezed == playtime ? _self._playtime : playtime // ignore: cast_nullable_to_non_nullable
as List<Timeslot>?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as UserLocation?,sport: freezed == sport ? _self._sport : sport // ignore: cast_nullable_to_non_nullable
as Map<String, SportProfile>?,
  ));
}

/// Create a copy of UserDetails
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserLocationCopyWith<$Res>? get location {
    if (_self.location == null) {
    return null;
  }

  return $UserLocationCopyWith<$Res>(_self.location!, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}

// dart format on
