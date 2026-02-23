// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lobby.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LobbyDetails {

 AgeGroup? get ageGroup; int? get skill;
/// Create a copy of LobbyDetails
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LobbyDetailsCopyWith<LobbyDetails> get copyWith => _$LobbyDetailsCopyWithImpl<LobbyDetails>(this as LobbyDetails, _$identity);

  /// Serializes this LobbyDetails to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LobbyDetails&&(identical(other.ageGroup, ageGroup) || other.ageGroup == ageGroup)&&(identical(other.skill, skill) || other.skill == skill));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ageGroup,skill);

@override
String toString() {
  return 'LobbyDetails(ageGroup: $ageGroup, skill: $skill)';
}


}

/// @nodoc
abstract mixin class $LobbyDetailsCopyWith<$Res>  {
  factory $LobbyDetailsCopyWith(LobbyDetails value, $Res Function(LobbyDetails) _then) = _$LobbyDetailsCopyWithImpl;
@useResult
$Res call({
 AgeGroup? ageGroup, int? skill
});




}
/// @nodoc
class _$LobbyDetailsCopyWithImpl<$Res>
    implements $LobbyDetailsCopyWith<$Res> {
  _$LobbyDetailsCopyWithImpl(this._self, this._then);

  final LobbyDetails _self;
  final $Res Function(LobbyDetails) _then;

/// Create a copy of LobbyDetails
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ageGroup = freezed,Object? skill = freezed,}) {
  return _then(_self.copyWith(
ageGroup: freezed == ageGroup ? _self.ageGroup : ageGroup // ignore: cast_nullable_to_non_nullable
as AgeGroup?,skill: freezed == skill ? _self.skill : skill // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [LobbyDetails].
extension LobbyDetailsPatterns on LobbyDetails {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LobbyDetails value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LobbyDetails() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LobbyDetails value)  $default,){
final _that = this;
switch (_that) {
case _LobbyDetails():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LobbyDetails value)?  $default,){
final _that = this;
switch (_that) {
case _LobbyDetails() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AgeGroup? ageGroup,  int? skill)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LobbyDetails() when $default != null:
return $default(_that.ageGroup,_that.skill);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AgeGroup? ageGroup,  int? skill)  $default,) {final _that = this;
switch (_that) {
case _LobbyDetails():
return $default(_that.ageGroup,_that.skill);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AgeGroup? ageGroup,  int? skill)?  $default,) {final _that = this;
switch (_that) {
case _LobbyDetails() when $default != null:
return $default(_that.ageGroup,_that.skill);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LobbyDetails implements LobbyDetails {
  const _LobbyDetails({this.ageGroup, this.skill});
  factory _LobbyDetails.fromJson(Map<String, dynamic> json) => _$LobbyDetailsFromJson(json);

@override final  AgeGroup? ageGroup;
@override final  int? skill;

/// Create a copy of LobbyDetails
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LobbyDetailsCopyWith<_LobbyDetails> get copyWith => __$LobbyDetailsCopyWithImpl<_LobbyDetails>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LobbyDetailsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LobbyDetails&&(identical(other.ageGroup, ageGroup) || other.ageGroup == ageGroup)&&(identical(other.skill, skill) || other.skill == skill));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ageGroup,skill);

@override
String toString() {
  return 'LobbyDetails(ageGroup: $ageGroup, skill: $skill)';
}


}

/// @nodoc
abstract mixin class _$LobbyDetailsCopyWith<$Res> implements $LobbyDetailsCopyWith<$Res> {
  factory _$LobbyDetailsCopyWith(_LobbyDetails value, $Res Function(_LobbyDetails) _then) = __$LobbyDetailsCopyWithImpl;
@override @useResult
$Res call({
 AgeGroup? ageGroup, int? skill
});




}
/// @nodoc
class __$LobbyDetailsCopyWithImpl<$Res>
    implements _$LobbyDetailsCopyWith<$Res> {
  __$LobbyDetailsCopyWithImpl(this._self, this._then);

  final _LobbyDetails _self;
  final $Res Function(_LobbyDetails) _then;

/// Create a copy of LobbyDetails
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ageGroup = freezed,Object? skill = freezed,}) {
  return _then(_LobbyDetails(
ageGroup: freezed == ageGroup ? _self.ageGroup : ageGroup // ignore: cast_nullable_to_non_nullable
as AgeGroup?,skill: freezed == skill ? _self.skill : skill // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$Lobby {

 String? get id;@JsonKey(name: 'captain_id') String? get captainId;@JsonKey(name: 'searchable_id') String? get searchableId; String get name;@JsonKey(name: 'sport_id', fromJson: _sportFromJson, toJson: _sportToJson) Sport get sport; List<Timeslot>? get playtime; LobbyDetails? get details;@JsonKey(name: 'home_ground') String? get homeGround; LobbyVisibility get visibility;
/// Create a copy of Lobby
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LobbyCopyWith<Lobby> get copyWith => _$LobbyCopyWithImpl<Lobby>(this as Lobby, _$identity);

  /// Serializes this Lobby to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Lobby&&(identical(other.id, id) || other.id == id)&&(identical(other.captainId, captainId) || other.captainId == captainId)&&(identical(other.searchableId, searchableId) || other.searchableId == searchableId)&&(identical(other.name, name) || other.name == name)&&(identical(other.sport, sport) || other.sport == sport)&&const DeepCollectionEquality().equals(other.playtime, playtime)&&(identical(other.details, details) || other.details == details)&&(identical(other.homeGround, homeGround) || other.homeGround == homeGround)&&(identical(other.visibility, visibility) || other.visibility == visibility));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,captainId,searchableId,name,sport,const DeepCollectionEquality().hash(playtime),details,homeGround,visibility);

@override
String toString() {
  return 'Lobby(id: $id, captainId: $captainId, searchableId: $searchableId, name: $name, sport: $sport, playtime: $playtime, details: $details, homeGround: $homeGround, visibility: $visibility)';
}


}

/// @nodoc
abstract mixin class $LobbyCopyWith<$Res>  {
  factory $LobbyCopyWith(Lobby value, $Res Function(Lobby) _then) = _$LobbyCopyWithImpl;
@useResult
$Res call({
 String? id,@JsonKey(name: 'captain_id') String? captainId,@JsonKey(name: 'searchable_id') String? searchableId, String name,@JsonKey(name: 'sport_id', fromJson: _sportFromJson, toJson: _sportToJson) Sport sport, List<Timeslot>? playtime, LobbyDetails? details,@JsonKey(name: 'home_ground') String? homeGround, LobbyVisibility visibility
});


$LobbyDetailsCopyWith<$Res>? get details;

}
/// @nodoc
class _$LobbyCopyWithImpl<$Res>
    implements $LobbyCopyWith<$Res> {
  _$LobbyCopyWithImpl(this._self, this._then);

  final Lobby _self;
  final $Res Function(Lobby) _then;

/// Create a copy of Lobby
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? captainId = freezed,Object? searchableId = freezed,Object? name = null,Object? sport = null,Object? playtime = freezed,Object? details = freezed,Object? homeGround = freezed,Object? visibility = null,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,captainId: freezed == captainId ? _self.captainId : captainId // ignore: cast_nullable_to_non_nullable
as String?,searchableId: freezed == searchableId ? _self.searchableId : searchableId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sport: null == sport ? _self.sport : sport // ignore: cast_nullable_to_non_nullable
as Sport,playtime: freezed == playtime ? _self.playtime : playtime // ignore: cast_nullable_to_non_nullable
as List<Timeslot>?,details: freezed == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as LobbyDetails?,homeGround: freezed == homeGround ? _self.homeGround : homeGround // ignore: cast_nullable_to_non_nullable
as String?,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as LobbyVisibility,
  ));
}
/// Create a copy of Lobby
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LobbyDetailsCopyWith<$Res>? get details {
    if (_self.details == null) {
    return null;
  }

  return $LobbyDetailsCopyWith<$Res>(_self.details!, (value) {
    return _then(_self.copyWith(details: value));
  });
}
}


