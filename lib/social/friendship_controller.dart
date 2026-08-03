import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_controller.dart';

part 'friendship_controller.g.dart';

/// Which way a live `friendship` row points, from the caller's perspective.
enum FriendDirection {
  /// Accepted both ways.
  friend,

  /// They asked, the caller hasn't answered.
  incoming,

  /// The caller asked, they haven't answered.
  outgoing,
}

/// The other party on one of the caller's live friendship edges.
///
/// Plain class with a manual `fromJson`, matching `LobbyFeedItem` /
/// `ProfessionalFeedItem` — no freezed, no build_runner for this one.
class FriendUser {
  final String friendshipId;
  final String userId;
  final String username;
  final String tagNumber;

  /// `user.details.generatedAvatar` — see [PUserAvatar] for how it's resolved.
  final String? generatedAvatar;
  final FriendDirection direction;
  final DateTime createdAt;

  const FriendUser({
    required this.friendshipId,
    required this.userId,
    required this.username,
    required this.tagNumber,
    required this.direction,
    required this.createdAt,
    this.generatedAvatar,
  });

  String get handle => '$username#$tagNumber';

  factory FriendUser.fromJson(Map<String, dynamic> json) {
    final details = json['details'] as Map<String, dynamic>?;
    return FriendUser(
      friendshipId: json['friendship_id'] as String,
      userId: json['user_id'] as String,
      username: json['username'] as String? ?? '',
      tagNumber: json['tag_number'] as String? ?? '0000',
      generatedAvatar: details?['generatedAvatar'] as String?,
      direction: switch (json['direction'] as String?) {
        'incoming' => FriendDirection.incoming,
        'outgoing' => FriendDirection.outgoing,
        _ => FriendDirection.friend,
      },
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// The caller's friends plus every open request, in one round trip
/// (`friend_data` RPC). Everything else in this file mutates through the
/// SECURITY DEFINER RPCs and then invalidates this.
@riverpod
class FriendshipController extends _$FriendshipController {
  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  Future<List<FriendUser>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const [];

    final rows = await _supabase
        .rpc('friend_data')
        .timeout(const Duration(seconds: 5));

    return (rows as List)
        .map((r) => FriendUser.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Send (or idempotently re-send) a request. If they already have one out to
  /// us the server accepts theirs instead — so this can turn into an instant
  /// friendship, which is why we always invalidate afterwards.
  Future<void> sendRequest(String userId) async {
    await _supabase
        .rpc('send_friend_request', params: {'p_user_id': userId})
        .timeout(const Duration(seconds: 5));
    ref.invalidateSelf();
  }

  Future<void> respond(String friendshipId, {required bool accept}) async {
    await _supabase.rpc('respond_friend_request', params: {
      'p_friendship_id': friendshipId,
      'p_action': accept ? 'accept' : 'decline',
    }).timeout(const Duration(seconds: 5));
    ref.invalidateSelf();
  }

  /// Cancels an outgoing request or removes an existing friend — one entry
  /// point for both, matching the RPC.
  Future<void> unfriend(String userId) async {
    await _supabase
        .rpc('unfriend', params: {'p_user_id': userId})
        .timeout(const Duration(seconds: 5));
    ref.invalidateSelf();
  }

  Future<void> block(String userId) async {
    await _supabase
        .rpc('block_user', params: {'p_user_id': userId})
        .timeout(const Duration(seconds: 5));
    ref.invalidateSelf();
  }

  Future<void> unblock(String userId) async {
    await _supabase
        .rpc('unblock_user', params: {'p_user_id': userId})
        .timeout(const Duration(seconds: 5));
    ref.invalidateSelf();
  }
}

/// Accepted friends only.
@riverpod
List<FriendUser> friends(Ref ref) =>
    ref.watch(friendshipControllerProvider).value
        ?.where((f) => f.direction == FriendDirection.friend)
        .toList() ??
    const [];

/// Requests waiting on the caller — drives the badge on the friends entry.
@riverpod
List<FriendUser> incomingFriendRequests(Ref ref) =>
    ref.watch(friendshipControllerProvider).value
        ?.where((f) => f.direction == FriendDirection.incoming)
        .toList() ??
    const [];
