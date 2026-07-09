// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'location.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Location {

 String get id; String get name;@JsonKey(name: 'full_address') String? get fullAddress;@JsonKey(name: 'street_number', fromJson: _streetNumberFromJson) String? get streetNumber;@JsonKey(name: 'street_name') String? get streetName; String? get district; String? get city; double? get lat; double? get lon;@JsonKey(fromJson: _tagsFromJson) List<String> get tags;@JsonKey(name: 'city_cluster') int? get cityCluster;
/// Create a copy of Location
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocationCopyWith<Location> get copyWith => _$LocationCopyWithImpl<Location>(this as Location, _$identity);

  /// Serializes this Location to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Location&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.fullAddress, fullAddress) || other.fullAddress == fullAddress)&&(identical(other.streetNumber, streetNumber) || other.streetNumber == streetNumber)&&(identical(other.streetName, streetName) || other.streetName == streetName)&&(identical(other.district, district) || other.district == district)&&(identical(other.city, city) || other.city == city)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lon, lon) || other.lon == lon)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.cityCluster, cityCluster) || other.cityCluster == cityCluster));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,fullAddress,streetNumber,streetName,district,city,lat,lon,const DeepCollectionEquality().hash(tags),cityCluster);

@override
String toString() {
  return 'Location(id: $id, name: $name, fullAddress: $fullAddress, streetNumber: $streetNumber, streetName: $streetName, district: $district, city: $city, lat: $lat, lon: $lon, tags: $tags, cityCluster: $cityCluster)';
}


}

/// @nodoc
abstract mixin class $LocationCopyWith<$Res>  {
  factory $LocationCopyWith(Location value, $Res Function(Location) _then) = _$LocationCopyWithImpl;
@useResult
$Res call({
 String id, String name,@JsonKey(name: 'full_address') String? fullAddress,@JsonKey(name: 'street_number', fromJson: _streetNumberFromJson) String? streetNumber,@JsonKey(name: 'street_name') String? streetName, String? district, String? city, double? lat, double? lon,@JsonKey(fromJson: _tagsFromJson) List<String> tags,@JsonKey(name: 'city_cluster') int? cityCluster
});




}
/// @nodoc
class _$LocationCopyWithImpl<$Res>
    implements $LocationCopyWith<$Res> {
  _$LocationCopyWithImpl(this._self, this._then);

  final Location _self;
  final $Res Function(Location) _then;

/// Create a copy of Location
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? fullAddress = freezed,Object? streetNumber = freezed,Object? streetName = freezed,Object? district = freezed,Object? city = freezed,Object? lat = freezed,Object? lon = freezed,Object? tags = null,Object? cityCluster = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,fullAddress: freezed == fullAddress ? _self.fullAddress : fullAddress // ignore: cast_nullable_to_non_nullable
as String?,streetNumber: freezed == streetNumber ? _self.streetNumber : streetNumber // ignore: cast_nullable_to_non_nullable
as String?,streetName: freezed == streetName ? _self.streetName : streetName // ignore: cast_nullable_to_non_nullable
as String?,district: freezed == district ? _self.district : district // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,lat: freezed == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double?,lon: freezed == lon ? _self.lon : lon // ignore: cast_nullable_to_non_nullable
as double?,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,cityCluster: freezed == cityCluster ? _self.cityCluster : cityCluster // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [Location].
extension LocationPatterns on Location {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Location value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Location() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Location value)  $default,){
final _that = this;
switch (_that) {
case _Location():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Location value)?  $default,){
final _that = this;
switch (_that) {
case _Location() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name, @JsonKey(name: 'full_address')  String? fullAddress, @JsonKey(name: 'street_number', fromJson: _streetNumberFromJson)  String? streetNumber, @JsonKey(name: 'street_name')  String? streetName,  String? district,  String? city,  double? lat,  double? lon, @JsonKey(fromJson: _tagsFromJson)  List<String> tags, @JsonKey(name: 'city_cluster')  int? cityCluster)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Location() when $default != null:
return $default(_that.id,_that.name,_that.fullAddress,_that.streetNumber,_that.streetName,_that.district,_that.city,_that.lat,_that.lon,_that.tags,_that.cityCluster);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name, @JsonKey(name: 'full_address')  String? fullAddress, @JsonKey(name: 'street_number', fromJson: _streetNumberFromJson)  String? streetNumber, @JsonKey(name: 'street_name')  String? streetName,  String? district,  String? city,  double? lat,  double? lon, @JsonKey(fromJson: _tagsFromJson)  List<String> tags, @JsonKey(name: 'city_cluster')  int? cityCluster)  $default,) {final _that = this;
switch (_that) {
case _Location():
return $default(_that.id,_that.name,_that.fullAddress,_that.streetNumber,_that.streetName,_that.district,_that.city,_that.lat,_that.lon,_that.tags,_that.cityCluster);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name, @JsonKey(name: 'full_address')  String? fullAddress, @JsonKey(name: 'street_number', fromJson: _streetNumberFromJson)  String? streetNumber, @JsonKey(name: 'street_name')  String? streetName,  String? district,  String? city,  double? lat,  double? lon, @JsonKey(fromJson: _tagsFromJson)  List<String> tags, @JsonKey(name: 'city_cluster')  int? cityCluster)?  $default,) {final _that = this;
switch (_that) {
case _Location() when $default != null:
return $default(_that.id,_that.name,_that.fullAddress,_that.streetNumber,_that.streetName,_that.district,_that.city,_that.lat,_that.lon,_that.tags,_that.cityCluster);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Location extends Location {
  const _Location({required this.id, required this.name, @JsonKey(name: 'full_address') this.fullAddress, @JsonKey(name: 'street_number', fromJson: _streetNumberFromJson) this.streetNumber, @JsonKey(name: 'street_name') this.streetName, this.district, this.city, this.lat, this.lon, @JsonKey(fromJson: _tagsFromJson) final  List<String> tags = const <String>[], @JsonKey(name: 'city_cluster') this.cityCluster}): _tags = tags,super._();
  factory _Location.fromJson(Map<String, dynamic> json) => _$LocationFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey(name: 'full_address') final  String? fullAddress;
@override@JsonKey(name: 'street_number', fromJson: _streetNumberFromJson) final  String? streetNumber;
@override@JsonKey(name: 'street_name') final  String? streetName;
@override final  String? district;
@override final  String? city;
@override final  double? lat;
@override final  double? lon;
 final  List<String> _tags;
@override@JsonKey(fromJson: _tagsFromJson) List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override@JsonKey(name: 'city_cluster') final  int? cityCluster;

/// Create a copy of Location
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LocationCopyWith<_Location> get copyWith => __$LocationCopyWithImpl<_Location>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LocationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Location&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.fullAddress, fullAddress) || other.fullAddress == fullAddress)&&(identical(other.streetNumber, streetNumber) || other.streetNumber == streetNumber)&&(identical(other.streetName, streetName) || other.streetName == streetName)&&(identical(other.district, district) || other.district == district)&&(identical(other.city, city) || other.city == city)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lon, lon) || other.lon == lon)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.cityCluster, cityCluster) || other.cityCluster == cityCluster));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,fullAddress,streetNumber,streetName,district,city,lat,lon,const DeepCollectionEquality().hash(_tags),cityCluster);

