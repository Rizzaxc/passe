import 'package:freezed_annotation/freezed_annotation.dart';

import 'user_details.dart';

part 'pubox_user.freezed.dart';
part 'pubox_user.g.dart';

@freezed
abstract class PuboxUser with _$PuboxUser {
  const factory PuboxUser({
    String? id,
    @Default('Guest') String username,
    @Default('0000') String tagNumber,
    String? email,
    UserDetails? details,
  }) = _PuboxUser;

  factory PuboxUser.fromJson(Map<String, dynamic> json) =>
      _$PuboxUserFromJson(json);
}
