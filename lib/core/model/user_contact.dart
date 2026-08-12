import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_contact.freezed.dart';
part 'user_contact.g.dart';

/// A user's optional external-app contact info (`user_contact` table).
///
/// Visibility is enforced by that table's RLS, not client code: readable by
/// the owner, by friends, by anyone if [zaloPublic] is set, and always for
/// an active freeplay host (they act as an "alternative pro"). See
/// `schema/user_contact.sql` / `schema/user_contact_zalo_public.sql`.
@freezed
abstract class UserContact with _$UserContact {
  const factory UserContact({
    String? zalo,
    @JsonKey(name: 'zalo_public') @Default(false) bool zaloPublic,
  }) = _UserContact;

  factory UserContact.fromJson(Map<String, dynamic> json) =>
      _$UserContactFromJson(json);
}
