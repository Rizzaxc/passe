
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

import 'enum.dart';
import 'network.dart';
import 'timeslot.dart';
import 'user_location.dart';

part 'user_details.freezed.dart';
part 'user_details.g.dart';

@freezed
abstract class SportProfile with _$SportProfile {
  const factory SportProfile({
    int? skill,
  }) = _SportProfile;

  factory SportProfile.fromJson(Map<String, dynamic> json) =>
      _$SportProfileFromJson(json);
}

@freezed
abstract class UserDetails with _$UserDetails {
  const factory UserDetails({
    Gender? gender,
    AgeGroup? ageGroup,
    List<Timeslot>? playtime,
    UserLocation? location,
    Map<String, SportProfile>? sport,
    String? generatedAvatar,
  }) = _UserDetails;

  factory UserDetails.fromJson(Map<String, dynamic> json) =>
      _$UserDetailsFromJson(json);
}

