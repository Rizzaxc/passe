// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'network.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Network {

 int get id; String get name;// if representing a UserNetwork, can either be true or false.
// if it's only for a Network, default to false
 bool get isAlumni; NetworkCategory get category; City? get city;
/// Create a copy of Network
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NetworkCopyWith<Network> get copyWith => _$NetworkCopyWithImpl<Network>(this as Network, _$identity);

  /// Serializes this Network to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Network&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.isAlumni, isAlumni) || other.isAlumni == isAlumni)&&(identical(other.category, category) || other.category == category)&&(identical(other.city, city) || other.city == city));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,isAlumni,category,city);



}

/// @nodoc
abstract mixin class $NetworkCopyWith<$Res>  {
  factory $NetworkCopyWith(Network value, $Res Function(Network) _then) = _$NetworkCopyWithImpl;
@useResult
$Res call({
 int id, String name, bool isAlumni, NetworkCategory category, City? city
});




}
/// @nodoc
class _$NetworkCopyWithImpl<$Res>
    implements $NetworkCopyWith<$Res> {
  _$NetworkCopyWithImpl(this._self, this._then);

  final Network _self;
  final $Res Function(Network) _then;

/// Create a copy of Network
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? isAlumni = null,Object? category = null,Object? city = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isAlumni: null == isAlumni ? _self.isAlumni : isAlumni // ignore: cast_nullable_to_non_nullable
as bool,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as NetworkCategory,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as City?,
  ));
}

}


/// Adds pattern-matching-related methods to [Network].
extension NetworkPatterns on Network {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Network value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Network() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Network value)  $default,){
final _that = this;
switch (_that) {
case _Network():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Network value)?  $default,){
final _that = this;
switch (_that) {
case _Network() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  bool isAlumni,  NetworkCategory category,  City? city)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Network() when $default != null:
return $default(_that.id,_that.name,_that.isAlumni,_that.category,_that.city);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  bool isAlumni,  NetworkCategory category,  City? city)  $default,) {final _that = this;
switch (_that) {
case _Network():
return $default(_that.id,_that.name,_that.isAlumni,_that.category,_that.city);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  bool isAlumni,  NetworkCategory category,  City? city)?  $default,) {final _that = this;
switch (_that) {
case _Network() when $default != null:
return $default(_that.id,_that.name,_that.isAlumni,_that.category,_that.city);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Network extends Network {
  const _Network({required this.id, required this.name, required this.isAlumni, required this.category, this.city}): super._();
  factory _Network.fromJson(Map<String, dynamic> json) => _$NetworkFromJson(json);

@override final  int id;
@override final  String name;
// if representing a UserNetwork, can either be true or false.
// if it's only for a Network, default to false
@override final  bool isAlumni;
@override final  NetworkCategory category;
@override final  City? city;

/// Create a copy of Network
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NetworkCopyWith<_Network> get copyWith => __$NetworkCopyWithImpl<_Network>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NetworkToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Network&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.isAlumni, isAlumni) || other.isAlumni == isAlumni)&&(identical(other.category, category) || other.category == category)&&(identical(other.city, city) || other.city == city));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,isAlumni,category,city);



}

/// @nodoc
abstract mixin class _$NetworkCopyWith<$Res> implements $NetworkCopyWith<$Res> {
  factory _$NetworkCopyWith(_Network value, $Res Function(_Network) _then) = __$NetworkCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, bool isAlumni, NetworkCategory category, City? city
});




}
/// @nodoc
class __$NetworkCopyWithImpl<$Res>
    implements _$NetworkCopyWith<$Res> {
  __$NetworkCopyWithImpl(this._self, this._then);

  final _Network _self;
  final $Res Function(_Network) _then;

/// Create a copy of Network
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? isAlumni = null,Object? category = null,Object? city = freezed,}) {
  return _then(_Network(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isAlumni: null == isAlumni ? _self.isAlumni : isAlumni // ignore: cast_nullable_to_non_nullable
as bool,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as NetworkCategory,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as City?,
  ));
}


}

// dart format on
