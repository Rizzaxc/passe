// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProfileState {

 String get username; UserDetails get details; List<Network> get networks; List<Industry> get industries; XFile? get pickedAvatar;
/// Create a copy of ProfileState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileStateCopyWith<ProfileState> get copyWith => _$ProfileStateCopyWithImpl<ProfileState>(this as ProfileState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileState&&(identical(other.username, username) || other.username == username)&&(identical(other.details, details) || other.details == details)&&const DeepCollectionEquality().equals(other.networks, networks)&&const DeepCollectionEquality().equals(other.industries, industries)&&(identical(other.pickedAvatar, pickedAvatar) || other.pickedAvatar == pickedAvatar));
}


@override
int get hashCode => Object.hash(runtimeType,username,details,const DeepCollectionEquality().hash(networks),const DeepCollectionEquality().hash(industries),pickedAvatar);

@override
String toString() {
  return 'ProfileState(username: $username, details: $details, networks: $networks, industries: $industries, pickedAvatar: $pickedAvatar)';
}


}

/// @nodoc
abstract mixin class $ProfileStateCopyWith<$Res>  {
  factory $ProfileStateCopyWith(ProfileState value, $Res Function(ProfileState) _then) = _$ProfileStateCopyWithImpl;
@useResult
$Res call({
 String username, UserDetails details, List<Network> networks, List<Industry> industries, XFile? pickedAvatar
});


$UserDetailsCopyWith<$Res> get details;

}
/// @nodoc
class _$ProfileStateCopyWithImpl<$Res>
    implements $ProfileStateCopyWith<$Res> {
  _$ProfileStateCopyWithImpl(this._self, this._then);

  final ProfileState _self;
  final $Res Function(ProfileState) _then;

/// Create a copy of ProfileState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? username = null,Object? details = null,Object? networks = null,Object? industries = null,Object? pickedAvatar = freezed,}) {
  return _then(_self.copyWith(
username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as UserDetails,networks: null == networks ? _self.networks : networks // ignore: cast_nullable_to_non_nullable
as List<Network>,industries: null == industries ? _self.industries : industries // ignore: cast_nullable_to_non_nullable
as List<Industry>,pickedAvatar: freezed == pickedAvatar ? _self.pickedAvatar : pickedAvatar // ignore: cast_nullable_to_non_nullable
as XFile?,
  ));
}
/// Create a copy of ProfileState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserDetailsCopyWith<$Res> get details {
  
  return $UserDetailsCopyWith<$Res>(_self.details, (value) {
    return _then(_self.copyWith(details: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProfileState].
extension ProfileStatePatterns on ProfileState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfileState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfileState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfileState value)  $default,){
final _that = this;
switch (_that) {
case _ProfileState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfileState value)?  $default,){
final _that = this;
switch (_that) {
case _ProfileState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String username,  UserDetails details,  List<Network> networks,  List<Industry> industries,  XFile? pickedAvatar)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfileState() when $default != null:
return $default(_that.username,_that.details,_that.networks,_that.industries,_that.pickedAvatar);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String username,  UserDetails details,  List<Network> networks,  List<Industry> industries,  XFile? pickedAvatar)  $default,) {final _that = this;
switch (_that) {
case _ProfileState():
return $default(_that.username,_that.details,_that.networks,_that.industries,_that.pickedAvatar);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String username,  UserDetails details,  List<Network> networks,  List<Industry> industries,  XFile? pickedAvatar)?  $default,) {final _that = this;
switch (_that) {
case _ProfileState() when $default != null:
return $default(_that.username,_that.details,_that.networks,_that.industries,_that.pickedAvatar);case _:
  return null;

}
}

}

/// @nodoc


class _ProfileState extends ProfileState {
  const _ProfileState({required this.username, required this.details, final  List<Network> networks = const [], final  List<Industry> industries = const [], this.pickedAvatar}): _networks = networks,_industries = industries,super._();
  

@override final  String username;
@override final  UserDetails details;
 final  List<Network> _networks;
@override@JsonKey() List<Network> get networks {
  if (_networks is EqualUnmodifiableListView) return _networks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_networks);
}

 final  List<Industry> _industries;
@override@JsonKey() List<Industry> get industries {
  if (_industries is EqualUnmodifiableListView) return _industries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_industries);
}

@override final  XFile? pickedAvatar;

