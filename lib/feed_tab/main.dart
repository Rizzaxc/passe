import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../auth/auth_controller.dart';
import '../core/model/wall_post.dart';
import '../router.dart';
import '../social/friends_screen.dart';
import '../ui/main.dart';
import 'compose_post_sheet.dart';
import 'feed_controller.dart';
import 'post_card.dart';

Future<void> _refreshFeed(BuildContext context, WidgetRef ref) async {
  ref.invalidate(wallFeedControllerProvider);
  ref.invalidate(hiddenFeedPostsProvider);
  try {
    await Future.wait([
      ref.read(wallFeedControllerProvider.future),
      ref.read(hiddenFeedPostsProvider.future),
    ]);
  } catch (e, st) {
    // RefreshIndicator expects its callback to complete normally so it can
    // dismiss. The provider still retains the error state for initial-load
    // handling; an in-place refresh surfaces it here without dropping the
    // stale posts that remain useful to the user.
    Talker().handle(e, st, 'Refresh wall feed failed');
    if (!context.mounted) return;
    showFToast(
      context: context,
      icon: const Icon(FLucideIcons.cloudAlert),
      variant: .destructive,
      title: Text('feed.error'.tr()),
      alignment: .bottomCenter,
    );
  }
}

/// The Feed tab — first in the bottom nav. Wall posts from you, your friends,
/// your lobby mates, and anyone a friend of yours is tagged in. Cross-sport
/// by design (see feed_controller.dart).
///
/// Presents one post per screen in a vertically **snapping** pager — swiping
/// up always lands on the next whole post, never mid-scroll through a list.
/// Each page uses the Feed-only `FeedPostCard`, while a user's wall and lobby
/// activity feed retain the compact shared `PostCard`. Empty/error/guest
/// states follow the same
/// `PEmptySectionPlaceholder` + hero icon + direct CTA convention every other
/// tab uses (see e.g. `discover_tab/challenger_section/main.dart`'s `_NoLobbyState`).
class FeedTab extends ConsumerStatefulWidget {
  const FeedTab({super.key});

  @override
  ConsumerState<FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends ConsumerState<FeedTab> {
  @override
  void initState() {
    super.initState();
    // "Opened the tab" is the read signal — not "scrolled through every
    // post" — matching the achievements tab's unseen-flag posture. Marking
    // happens here, never from the router's unread check, or computing
    // "should I land on Feed" would immediately erase the signal it just
    // found.
    if (ref.read(currentUserIdProvider) != null) {
      ref.read(feedLastVisitedAtProvider.notifier).markVisitedNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = ref.watch(currentUserIdProvider) == null;

    return FScaffold(
      header: FHeader(
        title: Text('nav.feed'.tr()),
        suffixes: [
          // This re-reads the feed immediately; pull-to-refresh remains
          // available inside the pager and empty/error states.
          if (!isGuest) const _FeedRefreshButton(),
          const NotificationIconButton(),
          // Posting requires being signed in — hide the CTA for guests
          // rather than let it lead to an RPC that will just reject them.
          if (!isGuest)
            FButton.icon(
              variant: .ghost,
              onPress: () => showComposePostSheet(context),
              child: const Icon(FLucideIcons.plus),
            ),
        ],
      ),
      child: isGuest ? const _GuestState() : const _FeedBody(),
    );
  }
}

/// Header-level force refresh for when the user wants to fetch new posts
/// without first scrolling back to the top of the pager.
class _FeedRefreshButton extends ConsumerWidget {
  const _FeedRefreshButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refreshing = ref.watch(wallFeedControllerProvider).isLoading;

    return FButton.icon(
      variant: .ghost,
      onPress: refreshing
          ? null
          : () => _refreshFeed(context, ref),
      child: refreshing
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(FLucideIcons.refreshCw, size: 20),
    );
  }
}

/// A guest has no friends and no lobbies, so the feed is empty by
/// construction — say so, with a way out, rather than showing a spinner
/// forever or a bare line of text.
class _GuestState extends StatelessWidget {
  const _GuestState();

  @override
  Widget build(BuildContext context) {
    return _CenteredEmpty(
      icon: FLucideIcons.userX,
      title: 'feed.guestTitle'.tr(),
      subtitle: 'feed.guest'.tr(),
      cta: FButton(
        onPress: () => const ProfileRoute().go(context),
        child: Text('auth.guestPrompt.cta'.tr()),
      ),
    );
  }
}

class _FeedBody extends ConsumerWidget {
  const _FeedBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(wallFeedControllerProvider);
    final hiddenAsync = ref.watch(hiddenFeedPostsProvider);

