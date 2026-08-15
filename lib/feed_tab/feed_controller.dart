import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_controller.dart';
import '../core/achievement_evaluator.dart';
import '../core/model/wall_post.dart';
import '../core/user_preferences.dart';

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

/// Post ids the signed-in user chose to hide from the main Feed on this
/// device. This is display state only: it does not mutate the post, affect
/// other users, or hide the same card on lobby/profile surfaces.
@Riverpod(keepAlive: true)
class HiddenFeedPosts extends _$HiddenFeedPosts {
  static const _prefKey = 'HIDDEN_FEED_POST_IDS';
  static const _maxStoredIds = 200;

  @override
  Future<Set<String>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const {};
    final stored =
        await UserPreferences.instance.getStringList(_prefKey) ?? const [];
    return stored.toSet();
  }

  Future<void> hide(String postId) async {
    final ordered = [...?state.value]..remove(postId)..add(postId);
    if (ordered.length > _maxStoredIds) {
      ordered.removeRange(0, ordered.length - _maxStoredIds);
    }
    await _persist(ordered.toSet());
  }

  Future<void> clear() => _persist(const <String>{});

  Future<void> _persist(Set<String> next) async {
    final saved = await UserPreferences.instance.setStringList(
      _prefKey,
      next.toList(),
    );
    if (!saved) throw StateError('Could not persist hidden Feed posts');
    state = AsyncData(next);
  }
}

/// When the signed-in user last opened the Feed tab on this device — a
/// per-device watermark, not synced across devices (same posture as the đá
/// balance and `HiddenFeedPosts` above). Written *only* from `FeedTab`'s
/// `initState` (see `main.dart`) when the tab is actually opened — never
/// from [feedHasUnread] itself, or checking "is there anything unread" would
/// immediately erase the thing it just found.
@Riverpod(keepAlive: true)
class FeedLastVisitedAt extends _$FeedLastVisitedAt {
  static const _prefKey = 'FEED_LAST_VISITED_AT';

  @override
  Future<DateTime?> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return null;
    final stored = await UserPreferences.instance.getString(_prefKey);
    return stored == null ? null : DateTime.tryParse(stored);
  }

  Future<void> markVisitedNow() async {
    final now = DateTime.now().toUtc();
    final saved = await UserPreferences.instance.setString(
      _prefKey,
      now.toIso8601String(),
    );
    if (saved) state = AsyncData(now);
  }
}

/// Whether the caller has a wall post newer than [FeedLastVisitedAt] from
/// someone other than themselves — drives `router.dart`'s initial-tab pick
/// (guest -> Discover, unread Feed -> Feed, else -> Manage). Not wired to a
/// nav-bar badge or kept live during a session; it's read once at cold start.
@riverpod
Future<bool> feedHasUnread(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return false;

  final lastVisited = await ref.watch(feedLastVisitedAtProvider.future);
  final result = await Supabase.instance.client
      .rpc(
        'wall_feed_has_unread',
        params: {'p_since': lastVisited?.toUtc().toIso8601String()},
      )
      .timeout(const Duration(seconds: 5));
  return result as bool;
}

/// Posts from the caller, their friends, their lobby mates, and any post a
/// friend of theirs is tagged in. Visibility is resolved server-side in
/// `wall_feed_data` — the client never assembles the audience itself.
@riverpod
class WallFeedController extends _$WallFeedController {
  static const _pageSize = 5;

  SupabaseClient get _supabase => Supabase.instance.client;
  int _generation = 0;
  int _nextPage = 1;
  int? _sportId;
  bool _hasMore = true;
  bool _loadingMore = false;
  bool _loadMoreFailed = false;

  bool get hasMore => _hasMore;
  bool get loadMoreFailed => _loadMoreFailed;
  bool get canAutoLoadMore =>
      _hasMore && !_loadingMore && !_loadMoreFailed;

  @override
  Future<List<WallPost>> build() async {
    final generation = ++_generation;
    _sportId = ref.watch(feedSportFilterProvider);
    _nextPage = 1;
    _hasMore = true;
    _loadingMore = false;
    _loadMoreFailed = false;

    // Guests have no friends and no lobbies, so the feed is empty by
    // definition — skip the round trip rather than returning an empty list
    // from the server.
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) {
      _hasMore = false;
      return const [];
    }

    final posts = await _fetchPage(0, sportId: _sportId);
    if (generation == _generation) {
      _hasMore = posts.length == _pageSize;
    }
    return posts;
  }

  Future<List<WallPost>> _fetchPage(
    int pageNumber, {
    required int? sportId,
  }) async {
    final rows = await _supabase.rpc('wall_feed_data', params: {
      'p_sport_id': sportId,
      'p_page_size': _pageSize,
      'p_page_number': pageNumber,
    }).timeout(const Duration(seconds: 5));

    return (rows as List)
        .map((r) => WallPost.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Fetches the next five posts while retaining the already rendered page.
  /// Deduplication protects the client from an item shifting between OFFSET
  /// pages if a new post lands between requests.
  Future<void> loadMore() async {
    if (!_hasMore || _loadingMore) return;
    final current = state.value;
    if (current == null) return;

    final generation = _generation;
    final sportId = _sportId;
    _loadingMore = true;
    _loadMoreFailed = false;
    try {
      final page = await _fetchPage(_nextPage, sportId: sportId);
      if (generation != _generation) return;
      final knownIds = current.map((post) => post.id).toSet();
      final combined = [
        ...current,
        ...page.where((post) => knownIds.add(post.id)),
      ];
      _nextPage++;
      _hasMore = page.length == _pageSize;
      state = AsyncData(combined);
    } catch (_) {
      if (generation != _generation) return;
      _loadMoreFailed = true;
      state = AsyncData(current);
      rethrow;
    } finally {
      if (generation == _generation) _loadingMore = false;
    }
  }

  /// Toggle one of the caller's reactions.
  ///
  /// Applied optimistically so the tap feels instant, then rolled back if the
  /// RPC fails — the same approach as the teammate feed's request button.
  Future<void> react(String postId, String emoji) async {
    final previous = state.value;
    final wasSelected =
        previous
            ?.where((post) => post.id == postId)
            .firstOrNull
            ?.myReactions
            .contains(emoji) ??
        false;
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

    // Only adding a reaction (not removing one) can move the badge.
    final userId = ref.read(currentUserIdProvider);
    if (!wasSelected && userId != null) {
      await evaluateAchievements(ref, userId);
    }
  }

  Future<void> deletePost(String postId) async {
    await _supabase
        .rpc('delete_wall_post', params: {'p_post_id': postId})
        .timeout(const Duration(seconds: 5));
    ref.invalidateSelf();
  }

  WallPost _withReaction(WallPost post, String emoji) {
    final counts = Map<String, int>.from(post.reactions);
    final myReactions = [...post.myReactions];
    if (myReactions.remove(emoji)) {
      final n = (counts[emoji] ?? 1) - 1;
      if (n <= 0) {
        counts.remove(emoji);
      } else {
        counts[emoji] = n;
      }
    } else {
      myReactions.add(emoji);
      counts[emoji] = (counts[emoji] ?? 0) + 1;
    }

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
      myReactions: myReactions,
    );
  }
}
