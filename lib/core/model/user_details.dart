
import 'package:freezed_annotation/freezed_annotation.dart';

import 'enum.dart';
import 'timeslot.dart';
import 'user_avatar.dart';
import 'user_location.dart';

part 'user_details.freezed.dart';
part 'user_details.g.dart';

@freezed
abstract class UserDetails with _$UserDetails {
  const factory UserDetails({
    Gender? gender,
    AgeGroup? ageGroup,
    List<Timeslot>? playtime,
    UserLocation? location,
    @JsonKey(
      name: 'generatedAvatar',
      fromJson: UserAvatar.decode,
      toJson: UserAvatar.encode,
    )
    UserAvatar? avatar,
  }) = _UserDetails;

  factory UserDetails.fromJson(Map<String, dynamic> json) =>
      _$UserDetailsFromJson(json);
}

