import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_controller.dart';
import '../core/achievement_evaluator.dart';
import '../core/model/wall_post.dart';

part 'feed_controller.g.dart';

/// The Feed's own sport filter — deliberately **not** `selectedSportStateProvider`.
///
/// Every Discover subtab is scoped to the context sport, but a social feed
/// scoped that way would hide a friend's badminton photo while you happen to
/// be in soccer mode. So the Feed defaults to all sports and offers this as an
/// opt-in chip. `null` = every sport.
@Riverpod(keepAlive: true)
class FeedSportFilter extends _$FeedSportFilter {
  @override
  int? build() => null;

  void set(int? sportId) => state = sportId;
}

/// Session-wide "is autoplaying video muted" preference — unmuted by
/// default (video only ever autoplays in the Feed pager, with sound). The
/// mute toggle on a playing video (post_card.dart's `_VideoPage`) flips this,
/// and it carries forward to the next video the user lands on rather than
/// resetting per-video.
@Riverpod(keepAlive: true)
class FeedVideoMuted extends _$FeedVideoMuted {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

/// Posts from the caller, their friends, their lobby mates, and any post a
/// friend of theirs is tagged in. Visibility is resolved server-side in
/// `wall_feed_data` — the client never assembles the audience itself.
@riverpod
class WallFeedController extends _$WallFeedController {
  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  Future<List<WallPost>> build() async {
    // Guests have no friends and no lobbies, so the feed is empty by
    // definition — skip the round trip rather than returning an empty list
    // from the server.
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const [];

    final sportId = ref.watch(feedSportFilterProvider);

    final rows = await _supabase.rpc('wall_feed_data', params: {
      'p_sport_id': sportId,
      'p_page_size': 20,
      'p_page_number': 0,
    }).timeout(const Duration(seconds: 5));

    return (rows as List)
        .map((r) => WallPost.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Set, change, or (with a null emoji) clear the caller's reaction.
  ///
  /// Applied optimistically so the tap feels instant, then rolled back if the
  /// RPC fails — the same approach as the teammate feed's request button.
  Future<void> react(String postId, String? emoji) async {
    final previous = state.value;
    if (previous != null) {
      state = AsyncData([
        for (final p in previous)
          if (p.id == postId) _withReaction(p, emoji) else p,
      ]);
    }

    try {
      await _supabase.rpc('react_to_wall_post', params: {
        'p_post_id': postId,
        'p_emoji': emoji,
      }).timeout(const Duration(seconds: 5));
    } catch (_) {
      if (previous != null) state = AsyncData(previous);
      rethrow;
    }

    // Only reacting (not clearing) can move the "react to N posts" badge.
    final userId = ref.read(currentUserIdProvider);
    if (emoji != null && userId != null) {
      await evaluateAchievements(ref, userId);
    }
  }

  Future<void> deletePost(String postId) async {
    await _supabase
        .rpc('delete_wall_post', params: {'p_post_id': postId})
        .timeout(const Duration(seconds: 5));
    ref.invalidateSelf();
  }

  WallPost _withReaction(WallPost post, String? emoji) {
    final counts = Map<String, int>.from(post.reactions);

    final old = post.myReaction;
    if (old != null) {
      final n = (counts[old] ?? 1) - 1;
      if (n <= 0) {
        counts.remove(old);
      } else {
        counts[old] = n;
      }
    }
    if (emoji != null) counts[emoji] = (counts[emoji] ?? 0) + 1;

    return WallPost(
      id: post.id,
      authorId: post.authorId,
      authorUsername: post.authorUsername,
      authorTagNumber: post.authorTagNumber,
      authorGeneratedAvatar: post.authorGeneratedAvatar,
      sportId: post.sportId,
      lobbyId: post.lobbyId,
      sourceLabel: post.sourceLabel,
      sourceStartTime: post.sourceStartTime,
      sourceVenueName: post.sourceVenueName,
      caption: post.caption,
      media: post.media,
      createdAt: post.createdAt,
      expiresAt: post.expiresAt,
      tags: post.tags,
      reactions: counts,
      myReaction: emoji,
    );
  }
}
