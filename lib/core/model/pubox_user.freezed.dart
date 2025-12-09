// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pubox_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PuboxUser {

 String? get id; String get displayName; String? get email; UserDetails? get details;
/// Create a copy of PuboxUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PuboxUserCopyWith<PuboxUser> get copyWith => _$PuboxUserCopyWithImpl<PuboxUser>(this as PuboxUser, _$identity);

  /// Serializes this PuboxUser to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PuboxUser&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.email, email) || other.email == email)&&(identical(other.details, details) || other.details == details));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,email,details);

@override
String toString() {
  return 'PuboxUser(id: $id, displayName: $displayName, email: $email, details: $details)';
}


}

/// @nodoc
abstract mixin class $PuboxUserCopyWith<$Res>  {
  factory $PuboxUserCopyWith(PuboxUser value, $Res Function(PuboxUser) _then) = _$PuboxUserCopyWithImpl;
@useResult
$Res call({
 String? id, String displayName, String? email, UserDetails? details
});


$UserDetailsCopyWith<$Res>? get details;

}
/// @nodoc
class _$PuboxUserCopyWithImpl<$Res>
    implements $PuboxUserCopyWith<$Res> {
  _$PuboxUserCopyWithImpl(this._self, this._then);

  final PuboxUser _self;
  final $Res Function(PuboxUser) _then;

/// Create a copy of PuboxUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? displayName = null,Object? email = freezed,Object? details = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,details: freezed == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as UserDetails?,
  ));
}
/// Create a copy of PuboxUser
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserDetailsCopyWith<$Res>? get details {
    if (_self.details == null) {
    return null;
  }

  return $UserDetailsCopyWith<$Res>(_self.details!, (value) {
    return _then(_self.copyWith(details: value));
  });
}
}


/// Adds pattern-matching-related methods to [PuboxUser].
extension PuboxUserPatterns on PuboxUser {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PuboxUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PuboxUser() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PuboxUser value)  $default,){
final _that = this;
switch (_that) {
case _PuboxUser():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PuboxUser value)?  $default,){
final _that = this;
switch (_that) {
case _PuboxUser() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? id,  String displayName,  String? email,  UserDetails? details)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PuboxUser() when $default != null:
return $default(_that.id,_that.displayName,_that.email,_that.details);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? id,  String displayName,  String? email,  UserDetails? details)  $default,) {final _that = this;
switch (_that) {
case _PuboxUser():
return $default(_that.id,_that.displayName,_that.email,_that.details);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? id,  String displayName,  String? email,  UserDetails? details)?  $default,) {final _that = this;
switch (_that) {
case _PuboxUser() when $default != null:
return $default(_that.id,_that.displayName,_that.email,_that.details);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PuboxUser implements PuboxUser {
  const _PuboxUser({this.id, this.displayName = 'Guest', this.email, this.details});
  factory _PuboxUser.fromJson(Map<String, dynamic> json) => _$PuboxUserFromJson(json);

@override final  String? id;
@override@JsonKey() final  String displayName;
@override final  String? email;
@override final  UserDetails? details;

/// Create a copy of PuboxUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PuboxUserCopyWith<_PuboxUser> get copyWith => __$PuboxUserCopyWithImpl<_PuboxUser>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PuboxUserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PuboxUser&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.email, email) || other.email == email)&&(identical(other.details, details) || other.details == details));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,email,details);

@override
String toString() {
  return 'PuboxUser(id: $id, displayName: $displayName, email: $email, details: $details)';
}


}

/// @nodoc
abstract mixin class _$PuboxUserCopyWith<$Res> implements $PuboxUserCopyWith<$Res> {
  factory _$PuboxUserCopyWith(_PuboxUser value, $Res Function(_PuboxUser) _then) = __$PuboxUserCopyWithImpl;
@override @useResult
$Res call({
 String? id, String displayName, String? email, UserDetails? details
});


@override $UserDetailsCopyWith<$Res>? get details;

}
/// @nodoc
class __$PuboxUserCopyWithImpl<$Res>
    implements _$PuboxUserCopyWith<$Res> {
  __$PuboxUserCopyWithImpl(this._self, this._then);

  final _PuboxUser _self;
  final $Res Function(_PuboxUser) _then;

/// Create a copy of PuboxUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? displayName = null,Object? email = freezed,Object? details = freezed,}) {
  return _then(_PuboxUser(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,details: freezed == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as UserDetails?,
  ));
}

/// Create a copy of PuboxUser
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserDetailsCopyWith<$Res>? get details {
    if (_self.details == null) {
    return null;
  }

  return $UserDetailsCopyWith<$Res>(_self.details!, (value) {
    return _then(_self.copyWith(details: value));
  });
}
}

// dart format on
