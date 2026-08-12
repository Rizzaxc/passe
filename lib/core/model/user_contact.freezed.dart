// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_contact.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserContact {

 String? get zalo;@JsonKey(name: 'zalo_public') bool get zaloPublic;
/// Create a copy of UserContact
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserContactCopyWith<UserContact> get copyWith => _$UserContactCopyWithImpl<UserContact>(this as UserContact, _$identity);

  /// Serializes this UserContact to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserContact&&(identical(other.zalo, zalo) || other.zalo == zalo)&&(identical(other.zaloPublic, zaloPublic) || other.zaloPublic == zaloPublic));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,zalo,zaloPublic);

@override
String toString() {
  return 'UserContact(zalo: $zalo, zaloPublic: $zaloPublic)';
}


}

/// @nodoc
abstract mixin class $UserContactCopyWith<$Res>  {
  factory $UserContactCopyWith(UserContact value, $Res Function(UserContact) _then) = _$UserContactCopyWithImpl;
@useResult
$Res call({
 String? zalo,@JsonKey(name: 'zalo_public') bool zaloPublic
});




}
/// @nodoc
class _$UserContactCopyWithImpl<$Res>
    implements $UserContactCopyWith<$Res> {
  _$UserContactCopyWithImpl(this._self, this._then);

  final UserContact _self;
  final $Res Function(UserContact) _then;

/// Create a copy of UserContact
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? zalo = freezed,Object? zaloPublic = null,}) {
  return _then(_self.copyWith(
zalo: freezed == zalo ? _self.zalo : zalo // ignore: cast_nullable_to_non_nullable
as String?,zaloPublic: null == zaloPublic ? _self.zaloPublic : zaloPublic // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [UserContact].
extension UserContactPatterns on UserContact {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserContact value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserContact() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserContact value)  $default,){
final _that = this;
switch (_that) {
case _UserContact():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserContact value)?  $default,){
final _that = this;
switch (_that) {
case _UserContact() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? zalo, @JsonKey(name: 'zalo_public')  bool zaloPublic)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserContact() when $default != null:
return $default(_that.zalo,_that.zaloPublic);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? zalo, @JsonKey(name: 'zalo_public')  bool zaloPublic)  $default,) {final _that = this;
switch (_that) {
case _UserContact():
return $default(_that.zalo,_that.zaloPublic);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? zalo, @JsonKey(name: 'zalo_public')  bool zaloPublic)?  $default,) {final _that = this;
switch (_that) {
case _UserContact() when $default != null:
return $default(_that.zalo,_that.zaloPublic);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserContact implements UserContact {
  const _UserContact({this.zalo, @JsonKey(name: 'zalo_public') this.zaloPublic = false});
  factory _UserContact.fromJson(Map<String, dynamic> json) => _$UserContactFromJson(json);

@override final  String? zalo;
@override@JsonKey(name: 'zalo_public') final  bool zaloPublic;

/// Create a copy of UserContact
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserContactCopyWith<_UserContact> get copyWith => __$UserContactCopyWithImpl<_UserContact>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserContactToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserContact&&(identical(other.zalo, zalo) || other.zalo == zalo)&&(identical(other.zaloPublic, zaloPublic) || other.zaloPublic == zaloPublic));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,zalo,zaloPublic);

@override
String toString() {
  return 'UserContact(zalo: $zalo, zaloPublic: $zaloPublic)';
}


}

/// @nodoc
abstract mixin class _$UserContactCopyWith<$Res> implements $UserContactCopyWith<$Res> {
  factory _$UserContactCopyWith(_UserContact value, $Res Function(_UserContact) _then) = __$UserContactCopyWithImpl;
@override @useResult
$Res call({
 String? zalo,@JsonKey(name: 'zalo_public') bool zaloPublic
});




}
/// @nodoc
class __$UserContactCopyWithImpl<$Res>
    implements _$UserContactCopyWith<$Res> {
  __$UserContactCopyWithImpl(this._self, this._then);

  final _UserContact _self;
  final $Res Function(_UserContact) _then;

/// Create a copy of UserContact
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? zalo = freezed,Object? zaloPublic = null,}) {
  return _then(_UserContact(
zalo: freezed == zalo ? _self.zalo : zalo // ignore: cast_nullable_to_non_nullable
as String?,zaloPublic: null == zaloPublic ? _self.zaloPublic : zaloPublic // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
