// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lobby_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LobbyFormState {

 Lobby get lobby; bool get isSaving; List<LobbyHomeground> get homeGrounds; XFile? get pickedAvatar;
/// Create a copy of LobbyFormState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LobbyFormStateCopyWith<LobbyFormState> get copyWith => _$LobbyFormStateCopyWithImpl<LobbyFormState>(this as LobbyFormState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LobbyFormState&&(identical(other.lobby, lobby) || other.lobby == lobby)&&(identical(other.isSaving, isSaving) || other.isSaving == isSaving)&&const DeepCollectionEquality().equals(other.homeGrounds, homeGrounds)&&(identical(other.pickedAvatar, pickedAvatar) || other.pickedAvatar == pickedAvatar));
}


@override
int get hashCode => Object.hash(runtimeType,lobby,isSaving,const DeepCollectionEquality().hash(homeGrounds),pickedAvatar);

@override
String toString() {
  return 'LobbyFormState(lobby: $lobby, isSaving: $isSaving, homeGrounds: $homeGrounds, pickedAvatar: $pickedAvatar)';
}


}

/// @nodoc
abstract mixin class $LobbyFormStateCopyWith<$Res>  {
  factory $LobbyFormStateCopyWith(LobbyFormState value, $Res Function(LobbyFormState) _then) = _$LobbyFormStateCopyWithImpl;
@useResult
$Res call({
 Lobby lobby, bool isSaving, List<LobbyHomeground> homeGrounds, XFile? pickedAvatar
});


$LobbyCopyWith<$Res> get lobby;

}
/// @nodoc
class _$LobbyFormStateCopyWithImpl<$Res>
    implements $LobbyFormStateCopyWith<$Res> {
  _$LobbyFormStateCopyWithImpl(this._self, this._then);

  final LobbyFormState _self;
  final $Res Function(LobbyFormState) _then;

/// Create a copy of LobbyFormState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lobby = null,Object? isSaving = null,Object? homeGrounds = null,Object? pickedAvatar = freezed,}) {
  return _then(_self.copyWith(
lobby: null == lobby ? _self.lobby : lobby // ignore: cast_nullable_to_non_nullable
as Lobby,isSaving: null == isSaving ? _self.isSaving : isSaving // ignore: cast_nullable_to_non_nullable
as bool,homeGrounds: null == homeGrounds ? _self.homeGrounds : homeGrounds // ignore: cast_nullable_to_non_nullable
as List<LobbyHomeground>,pickedAvatar: freezed == pickedAvatar ? _self.pickedAvatar : pickedAvatar // ignore: cast_nullable_to_non_nullable
as XFile?,
  ));
}
/// Create a copy of LobbyFormState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LobbyCopyWith<$Res> get lobby {
  
  return $LobbyCopyWith<$Res>(_self.lobby, (value) {
    return _then(_self.copyWith(lobby: value));
  });
}
}


/// Adds pattern-matching-related methods to [LobbyFormState].
extension LobbyFormStatePatterns on LobbyFormState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LobbyFormState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LobbyFormState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LobbyFormState value)  $default,){
final _that = this;
switch (_that) {
case _LobbyFormState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LobbyFormState value)?  $default,){
final _that = this;
switch (_that) {
case _LobbyFormState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Lobby lobby,  bool isSaving,  List<LobbyHomeground> homeGrounds,  XFile? pickedAvatar)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LobbyFormState() when $default != null:
return $default(_that.lobby,_that.isSaving,_that.homeGrounds,_that.pickedAvatar);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Lobby lobby,  bool isSaving,  List<LobbyHomeground> homeGrounds,  XFile? pickedAvatar)  $default,) {final _that = this;
switch (_that) {
case _LobbyFormState():
return $default(_that.lobby,_that.isSaving,_that.homeGrounds,_that.pickedAvatar);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Lobby lobby,  bool isSaving,  List<LobbyHomeground> homeGrounds,  XFile? pickedAvatar)?  $default,) {final _that = this;
switch (_that) {
case _LobbyFormState() when $default != null:
return $default(_that.lobby,_that.isSaving,_that.homeGrounds,_that.pickedAvatar);case _:
  return null;

}
}

}

/// @nodoc


class _LobbyFormState implements LobbyFormState {
  const _LobbyFormState({required this.lobby, this.isSaving = false, final  List<LobbyHomeground> homeGrounds = const <LobbyHomeground>[], this.pickedAvatar}): _homeGrounds = homeGrounds;
  

@override final  Lobby lobby;
@override@JsonKey() final  bool isSaving;
 final  List<LobbyHomeground> _homeGrounds;
@override@JsonKey() List<LobbyHomeground> get homeGrounds {
  if (_homeGrounds is EqualUnmodifiableListView) return _homeGrounds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_homeGrounds);
}

@override final  XFile? pickedAvatar;

/// Create a copy of LobbyFormState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LobbyFormStateCopyWith<_LobbyFormState> get copyWith => __$LobbyFormStateCopyWithImpl<_LobbyFormState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LobbyFormState&&(identical(other.lobby, lobby) || other.lobby == lobby)&&(identical(other.isSaving, isSaving) || other.isSaving == isSaving)&&const DeepCollectionEquality().equals(other._homeGrounds, _homeGrounds)&&(identical(other.pickedAvatar, pickedAvatar) || other.pickedAvatar == pickedAvatar));
}


@override
int get hashCode => Object.hash(runtimeType,lobby,isSaving,const DeepCollectionEquality().hash(_homeGrounds),pickedAvatar);

@override
String toString() {
  return 'LobbyFormState(lobby: $lobby, isSaving: $isSaving, homeGrounds: $homeGrounds, pickedAvatar: $pickedAvatar)';
}


}

/// @nodoc
abstract mixin class _$LobbyFormStateCopyWith<$Res> implements $LobbyFormStateCopyWith<$Res> {
  factory _$LobbyFormStateCopyWith(_LobbyFormState value, $Res Function(_LobbyFormState) _then) = __$LobbyFormStateCopyWithImpl;
@override @useResult
$Res call({
 Lobby lobby, bool isSaving, List<LobbyHomeground> homeGrounds, XFile? pickedAvatar
});


@override $LobbyCopyWith<$Res> get lobby;

}
/// @nodoc
class __$LobbyFormStateCopyWithImpl<$Res>
    implements _$LobbyFormStateCopyWith<$Res> {
  __$LobbyFormStateCopyWithImpl(this._self, this._then);

  final _LobbyFormState _self;
  final $Res Function(_LobbyFormState) _then;

/// Create a copy of LobbyFormState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lobby = null,Object? isSaving = null,Object? homeGrounds = null,Object? pickedAvatar = freezed,}) {
  return _then(_LobbyFormState(
lobby: null == lobby ? _self.lobby : lobby // ignore: cast_nullable_to_non_nullable
as Lobby,isSaving: null == isSaving ? _self.isSaving : isSaving // ignore: cast_nullable_to_non_nullable
as bool,homeGrounds: null == homeGrounds ? _self._homeGrounds : homeGrounds // ignore: cast_nullable_to_non_nullable
as List<LobbyHomeground>,pickedAvatar: freezed == pickedAvatar ? _self.pickedAvatar : pickedAvatar // ignore: cast_nullable_to_non_nullable
as XFile?,
  ));
}

/// Create a copy of LobbyFormState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LobbyCopyWith<$Res> get lobby {
  
  return $LobbyCopyWith<$Res>(_self.lobby, (value) {
    return _then(_self.copyWith(lobby: value));
  });
}
}

// dart format on