/// Create a copy of ProfileState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileStateCopyWith<_ProfileState> get copyWith => __$ProfileStateCopyWithImpl<_ProfileState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileState&&(identical(other.username, username) || other.username == username)&&(identical(other.details, details) || other.details == details)&&const DeepCollectionEquality().equals(other._networks, _networks)&&const DeepCollectionEquality().equals(other._industries, _industries)&&(identical(other.pickedAvatar, pickedAvatar) || other.pickedAvatar == pickedAvatar));
}


@override
int get hashCode => Object.hash(runtimeType,username,details,const DeepCollectionEquality().hash(_networks),const DeepCollectionEquality().hash(_industries),pickedAvatar);

@override
String toString() {
  return 'ProfileState(username: $username, details: $details, networks: $networks, industries: $industries, pickedAvatar: $pickedAvatar)';
}


}

/// @nodoc
abstract mixin class _$ProfileStateCopyWith<$Res> implements $ProfileStateCopyWith<$Res> {
  factory _$ProfileStateCopyWith(_ProfileState value, $Res Function(_ProfileState) _then) = __$ProfileStateCopyWithImpl;
@override @useResult
$Res call({
 String username, UserDetails details, List<Network> networks, List<Industry> industries, XFile? pickedAvatar
});


@override $UserDetailsCopyWith<$Res> get details;

}
/// @nodoc
class __$ProfileStateCopyWithImpl<$Res>
    implements _$ProfileStateCopyWith<$Res> {
  __$ProfileStateCopyWithImpl(this._self, this._then);

  final _ProfileState _self;
  final $Res Function(_ProfileState) _then;

/// Create a copy of ProfileState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? username = null,Object? details = null,Object? networks = null,Object? industries = null,Object? pickedAvatar = freezed,}) {
  return _then(_ProfileState(
username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as UserDetails,networks: null == networks ? _self._networks : networks // ignore: cast_nullable_to_non_nullable
as List<Network>,industries: null == industries ? _self._industries : industries // ignore: cast_nullable_to_non_nullable
as List<Industry>,pickedAvatar: freezed == pickedAvatar ? _self.pickedAvatar : pickedAvatar // ignore: cast_nullable_to_non_nullable
as XFile?,
  ));
}

/// Create a copy of ProfileState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserDetailsCopyWith<$Res> get details {
  
  return $UserDetailsCopyWith<$Res>(_self.details, (value) {
    return _then(_self.copyWith(details: value));
  });
}
}

/// @nodoc
mixin _$NetworkSearchState {

 List<Network> get results; bool get isLoading; Set<City> get cityFilters; Set<NetworkCategory> get categoryFilters;
/// Create a copy of NetworkSearchState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NetworkSearchStateCopyWith<NetworkSearchState> get copyWith => _$NetworkSearchStateCopyWithImpl<NetworkSearchState>(this as NetworkSearchState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NetworkSearchState&&const DeepCollectionEquality().equals(other.results, results)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&const DeepCollectionEquality().equals(other.cityFilters, cityFilters)&&const DeepCollectionEquality().equals(other.categoryFilters, categoryFilters));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(results),isLoading,const DeepCollectionEquality().hash(cityFilters),const DeepCollectionEquality().hash(categoryFilters));

@override
String toString() {
  return 'NetworkSearchState(results: $results, isLoading: $isLoading, cityFilters: $cityFilters, categoryFilters: $categoryFilters)';
}


}

/// @nodoc
abstract mixin class $NetworkSearchStateCopyWith<$Res>  {
  factory $NetworkSearchStateCopyWith(NetworkSearchState value, $Res Function(NetworkSearchState) _then) = _$NetworkSearchStateCopyWithImpl;
@useResult
$Res call({
 List<Network> results, bool isLoading, Set<City> cityFilters, Set<NetworkCategory> categoryFilters
});




}
/// @nodoc
class _$NetworkSearchStateCopyWithImpl<$Res>
    implements $NetworkSearchStateCopyWith<$Res> {
  _$NetworkSearchStateCopyWithImpl(this._self, this._then);

  final NetworkSearchState _self;
  final $Res Function(NetworkSearchState) _then;

/// Create a copy of NetworkSearchState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? results = null,Object? isLoading = null,Object? cityFilters = null,Object? categoryFilters = null,}) {
  return _then(_self.copyWith(
results: null == results ? _self.results : results // ignore: cast_nullable_to_non_nullable
as List<Network>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,cityFilters: null == cityFilters ? _self.cityFilters : cityFilters // ignore: cast_nullable_to_non_nullable
as Set<City>,categoryFilters: null == categoryFilters ? _self.categoryFilters : categoryFilters // ignore: cast_nullable_to_non_nullable
as Set<NetworkCategory>,
  ));
}

}


