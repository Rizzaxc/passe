import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/model/user_details.dart';

part 'user_page_controller.g.dart';

/// The viewer's relationship to the profile they're looking at.
enum FriendState { none, friend, incoming, outgoing, blocked }

/// Another user as seen from `/user/:id` — the public-ish profile plus this
/// viewer's relationship to them (`user_profile_data` RPC).
class UserProfile {
  final String userId;
  final String username;
  final String tagNumber;
  final String? generatedAvatar;
  final String? friendshipId;
  final FriendState friendState;
  final int friendCount;

  /// How many of the viewer's own lobbies this person is also in. Drives the
  /// "cùng lobby" line — the honest reason a stranger's wall is visible.
  final int sharedLobbyCount;

  /// The full `details` jsonb, parsed — powers the Overview tab's general
  /// info section. `generatedAvatar` above stays the raw wire string
  /// separately since `PUserAvatar` wants that, not the typed `UserAvatar`.
  final UserDetails details;

  const UserProfile({
    required this.userId,
    required this.username,
    required this.tagNumber,
    required this.friendState,
    required this.friendCount,
    required this.sharedLobbyCount,
    required this.details,
    this.generatedAvatar,
    this.friendshipId,
  });

  String get handle => '$username#$tagNumber';

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final details = json['details'] as Map<String, dynamic>?;
    return UserProfile(
      userId: json['user_id'] as String,
      username: json['username'] as String? ?? '',
      tagNumber: json['tag_number'] as String? ?? '0000',
      generatedAvatar: details?['generatedAvatar'] as String?,
      details: UserDetails.fromJson(details ?? const {}),
      friendshipId: json['friendship_id'] as String?,
      friendState: switch (json['friend_state'] as String?) {
        'friend' => FriendState.friend,
        'incoming' => FriendState.incoming,
        'outgoing' => FriendState.outgoing,
        'blocked' => FriendState.blocked,
        _ => FriendState.none,
      },
      friendCount: (json['friend_count'] as num?)?.toInt() ?? 0,
      sharedLobbyCount: (json['shared_lobby_count'] as num?)?.toInt() ?? 0,
    );
  }
}

@riverpod
Future<UserProfile?> userProfile(Ref ref, String userId) async {
  final rows = await Supabase.instance.client
      .rpc('user_profile_data', params: {'p_user_id': userId})
      .timeout(const Duration(seconds: 5));

  final list = rows as List;
  if (list.isEmpty) return null;
  return UserProfile.fromJson(list.first as Map<String, dynamic>);
}