    Future<void> refresh() => _refreshFeed(context, ref);
    Future<void> loadMore() async {
      try {
        await ref.read(wallFeedControllerProvider.notifier).loadMore();
      } catch (e, st) {
        Talker().handle(e, st, 'Load more wall posts failed');
        if (!context.mounted) return;
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.cloudAlert),
          variant: .destructive,
          title: Text('feed.loadMoreFailed'.tr()),
          alignment: .bottomCenter,
        );
      }
    }

    // Keep resolved content mounted while Riverpod refreshes it. Replacing
    // the pager/empty scrollable with a loading spinner here would dispose
    // the RefreshIndicator that is still awaiting [refresh], leaving a
    // force-refresh gesture looking frozen until the request times out.
    if ((feedAsync.isLoading && !feedAsync.hasValue) ||
        (hiddenAsync.isLoading && !hiddenAsync.hasValue)) {
      return const Center(child: CircularProgressIndicator());
    }

    if ((feedAsync.hasError && !feedAsync.hasValue) ||
        (hiddenAsync.hasError && !hiddenAsync.hasValue)) {
      return _CenteredEmpty(
        icon: FLucideIcons.cloudAlert,
        subtitle: 'feed.error'.tr(),
        onRefresh: refresh,
      );
    }

    final posts = feedAsync.value ?? const <WallPost>[];
    if (posts.isEmpty) {
      return _CenteredEmpty(
        icon: FLucideIcons.images,
        title: 'feed.emptyTitle'.tr(),
        subtitle: 'feed.empty'.tr(),
        cta: FButton(
          onPress: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const FriendsScreen()),
          ),
          child: Text('feed.findFriends'.tr()),
        ),
        onRefresh: refresh,
      );
    }

    final hiddenIds = hiddenAsync.value ?? const <String>{};
    final visiblePosts = posts
        .where((post) => !hiddenIds.contains(post.id))
        .toList(growable: false);
    final feedController = ref.read(wallFeedControllerProvider.notifier);
    if (visiblePosts.length < 3 && feedController.canAutoLoadMore) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) loadMore();
      });
      if (visiblePosts.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
    }

    if (visiblePosts.isEmpty && feedController.loadMoreFailed) {
      return _CenteredEmpty(
        icon: FLucideIcons.cloudAlert,
        subtitle: 'feed.loadMoreFailed'.tr(),
        onRefresh: refresh,
      );
    }

    if (visiblePosts.isEmpty) {
      return _CenteredEmpty(
        icon: FLucideIcons.eyeOff,
        title: 'feed.hiddenTitle'.tr(),
        subtitle: 'feed.hidden'.tr(),
        cta: FButton(
          onPress: () async {
            try {
              await ref.read(hiddenFeedPostsProvider.notifier).clear();
            } catch (e, st) {
              Talker().handle(e, st, 'Restore hidden Feed posts failed');
              if (!context.mounted) return;
              showFToast(
                context: context,
                icon: const Icon(FLucideIcons.circleX),
                variant: .destructive,
                title: Text('feed.restoreHiddenFailed'.tr()),
                alignment: .bottomCenter,
              );
            }
          },
          child: Text('feed.showHiddenPosts'.tr()),
        ),
        onRefresh: refresh,
      );
    }

    return _FeedPager(posts: visiblePosts, onLoadMore: loadMore);
  }
}

/// Hero icon + title + subtitle + an optional direct CTA, vertically centered
/// in whatever space is available — the same building blocks every other
/// tab's empty state uses (`PEmptySectionPlaceholder`), just centered rather
/// than pinned to the top of a list, since here it's the *entire* tab rather
/// than one section among several. Still wrapped in a pull-to-refresh
/// scrollable when [onRefresh] is given, matching every other feed.
class _CenteredEmpty extends StatelessWidget {
  final IconData icon;
  final String? title;
  final String subtitle;
  final Widget? cta;
  final Future<void> Function()? onRefresh;

  const _CenteredEmpty({
    required this.icon,
    required this.subtitle,
    this.title,
    this.cta,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final body = LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PEmptySectionPlaceholder(
                  hero: Icon(
                    icon,
                    size: 64,
                    color: context.theme.colors.mutedForeground,
                  ),
                  title: title,
                  subtitle: subtitle,
                ),
                if (cta != null) ...[const SizedBox(height: 16), cta!],
              ],
            ),
          ),
        ),
      ),
    );

    if (onRefresh == null) return body;
    return RefreshIndicator(onRefresh: onRefresh!, child: body);
  }
}

class _FeedPager extends ConsumerStatefulWidget {
  final List<WallPost> posts;
  final Future<void> Function() onLoadMore;

  const _FeedPager({required this.posts, required this.onLoadMore});

  @override
  ConsumerState<_FeedPager> createState() => _FeedPagerState();
}

class _FeedPagerState extends ConsumerState<_FeedPager> {
  final _controller = PageController();

  // Drives which post's video is allowed to autoplay (see PostCard.isActive
  // / post_card.dart's _VideoPage) — only the page actually on screen.
  int _activeIndex = 0;

  @override
  void didUpdateWidget(covariant _FeedPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.posts.isEmpty || _activeIndex < widget.posts.length) return;
    _activeIndex = widget.posts.length - 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _controller.hasClients) {
        _controller.jumpToPage(_activeIndex);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await _refreshFeed(context, ref);
  }

  void _onPageChanged(int index) {
    setState(() => _activeIndex = index);
    if (index >= widget.posts.length - 2) widget.onLoadMore();
  }

  @override
  Widget build(BuildContext context) {
    // A vertical PageView is still a Scrollable, so overscrolling past the
    // first post drags-to-refresh the same way every other feed does. It
    // also snaps one full page per swipe by default — no extra physics
    // needed for the "one post at a time" pacing.
    return RefreshIndicator(
      onRefresh: _refresh,
      child: PageView.builder(
        controller: _controller,
        scrollDirection: Axis.vertical,
        itemCount: widget.posts.length,
        onPageChanged: _onPageChanged,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: FeedPostCard(
            key: ValueKey(widget.posts[i].id),
            post: widget.posts[i],
            isActive: i == _activeIndex,
          ),
        ),
      ),
    );
  }
}
