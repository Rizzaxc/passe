import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../auth/auth_controller.dart';
import '../core/model/wall_post.dart';
import '../router.dart';
import '../social/friends_screen.dart';
import '../ui/main.dart';
import 'compose_post_sheet.dart';
import 'feed_controller.dart';
import 'post_card.dart';

/// The Feed tab — first in the bottom nav. Wall posts from you, your friends,
/// your lobby mates, and anyone a friend of yours is tagged in. Cross-sport
/// by design (see feed_controller.dart).
///
/// Presents one post per screen in a vertically **snapping** pager — swiping
/// up always lands on the next whole post, never mid-scroll through a list.
/// Each page is the same `PostCard` used on a user's wall and the lobby
/// activity feed, so the visual language matches the rest of the app; only
/// the pacing is different. Empty/error/guest states follow the same
/// `PEmptySectionPlaceholder` + hero icon + direct CTA convention every other
/// tab uses (see e.g. `home_tab/challenger_section/main.dart`'s `_NoLobbyState`).
class FeedTab extends ConsumerWidget {
  const FeedTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          : () async {
              ref.invalidate(wallFeedControllerProvider);
              try {
                await ref.read(wallFeedControllerProvider.future);
              } catch (_) {
                // The Feed body switches to its error state, which already
                // offers another retry path and an explanatory message.
              }
            },
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

    Future<void> refresh() async {
      ref.invalidate(wallFeedControllerProvider);
      await ref.read(wallFeedControllerProvider.future);
    }

    return switch (feedAsync) {
      AsyncLoading() => const Center(child: CircularProgressIndicator()),
      AsyncError() => _CenteredEmpty(
        icon: FLucideIcons.cloudAlert,
        subtitle: 'feed.error'.tr(),
        onRefresh: refresh,
      ),
      AsyncValue(:final value) when (value?.isEmpty ?? true) => _CenteredEmpty(
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
      ),
      AsyncValue(:final value) => _FeedPager(posts: value!),
    };
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

  const _FeedPager({required this.posts});

  @override
  ConsumerState<_FeedPager> createState() => _FeedPagerState();
}

class _FeedPagerState extends ConsumerState<_FeedPager> {
  final _controller = PageController();

  // Drives which post's video is allowed to autoplay (see PostCard.isActive
  // / post_card.dart's _VideoPage) — only the page actually on screen.
  int _activeIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(wallFeedControllerProvider);
    await ref.read(wallFeedControllerProvider.future);
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
        onPageChanged: (i) => setState(() => _activeIndex = i),
        itemBuilder: (_, i) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: PostCard(
              post: widget.posts[i],
              isActive: i == _activeIndex,
            ),
          ),
        ),
      ),
    );
  }
}