/// Adds pattern-matching-related methods to [Lobby].
extension LobbyPatterns on Lobby {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Lobby value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Lobby() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Lobby value)  $default,){
final _that = this;
switch (_that) {
case _Lobby():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Lobby value)?  $default,){
final _that = this;
switch (_that) {
case _Lobby() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? id, @JsonKey(name: 'captain_id')  String? captainId, @JsonKey(name: 'searchable_id')  String? searchableId,  String name, @JsonKey(name: 'sport_id', fromJson: _sportFromJson, toJson: _sportToJson)  Sport sport,  List<Timeslot>? playtime,  LobbyDetails? details, @JsonKey(name: 'home_ground')  String? homeGround,  LobbyVisibility visibility)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Lobby() when $default != null:
return $default(_that.id,_that.captainId,_that.searchableId,_that.name,_that.sport,_that.playtime,_that.details,_that.homeGround,_that.visibility);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? id, @JsonKey(name: 'captain_id')  String? captainId, @JsonKey(name: 'searchable_id')  String? searchableId,  String name, @JsonKey(name: 'sport_id', fromJson: _sportFromJson, toJson: _sportToJson)  Sport sport,  List<Timeslot>? playtime,  LobbyDetails? details, @JsonKey(name: 'home_ground')  String? homeGround,  LobbyVisibility visibility)  $default,) {final _that = this;
switch (_that) {
case _Lobby():
return $default(_that.id,_that.captainId,_that.searchableId,_that.name,_that.sport,_that.playtime,_that.details,_that.homeGround,_that.visibility);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? id, @JsonKey(name: 'captain_id')  String? captainId, @JsonKey(name: 'searchable_id')  String? searchableId,  String name, @JsonKey(name: 'sport_id', fromJson: _sportFromJson, toJson: _sportToJson)  Sport sport,  List<Timeslot>? playtime,  LobbyDetails? details, @JsonKey(name: 'home_ground')  String? homeGround,  LobbyVisibility visibility)?  $default,) {final _that = this;
switch (_that) {
case _Lobby() when $default != null:
return $default(_that.id,_that.captainId,_that.searchableId,_that.name,_that.sport,_that.playtime,_that.details,_that.homeGround,_that.visibility);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Lobby implements Lobby {
  const _Lobby({this.id, @JsonKey(name: 'captain_id') this.captainId, @JsonKey(name: 'searchable_id') this.searchableId, required this.name, @JsonKey(name: 'sport_id', fromJson: _sportFromJson, toJson: _sportToJson) required this.sport, final  List<Timeslot>? playtime, this.details, @JsonKey(name: 'home_ground') this.homeGround, this.visibility = LobbyVisibility.discoverable}): _playtime = playtime;
  factory _Lobby.fromJson(Map<String, dynamic> json) => _$LobbyFromJson(json);

@override final  String? id;
@override@JsonKey(name: 'captain_id') final  String? captainId;
@override@JsonKey(name: 'searchable_id') final  String? searchableId;
@override final  String name;
@override@JsonKey(name: 'sport_id', fromJson: _sportFromJson, toJson: _sportToJson) final  Sport sport;
 final  List<Timeslot>? _playtime;
@override List<Timeslot>? get playtime {
  final value = _playtime;
  if (value == null) return null;
  if (_playtime is EqualUnmodifiableListView) return _playtime;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  LobbyDetails? details;
@override@JsonKey(name: 'home_ground') final  String? homeGround;
@override@JsonKey() final  LobbyVisibility visibility;

/// Create a copy of Lobby
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LobbyCopyWith<_Lobby> get copyWith => __$LobbyCopyWithImpl<_Lobby>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LobbyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Lobby&&(identical(other.id, id) || other.id == id)&&(identical(other.captainId, captainId) || other.captainId == captainId)&&(identical(other.searchableId, searchableId) || other.searchableId == searchableId)&&(identical(other.name, name) || other.name == name)&&(identical(other.sport, sport) || other.sport == sport)&&const DeepCollectionEquality().equals(other._playtime, _playtime)&&(identical(other.details, details) || other.details == details)&&(identical(other.homeGround, homeGround) || other.homeGround == homeGround)&&(identical(other.visibility, visibility) || other.visibility == visibility));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,captainId,searchableId,name,sport,const DeepCollectionEquality().hash(_playtime),details,homeGround,visibility);

@override
String toString() {
  return 'Lobby(id: $id, captainId: $captainId, searchableId: $searchableId, name: $name, sport: $sport, playtime: $playtime, details: $details, homeGround: $homeGround, visibility: $visibility)';
}


}

/// @nodoc
abstract mixin class _$LobbyCopyWith<$Res> implements $LobbyCopyWith<$Res> {
  factory _$LobbyCopyWith(_Lobby value, $Res Function(_Lobby) _then) = __$LobbyCopyWithImpl;
@override @useResult
$Res call({
 String? id,@JsonKey(name: 'captain_id') String? captainId,@JsonKey(name: 'searchable_id') String? searchableId, String name,@JsonKey(name: 'sport_id', fromJson: _sportFromJson, toJson: _sportToJson) Sport sport, List<Timeslot>? playtime, LobbyDetails? details,@JsonKey(name: 'home_ground') String? homeGround, LobbyVisibility visibility
});


@override $LobbyDetailsCopyWith<$Res>? get details;

}
/// @nodoc
class __$LobbyCopyWithImpl<$Res>
    implements _$LobbyCopyWith<$Res> {
  __$LobbyCopyWithImpl(this._self, this._then);

  final _Lobby _self;
  final $Res Function(_Lobby) _then;

/// Create a copy of Lobby
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? captainId = freezed,Object? searchableId = freezed,Object? name = null,Object? sport = null,Object? playtime = freezed,Object? details = freezed,Object? homeGround = freezed,Object? visibility = null,}) {
  return _then(_Lobby(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,captainId: freezed == captainId ? _self.captainId : captainId // ignore: cast_nullable_to_non_nullable
as String?,searchableId: freezed == searchableId ? _self.searchableId : searchableId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sport: null == sport ? _self.sport : sport // ignore: cast_nullable_to_non_nullable
as Sport,playtime: freezed == playtime ? _self._playtime : playtime // ignore: cast_nullable_to_non_nullable
as List<Timeslot>?,details: freezed == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as LobbyDetails?,homeGround: freezed == homeGround ? _self.homeGround : homeGround // ignore: cast_nullable_to_non_nullable
as String?,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as LobbyVisibility,
  ));
}

/// Create a copy of Lobby
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LobbyDetailsCopyWith<$Res>? get details {
    if (_self.details == null) {
    return null;
  }

  return $LobbyDetailsCopyWith<$Res>(_self.details!, (value) {
    return _then(_self.copyWith(details: value));
  });
}
}

// dart format on
