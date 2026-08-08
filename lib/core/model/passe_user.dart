import 'package:freezed_annotation/freezed_annotation.dart';

import 'user_details.dart';

part 'passe_user.freezed.dart';
part 'passe_user.g.dart';

@freezed
abstract class PasseUser with _$PasseUser {
  const PasseUser._();

  const factory PasseUser({
    String? id,
    @Default('Guest') String username,
    @Default('0000') String tagNumber,
    String? email,
    UserDetails? details,
    @Default(false) bool hasPassword,
  }) = _PasseUser;

  factory PasseUser.fromJson(Map<String, dynamic> json) =>
      _$PasseUserFromJson(json);

  bool get isGuest => id == null;
}
