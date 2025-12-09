
import 'package:freezed_annotation/freezed_annotation.dart';

import 'enum.dart';
import 'timeslot.dart';
import 'user_location.dart';

part 'user_details.freezed.dart';
part 'user_details.g.dart';

@freezed
abstract class UserDetails with _$UserDetails {
  const factory UserDetails({
    Gender? gender,
    AgeGroup? ageGroup,
    @Default([]) List<Timeslot> playtime,
    UserLocation? location,
  }) = _UserDetails;

  // TODO: sport profile


  factory UserDetails.fromJson(Map<String, dynamic> json) =>
      _$UserDetailsFromJson(json);

}