/// Adds pattern-matching-related methods to [NetworkSearchState].
extension NetworkSearchStatePatterns on NetworkSearchState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NetworkSearchState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NetworkSearchState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NetworkSearchState value)  $default,){
final _that = this;
switch (_that) {
case _NetworkSearchState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NetworkSearchState value)?  $default,){
final _that = this;
switch (_that) {
case _NetworkSearchState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Network> results,  bool isLoading,  Set<City> cityFilters,  Set<NetworkCategory> categoryFilters)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NetworkSearchState() when $default != null:
return $default(_that.results,_that.isLoading,_that.cityFilters,_that.categoryFilters);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Network> results,  bool isLoading,  Set<City> cityFilters,  Set<NetworkCategory> categoryFilters)  $default,) {final _that = this;
switch (_that) {
case _NetworkSearchState():
return $default(_that.results,_that.isLoading,_that.cityFilters,_that.categoryFilters);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Network> results,  bool isLoading,  Set<City> cityFilters,  Set<NetworkCategory> categoryFilters)?  $default,) {final _that = this;
switch (_that) {
case _NetworkSearchState() when $default != null:
return $default(_that.results,_that.isLoading,_that.cityFilters,_that.categoryFilters);case _:
  return null;

}
}

}

/// @nodoc


class _NetworkSearchState implements NetworkSearchState {
  const _NetworkSearchState({final  List<Network> results = const [], this.isLoading = false, final  Set<City> cityFilters = const {}, final  Set<NetworkCategory> categoryFilters = const {}}): _results = results,_cityFilters = cityFilters,_categoryFilters = categoryFilters;
  

 final  List<Network> _results;
@override@JsonKey() List<Network> get results {
  if (_results is EqualUnmodifiableListView) return _results;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_results);
}

@override@JsonKey() final  bool isLoading;
 final  Set<City> _cityFilters;
@override@JsonKey() Set<City> get cityFilters {
  if (_cityFilters is EqualUnmodifiableSetView) return _cityFilters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_cityFilters);
}

 final  Set<NetworkCategory> _categoryFilters;
@override@JsonKey() Set<NetworkCategory> get categoryFilters {
  if (_categoryFilters is EqualUnmodifiableSetView) return _categoryFilters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_categoryFilters);
}


/// Create a copy of NetworkSearchState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NetworkSearchStateCopyWith<_NetworkSearchState> get copyWith => __$NetworkSearchStateCopyWithImpl<_NetworkSearchState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NetworkSearchState&&const DeepCollectionEquality().equals(other._results, _results)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&const DeepCollectionEquality().equals(other._cityFilters, _cityFilters)&&const DeepCollectionEquality().equals(other._categoryFilters, _categoryFilters));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_results),isLoading,const DeepCollectionEquality().hash(_cityFilters),const DeepCollectionEquality().hash(_categoryFilters));

@override
String toString() {
  return 'NetworkSearchState(results: $results, isLoading: $isLoading, cityFilters: $cityFilters, categoryFilters: $categoryFilters)';
}


}

/// @nodoc
abstract mixin class _$NetworkSearchStateCopyWith<$Res> implements $NetworkSearchStateCopyWith<$Res> {
  factory _$NetworkSearchStateCopyWith(_NetworkSearchState value, $Res Function(_NetworkSearchState) _then) = __$NetworkSearchStateCopyWithImpl;
@override @useResult
$Res call({
 List<Network> results, bool isLoading, Set<City> cityFilters, Set<NetworkCategory> categoryFilters
});




}
/// @nodoc
class __$NetworkSearchStateCopyWithImpl<$Res>
    implements _$NetworkSearchStateCopyWith<$Res> {
  __$NetworkSearchStateCopyWithImpl(this._self, this._then);

  final _NetworkSearchState _self;
  final $Res Function(_NetworkSearchState) _then;

/// Create a copy of NetworkSearchState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? results = null,Object? isLoading = null,Object? cityFilters = null,Object? categoryFilters = null,}) {
  return _then(_NetworkSearchState(
results: null == results ? _self._results : results // ignore: cast_nullable_to_non_nullable
as List<Network>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,cityFilters: null == cityFilters ? _self._cityFilters : cityFilters // ignore: cast_nullable_to_non_nullable
as Set<City>,categoryFilters: null == categoryFilters ? _self._categoryFilters : categoryFilters // ignore: cast_nullable_to_non_nullable
as Set<NetworkCategory>,
  ));
}


}

// dart format on
