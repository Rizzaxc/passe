// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_health_link.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserHealthLink {

@JsonKey(name: 'user_id') String get userId; HealthPlatform get platform;@JsonKey(name: 'linked_at') DateTime get linkedAt;@JsonKey(name: 'last_sync_at') DateTime? get lastSyncAt;
/// Create a copy of UserHealthLink
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserHealthLinkCopyWith<UserHealthLink> get copyWith => _$UserHealthLinkCopyWithImpl<UserHealthLink>(this as UserHealthLink, _$identity);

  /// Serializes this UserHealthLink to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserHealthLink&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.linkedAt, linkedAt) || other.linkedAt == linkedAt)&&(identical(other.lastSyncAt, lastSyncAt) || other.lastSyncAt == lastSyncAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,platform,linkedAt,lastSyncAt);

@override
String toString() {
  return 'UserHealthLink(userId: $userId, platform: $platform, linkedAt: $linkedAt, lastSyncAt: $lastSyncAt)';
}


}

/// @nodoc
abstract mixin class $UserHealthLinkCopyWith<$Res>  {
  factory $UserHealthLinkCopyWith(UserHealthLink value, $Res Function(UserHealthLink) _then) = _$UserHealthLinkCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'user_id') String userId, HealthPlatform platform,@JsonKey(name: 'linked_at') DateTime linkedAt,@JsonKey(name: 'last_sync_at') DateTime? lastSyncAt
});




}
/// @nodoc
class _$UserHealthLinkCopyWithImpl<$Res>
    implements $UserHealthLinkCopyWith<$Res> {
  _$UserHealthLinkCopyWithImpl(this._self, this._then);

  final UserHealthLink _self;
  final $Res Function(UserHealthLink) _then;

/// Create a copy of UserHealthLink
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? platform = null,Object? linkedAt = null,Object? lastSyncAt = freezed,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as HealthPlatform,linkedAt: null == linkedAt ? _self.linkedAt : linkedAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastSyncAt: freezed == lastSyncAt ? _self.lastSyncAt : lastSyncAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [UserHealthLink].
extension UserHealthLinkPatterns on UserHealthLink {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserHealthLink value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserHealthLink() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserHealthLink value)  $default,){
final _that = this;
switch (_that) {
case _UserHealthLink():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserHealthLink value)?  $default,){
final _that = this;
switch (_that) {
case _UserHealthLink() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'user_id')  String userId,  HealthPlatform platform, @JsonKey(name: 'linked_at')  DateTime linkedAt, @JsonKey(name: 'last_sync_at')  DateTime? lastSyncAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserHealthLink() when $default != null:
return $default(_that.userId,_that.platform,_that.linkedAt,_that.lastSyncAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'user_id')  String userId,  HealthPlatform platform, @JsonKey(name: 'linked_at')  DateTime linkedAt, @JsonKey(name: 'last_sync_at')  DateTime? lastSyncAt)  $default,) {final _that = this;
switch (_that) {
case _UserHealthLink():
return $default(_that.userId,_that.platform,_that.linkedAt,_that.lastSyncAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'user_id')  String userId,  HealthPlatform platform, @JsonKey(name: 'linked_at')  DateTime linkedAt, @JsonKey(name: 'last_sync_at')  DateTime? lastSyncAt)?  $default,) {final _that = this;
switch (_that) {
case _UserHealthLink() when $default != null:
return $default(_that.userId,_that.platform,_that.linkedAt,_that.lastSyncAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserHealthLink implements UserHealthLink {
  const _UserHealthLink({@JsonKey(name: 'user_id') required this.userId, required this.platform, @JsonKey(name: 'linked_at') required this.linkedAt, @JsonKey(name: 'last_sync_at') this.lastSyncAt});
  factory _UserHealthLink.fromJson(Map<String, dynamic> json) => _$UserHealthLinkFromJson(json);

@override@JsonKey(name: 'user_id') final  String userId;
@override final  HealthPlatform platform;
@override@JsonKey(name: 'linked_at') final  DateTime linkedAt;
@override@JsonKey(name: 'last_sync_at') final  DateTime? lastSyncAt;

/// Create a copy of UserHealthLink
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserHealthLinkCopyWith<_UserHealthLink> get copyWith => __$UserHealthLinkCopyWithImpl<_UserHealthLink>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserHealthLinkToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserHealthLink&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.linkedAt, linkedAt) || other.linkedAt == linkedAt)&&(identical(other.lastSyncAt, lastSyncAt) || other.lastSyncAt == lastSyncAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,platform,linkedAt,lastSyncAt);

@override
String toString() {
  return 'UserHealthLink(userId: $userId, platform: $platform, linkedAt: $linkedAt, lastSyncAt: $lastSyncAt)';
}


}

/// @nodoc
abstract mixin class _$UserHealthLinkCopyWith<$Res> implements $UserHealthLinkCopyWith<$Res> {
  factory _$UserHealthLinkCopyWith(_UserHealthLink value, $Res Function(_UserHealthLink) _then) = __$UserHealthLinkCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'user_id') String userId, HealthPlatform platform,@JsonKey(name: 'linked_at') DateTime linkedAt,@JsonKey(name: 'last_sync_at') DateTime? lastSyncAt
});




}
/// @nodoc
class __$UserHealthLinkCopyWithImpl<$Res>
    implements _$UserHealthLinkCopyWith<$Res> {
  __$UserHealthLinkCopyWithImpl(this._self, this._then);

  final _UserHealthLink _self;
  final $Res Function(_UserHealthLink) _then;

/// Create a copy of UserHealthLink
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? platform = null,Object? linkedAt = null,Object? lastSyncAt = freezed,}) {
  return _then(_UserHealthLink(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as HealthPlatform,linkedAt: null == linkedAt ? _self.linkedAt : linkedAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastSyncAt: freezed == lastSyncAt ? _self.lastSyncAt : lastSyncAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
