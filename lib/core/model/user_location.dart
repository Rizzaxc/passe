import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

import 'enum.dart';

part 'user_location.freezed.dart';
part 'user_location.g.dart';

@freezed
abstract class UserLocation with _$UserLocation {
  const factory UserLocation({
    City? city,
    @Default([]) List<String> districts,
  }) = _UserLocation;

  factory UserLocation.fromJson(Map<String, dynamic> json) =>
      _$UserLocationFromJson(json);
}
