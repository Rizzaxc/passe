// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'activity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Activity {

 String? get id;@JsonKey(name: 'user_id') String get userId;@JsonKey(name: 'sport_id') int get sportId;@JsonKey(name: 'start_time') DateTime get startTime;@JsonKey(name: 'end_time') DateTime? get endTime;@JsonKey(name: 'lobby_id') String? get lobbyId;@JsonKey(name: 'professional_booking_id') String? get professionalBookingId;@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of Activity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActivityCopyWith<Activity> get copyWith => _$ActivityCopyWithImpl<Activity>(this as Activity, _$identity);

  /// Serializes this Activity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Activity&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.sportId, sportId) || other.sportId == sportId)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.lobbyId, lobbyId) || other.lobbyId == lobbyId)&&(identical(other.professionalBookingId, professionalBookingId) || other.professionalBookingId == professionalBookingId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,sportId,startTime,endTime,lobbyId,professionalBookingId,createdAt);

@override
String toString() {
  return 'Activity(id: $id, userId: $userId, sportId: $sportId, startTime: $startTime, endTime: $endTime, lobbyId: $lobbyId, professionalBookingId: $professionalBookingId, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ActivityCopyWith<$Res>  {
  factory $ActivityCopyWith(Activity value, $Res Function(Activity) _then) = _$ActivityCopyWithImpl;
@useResult
$Res call({
 String? id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'sport_id') int sportId,@JsonKey(name: 'start_time') DateTime startTime,@JsonKey(name: 'end_time') DateTime? endTime,@JsonKey(name: 'lobby_id') String? lobbyId,@JsonKey(name: 'professional_booking_id') String? professionalBookingId,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class _$ActivityCopyWithImpl<$Res>
    implements $ActivityCopyWith<$Res> {
  _$ActivityCopyWithImpl(this._self, this._then);

  final Activity _self;
  final $Res Function(Activity) _then;

/// Create a copy of Activity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? userId = null,Object? sportId = null,Object? startTime = null,Object? endTime = freezed,Object? lobbyId = freezed,Object? professionalBookingId = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,sportId: null == sportId ? _self.sportId : sportId // ignore: cast_nullable_to_non_nullable
as int,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,endTime: freezed == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as DateTime?,lobbyId: freezed == lobbyId ? _self.lobbyId : lobbyId // ignore: cast_nullable_to_non_nullable
as String?,professionalBookingId: freezed == professionalBookingId ? _self.professionalBookingId : professionalBookingId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Activity].
extension ActivityPatterns on Activity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Activity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Activity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Activity value)  $default,){
final _that = this;
switch (_that) {
case _Activity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Activity value)?  $default,){
final _that = this;
switch (_that) {
case _Activity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'sport_id')  int sportId, @JsonKey(name: 'start_time')  DateTime startTime, @JsonKey(name: 'end_time')  DateTime? endTime, @JsonKey(name: 'lobby_id')  String? lobbyId, @JsonKey(name: 'professional_booking_id')  String? professionalBookingId, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Activity() when $default != null:
return $default(_that.id,_that.userId,_that.sportId,_that.startTime,_that.endTime,_that.lobbyId,_that.professionalBookingId,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'sport_id')  int sportId, @JsonKey(name: 'start_time')  DateTime startTime, @JsonKey(name: 'end_time')  DateTime? endTime, @JsonKey(name: 'lobby_id')  String? lobbyId, @JsonKey(name: 'professional_booking_id')  String? professionalBookingId, @JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _Activity():
return $default(_that.id,_that.userId,_that.sportId,_that.startTime,_that.endTime,_that.lobbyId,_that.professionalBookingId,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'sport_id')  int sportId, @JsonKey(name: 'start_time')  DateTime startTime, @JsonKey(name: 'end_time')  DateTime? endTime, @JsonKey(name: 'lobby_id')  String? lobbyId, @JsonKey(name: 'professional_booking_id')  String? professionalBookingId, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Activity() when $default != null:
return $default(_that.id,_that.userId,_that.sportId,_that.startTime,_that.endTime,_that.lobbyId,_that.professionalBookingId,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Activity implements Activity {
  const _Activity({this.id, @JsonKey(name: 'user_id') required this.userId, @JsonKey(name: 'sport_id') required this.sportId, @JsonKey(name: 'start_time') required this.startTime, @JsonKey(name: 'end_time') this.endTime, @JsonKey(name: 'lobby_id') this.lobbyId, @JsonKey(name: 'professional_booking_id') this.professionalBookingId, @JsonKey(name: 'created_at') this.createdAt});
  factory _Activity.fromJson(Map<String, dynamic> json) => _$ActivityFromJson(json);

@override final  String? id;
@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey(name: 'sport_id') final  int sportId;
@override@JsonKey(name: 'start_time') final  DateTime startTime;
@override@JsonKey(name: 'end_time') final  DateTime? endTime;
@override@JsonKey(name: 'lobby_id') final  String? lobbyId;
@override@JsonKey(name: 'professional_booking_id') final  String? professionalBookingId;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of Activity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActivityCopyWith<_Activity> get copyWith => __$ActivityCopyWithImpl<_Activity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ActivityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Activity&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.sportId, sportId) || other.sportId == sportId)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.lobbyId, lobbyId) || other.lobbyId == lobbyId)&&(identical(other.professionalBookingId, professionalBookingId) || other.professionalBookingId == professionalBookingId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,sportId,startTime,endTime,lobbyId,professionalBookingId,createdAt);

@override
String toString() {
  return 'Activity(id: $id, userId: $userId, sportId: $sportId, startTime: $startTime, endTime: $endTime, lobbyId: $lobbyId, professionalBookingId: $professionalBookingId, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ActivityCopyWith<$Res> implements $ActivityCopyWith<$Res> {
  factory _$ActivityCopyWith(_Activity value, $Res Function(_Activity) _then) = __$ActivityCopyWithImpl;
@override @useResult
$Res call({
 String? id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'sport_id') int sportId,@JsonKey(name: 'start_time') DateTime startTime,@JsonKey(name: 'end_time') DateTime? endTime,@JsonKey(name: 'lobby_id') String? lobbyId,@JsonKey(name: 'professional_booking_id') String? professionalBookingId,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class __$ActivityCopyWithImpl<$Res>
    implements _$ActivityCopyWith<$Res> {
  __$ActivityCopyWithImpl(this._self, this._then);

  final _Activity _self;
  final $Res Function(_Activity) _then;

/// Create a copy of Activity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? userId = null,Object? sportId = null,Object? startTime = null,Object? endTime = freezed,Object? lobbyId = freezed,Object? professionalBookingId = freezed,Object? createdAt = freezed,}) {
  return _then(_Activity(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,sportId: null == sportId ? _self.sportId : sportId // ignore: cast_nullable_to_non_nullable
as int,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,endTime: freezed == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as DateTime?,lobbyId: freezed == lobbyId ? _self.lobbyId : lobbyId // ignore: cast_nullable_to_non_nullable
as String?,professionalBookingId: freezed == professionalBookingId ? _self.professionalBookingId : professionalBookingId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