@override
String toString() {
  return 'Location(id: $id, name: $name, fullAddress: $fullAddress, streetNumber: $streetNumber, streetName: $streetName, district: $district, city: $city, lat: $lat, lon: $lon, tags: $tags, cityCluster: $cityCluster)';
}


}

/// @nodoc
abstract mixin class _$LocationCopyWith<$Res> implements $LocationCopyWith<$Res> {
  factory _$LocationCopyWith(_Location value, $Res Function(_Location) _then) = __$LocationCopyWithImpl;
@override @useResult
$Res call({
 String id, String name,@JsonKey(name: 'full_address') String? fullAddress,@JsonKey(name: 'street_number', fromJson: _streetNumberFromJson) String? streetNumber,@JsonKey(name: 'street_name') String? streetName, String? district, String? city, double? lat, double? lon,@JsonKey(fromJson: _tagsFromJson) List<String> tags,@JsonKey(name: 'city_cluster') int? cityCluster
});




}
/// @nodoc
class __$LocationCopyWithImpl<$Res>
    implements _$LocationCopyWith<$Res> {
  __$LocationCopyWithImpl(this._self, this._then);

  final _Location _self;
  final $Res Function(_Location) _then;

/// Create a copy of Location
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? fullAddress = freezed,Object? streetNumber = freezed,Object? streetName = freezed,Object? district = freezed,Object? city = freezed,Object? lat = freezed,Object? lon = freezed,Object? tags = null,Object? cityCluster = freezed,}) {
  return _then(_Location(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,fullAddress: freezed == fullAddress ? _self.fullAddress : fullAddress // ignore: cast_nullable_to_non_nullable
as String?,streetNumber: freezed == streetNumber ? _self.streetNumber : streetNumber // ignore: cast_nullable_to_non_nullable
as String?,streetName: freezed == streetName ? _self.streetName : streetName // ignore: cast_nullable_to_non_nullable
as String?,district: freezed == district ? _self.district : district // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,lat: freezed == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double?,lon: freezed == lon ? _self.lon : lon // ignore: cast_nullable_to_non_nullable
as double?,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,cityCluster: freezed == cityCluster ? _self.cityCluster : cityCluster // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
