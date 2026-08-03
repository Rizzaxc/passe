import 'package:avatar_plus/avatar_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A user's avatar, resolved the same way everywhere.
///
/// `generatedAvatar` is overloaded on `user.details` (see profile_tab/CLAUDE.md):
/// a non-empty string is an [AvatarPlus] seed, and the empty string means the
/// user has a **custom photo** in the public `user_avatar` bucket at
/// `<userId>.jpg`. Null falls back to seeding off the username.
///
/// Deliberately **not** cache-busted. `profile_tab/main.dart` appends a
/// `?t=<millis>` to its own avatar so an upload shows immediately, but doing
/// that here would make the URL change on every build — every avatar in a feed
/// would miss both the disk cache and the CDN and re-download on each scroll.
/// The cost is that someone else's avatar change can take a while to appear,
/// which is the right trade for a list of dozens of them.
class PUserAvatar extends StatelessWidget {
  final String userId;
  final String username;
  final String? generatedAvatar;
  final double radius;
  final VoidCallback? onTap;

  const PUserAvatar({
    super.key,
    required this.userId,
    required this.username,
    this.generatedAvatar,
    this.radius = 20,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasCustomPhoto = generatedAvatar == '';

    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: context.theme.colors.primary,
      backgroundImage: hasCustomPhoto
          ? CachedNetworkImageProvider(
              Supabase.instance.client.storage
                  .from('user_avatar')
                  .getPublicUrl('$userId.jpg'),
            )
          : null,
      child: hasCustomPhoto
          ? null
          : ClipOval(
              child: AvatarPlus(
                (generatedAvatar == null || generatedAvatar!.isEmpty)
                    ? username
                    : generatedAvatar!,
                height: radius * 2,
                width: radius * 2,
              ),
            ),
    );

    if (onTap == null) return avatar;
    return GestureDetector(onTap: onTap, child: avatar);
  }
}
