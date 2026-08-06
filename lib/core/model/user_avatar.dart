/// A user's avatar: either a procedurally generated seed (fed to
/// `AvatarPlus`) or a marker that the user has a custom photo uploaded to
/// the `user_avatar` storage bucket at `<userId>.jpg` (see `PUserAvatar` in
/// lib/ui/user_avatar.dart).
///
/// [decode]/[encode] are wire-compatible with the `details ->>
/// 'generatedAvatar'` string convention this replaces (non-empty string =
/// seed, `''` = photo, absent/null = unset) — see `UserDetails.avatar`'s
/// `@JsonKey` — so introducing this type needed no DB migration or RPC
/// changes. Only `UserDetails` (the editable, persisted model) uses this;
/// read-only surfaces across the app (lobby member lists, feed authors,
/// payment payees, etc.) still consume the raw wire string directly via
/// `PUserAvatar`, which is unaffected by this type's existence.
sealed class UserAvatar {
  const UserAvatar();

  static UserAvatar? decode(String? raw) {
    if (raw == null) return null;
    return raw.isEmpty ? const PhotoAvatar() : GeneratedAvatar(raw);
  }

  static String? encode(UserAvatar? avatar) => switch (avatar) {
    null => null,
    GeneratedAvatar(:final seed) => seed,
    PhotoAvatar() => '',
  };
}

final class GeneratedAvatar extends UserAvatar {
  final String seed;
  const GeneratedAvatar(this.seed);
}

final class PhotoAvatar extends UserAvatar {
  const PhotoAvatar();
}
