// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_payment_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserPaymentInfo {

 String get id;@JsonKey(name: 'bank_id') String get bankId;@JsonKey(name: 'bank_display_name') String get bankDisplayName; String get value;@JsonKey(name: 'account_name') String? get accountName;@JsonKey(name: 'created_at') DateTime get createdAt;
/// Create a copy of UserPaymentInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserPaymentInfoCopyWith<UserPaymentInfo> get copyWith => _$UserPaymentInfoCopyWithImpl<UserPaymentInfo>(this as UserPaymentInfo, _$identity);

  /// Serializes this UserPaymentInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserPaymentInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.bankId, bankId) || other.bankId == bankId)&&(identical(other.bankDisplayName, bankDisplayName) || other.bankDisplayName == bankDisplayName)&&(identical(other.value, value) || other.value == value)&&(identical(other.accountName, accountName) || other.accountName == accountName)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,bankId,bankDisplayName,value,accountName,createdAt);

@override
String toString() {
  return 'UserPaymentInfo(id: $id, bankId: $bankId, bankDisplayName: $bankDisplayName, value: $value, accountName: $accountName, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $UserPaymentInfoCopyWith<$Res>  {
  factory $UserPaymentInfoCopyWith(UserPaymentInfo value, $Res Function(UserPaymentInfo) _then) = _$UserPaymentInfoCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'bank_id') String bankId,@JsonKey(name: 'bank_display_name') String bankDisplayName, String value,@JsonKey(name: 'account_name') String? accountName,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class _$UserPaymentInfoCopyWithImpl<$Res>
    implements $UserPaymentInfoCopyWith<$Res> {
  _$UserPaymentInfoCopyWithImpl(this._self, this._then);

  final UserPaymentInfo _self;
  final $Res Function(UserPaymentInfo) _then;

/// Create a copy of UserPaymentInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? bankId = null,Object? bankDisplayName = null,Object? value = null,Object? accountName = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,bankId: null == bankId ? _self.bankId : bankId // ignore: cast_nullable_to_non_nullable
as String,bankDisplayName: null == bankDisplayName ? _self.bankDisplayName : bankDisplayName // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,accountName: freezed == accountName ? _self.accountName : accountName // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [UserPaymentInfo].
extension UserPaymentInfoPatterns on UserPaymentInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserPaymentInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserPaymentInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserPaymentInfo value)  $default,){
final _that = this;
switch (_that) {
case _UserPaymentInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserPaymentInfo value)?  $default,){
final _that = this;
switch (_that) {
case _UserPaymentInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'bank_id')  String bankId, @JsonKey(name: 'bank_display_name')  String bankDisplayName,  String value, @JsonKey(name: 'account_name')  String? accountName, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserPaymentInfo() when $default != null:
return $default(_that.id,_that.bankId,_that.bankDisplayName,_that.value,_that.accountName,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'bank_id')  String bankId, @JsonKey(name: 'bank_display_name')  String bankDisplayName,  String value, @JsonKey(name: 'account_name')  String? accountName, @JsonKey(name: 'created_at')  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _UserPaymentInfo():
return $default(_that.id,_that.bankId,_that.bankDisplayName,_that.value,_that.accountName,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'bank_id')  String bankId, @JsonKey(name: 'bank_display_name')  String bankDisplayName,  String value, @JsonKey(name: 'account_name')  String? accountName, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _UserPaymentInfo() when $default != null:
return $default(_that.id,_that.bankId,_that.bankDisplayName,_that.value,_that.accountName,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserPaymentInfo implements UserPaymentInfo {
  const _UserPaymentInfo({required this.id, @JsonKey(name: 'bank_id') required this.bankId, @JsonKey(name: 'bank_display_name') required this.bankDisplayName, required this.value, @JsonKey(name: 'account_name') this.accountName, @JsonKey(name: 'created_at') required this.createdAt});
  factory _UserPaymentInfo.fromJson(Map<String, dynamic> json) => _$UserPaymentInfoFromJson(json);

@override final  String id;
@override@JsonKey(name: 'bank_id') final  String bankId;
@override@JsonKey(name: 'bank_display_name') final  String bankDisplayName;
@override final  String value;
@override@JsonKey(name: 'account_name') final  String? accountName;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;

/// Create a copy of UserPaymentInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserPaymentInfoCopyWith<_UserPaymentInfo> get copyWith => __$UserPaymentInfoCopyWithImpl<_UserPaymentInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserPaymentInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserPaymentInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.bankId, bankId) || other.bankId == bankId)&&(identical(other.bankDisplayName, bankDisplayName) || other.bankDisplayName == bankDisplayName)&&(identical(other.value, value) || other.value == value)&&(identical(other.accountName, accountName) || other.accountName == accountName)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,bankId,bankDisplayName,value,accountName,createdAt);

@override
String toString() {
  return 'UserPaymentInfo(id: $id, bankId: $bankId, bankDisplayName: $bankDisplayName, value: $value, accountName: $accountName, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$UserPaymentInfoCopyWith<$Res> implements $UserPaymentInfoCopyWith<$Res> {
  factory _$UserPaymentInfoCopyWith(_UserPaymentInfo value, $Res Function(_UserPaymentInfo) _then) = __$UserPaymentInfoCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'bank_id') String bankId,@JsonKey(name: 'bank_display_name') String bankDisplayName, String value,@JsonKey(name: 'account_name') String? accountName,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class __$UserPaymentInfoCopyWithImpl<$Res>
    implements _$UserPaymentInfoCopyWith<$Res> {
  __$UserPaymentInfoCopyWithImpl(this._self, this._then);

  final _UserPaymentInfo _self;
  final $Res Function(_UserPaymentInfo) _then;

/// Create a copy of UserPaymentInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? bankId = null,Object? bankDisplayName = null,Object? value = null,Object? accountName = freezed,Object? createdAt = null,}) {
  return _then(_UserPaymentInfo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,bankId: null == bankId ? _self.bankId : bankId // ignore: cast_nullable_to_non_nullable
as String,bankDisplayName: null == bankDisplayName ? _self.bankDisplayName : bankDisplayName // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,accountName: freezed == accountName ? _self.accountName : accountName // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
