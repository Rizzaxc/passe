import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:video_player/video_player.dart';

import '../auth/auth_controller.dart';
import '../core/model/wall_post.dart';
import '../router.dart';
import '../ui/main.dart';
import 'feed_controller.dart';
import 'reaction_bar.dart';
import 'report_post_sheet.dart';

/// One post in the feed or on a wall.
///
/// Everything below the images is dynamic-length and user-supplied, so every
/// row here is overflow-guarded — this card renders at 375 px too.
///
/// [isActive] marks this post as the current page of the Feed's vertical
/// pager — the one surface where video autoplays (with sound). Everywhere
/// else this card is used (a user's wall, the lobby activity feed — both
/// scrolling lists where several cards can be near-visible at once) leaves
/// it false, so video there is always tap-to-play. See post_card.dart's
/// `_VideoPage` for the actual play/pause rule.
class PostCard extends ConsumerWidget {
  final WallPost post;
  final bool isActive;

  const PostCard({super.key, required this.post, this.isActive = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final isMine = ref.watch(currentUserIdProvider) == post.authorId;

    return PCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(post: post, isMine: isMine),
          const SizedBox(height: 10),
          _SourceLine(post: post),
          const SizedBox(height: 10),
          _Media(media: post.media, isActive: isActive),
          if (post.caption != null && post.caption!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              post.caption!,
              style: context.theme.typography.body.sm,
            ),
          ],
          if (post.tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            _Tags(tags: post.tags),
          ],
          const SizedBox(height: 8),
          Divider(height: 16, color: colors.border.withValues(alpha: 0.5)),
          ReactionBar(post: post),
        ],
      ),
    );
  }
}

/// Feed-only, full-page treatment. Media owns the flexible space while the
/// post context stays in a compact, readable panel below it. Other surfaces
/// continue to use [PostCard]'s conventional 4:3 card.
class FeedPostCard extends ConsumerWidget {
  final WallPost post;
  final bool isActive;

  const FeedPostCard({
    super.key,
    required this.post,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final isMine = ref.watch(currentUserIdProvider) == post.authorId;

    return FCard(
      clipBehavior: Clip.antiAlias,
      builder: (context, _, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Media(
              media: post.media,
              isActive: isActive,
              fillAvailable: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(post: post, isMine: isMine, allowHide: true),
                const SizedBox(height: 8),
                if (post.caption != null && post.caption!.isNotEmpty) ...[
                  Text(
                    post.caption!,
                    style: context.theme.typography.body.sm,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                ],
                _SourceLine(post: post),
                if (post.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _Tags(tags: post.tags),
                ],
                const SizedBox(height: 6),
                Divider(
                  height: 12,
                  color: colors.border.withValues(alpha: 0.5),
                ),
                ReactionBar(post: post),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  final WallPost post;
  final bool isMine;
  final bool allowHide;

  const _Header({
    required this.post,
    required this.isMine,
    this.allowHide = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return Row(
      children: [
        PUserAvatar(
          userId: post.authorId,
          username: post.authorUsername,
          generatedAvatar: post.authorGeneratedAvatar,
          radius: 18,
          onTap: () => UserRoute(id: post.authorId, $extra: post.authorUsername)
              .push(context),
        ),
        const SizedBox(width: 10),
        // Name and the "còn N ngày" line share the flexible space; the
        // trailing button is fixed-width, so nothing here can push it off.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () =>
                    UserRoute(id: post.authorId, $extra: post.authorUsername)
                        .push(context),
                child: Text(
                  post.authorUsername,
                  style: typography.body.sm.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _remaining(context, post.expiresAt),
                style: typography.body.xs
                    .copyWith(color: colors.mutedForeground),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        FButton.icon(
          variant: .ghost,
          onPress: () => _showOverflow(context, ref),
          child: const Icon(FLucideIcons.ellipsis, size: 16),
        ),
      ],
    );
  }

  /// Posts are ephemeral, so "how long is left" is more useful than "when was
  /// this posted" — it's the whole point of the TTL.
  String _remaining(BuildContext context, DateTime expiresAt) {
    final left = expiresAt.difference(DateTime.now());
    if (left.isNegative) return 'feed.expired'.tr();
    if (left.inHours < 1) {
      return 'feed.remainingMinutes'
          .tr(namedArgs: {'count': '${left.inMinutes}'});
    }
    if (left.inHours < 24) {
      return 'feed.remainingHours'.tr(namedArgs: {'count': '${left.inHours}'});
    }
    return 'feed.remainingDays'.tr(namedArgs: {'count': '${left.inDays}'});
  }

  void _showOverflow(BuildContext context, WidgetRef ref) {
    showPSheet(
      context: context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          PSheetTitle(label: post.authorHandle),
          if (isMine)
            FButton(
              variant: .destructive,
              prefix: const Icon(FLucideIcons.trash),
              onPress: () async {
                Navigator.of(sheetContext).pop();
                try {
                  await ref
                      .read(wallFeedControllerProvider.notifier)
                      .deletePost(post.id);
                } catch (e, st) {
                  Talker().handle(e, st, 'Delete post failed');
                  if (!context.mounted) return;
                  showFToast(
                    context: context,
                    icon: const Icon(FLucideIcons.circleX),
                    variant: .destructive,
                    title: Text('feed.deleteFailed'.tr()),
                    alignment: .bottomCenter,
                  );
                }
              },
              child: Text('feed.deletePost'.tr()),
            )
          else
            FButton(
              variant: .outline,
              prefix: const Icon(FLucideIcons.flag),
              onPress: () {
                Navigator.of(sheetContext).pop();
                showReportPostSheet(context, postId: post.id);
              },
              child: Text('feed.reportPost'.tr()),
            ),
          if (allowHide)
            FButton(
              variant: .outline,
              prefix: const Icon(FLucideIcons.eyeOff),
              onPress: () async {
                final toastContext =
                    Navigator.of(context, rootNavigator: true).context;
                Navigator.of(sheetContext).pop();
                try {
                  await ref
                      .read(hiddenFeedPostsProvider.notifier)
                      .hide(post.id);
                  if (!toastContext.mounted) return;
                  showFToast(
                    context: toastContext,
                    icon: const Icon(FLucideIcons.eyeOff),
                    title: Text('feed.postHidden'.tr()),
                    alignment: .bottomCenter,
                  );
                } catch (e, st) {
                  Talker().handle(e, st, 'Hide Feed post failed');
                  if (!toastContext.mounted) return;
                  showFToast(
                    context: toastContext,
                    icon: const Icon(FLucideIcons.circleX),
                    variant: .destructive,
                    title: Text('feed.hideFailed'.tr()),
                    alignment: .bottomCenter,
                  );
                }
              },
              child: Text('feed.hidePost'.tr()),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// The "hook" line — where this post came from. Rendered entirely from the
/// post's snapshot columns, never from the activity (which may be gone).
class _SourceLine extends StatelessWidget {
  final WallPost post;

  const _SourceLine({required this.post});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final parts = <String>[
      if (post.sourceLabel != null && post.sourceLabel!.isNotEmpty)
        post.sourceLabel!,
      DateFormat('EEEE, d/M', context.locale.toString())
          .format(post.sourceStartTime),
      if (post.sourceVenueName != null && post.sourceVenueName!.isNotEmpty)
        post.sourceVenueName!,
    ];

    return Row(
      children: [
        Icon(FLucideIcons.calendarCheck, size: 13, color: colors.primary),
        const SizedBox(width: 6),
        // One Flexible around the whole joined string: the pieces ellipsize
        // together at the end rather than each shrinking independently.
        Flexible(
          child: Text(
            parts.join(' · '),
            style: context.theme.typography.body.xs
                .copyWith(color: colors.mutedForeground),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// A post's media carousel (1-4 items, mixed images/video, order = display
/// order). Video only ever autoplays for the item that is both [isActive]
/// (this post is the Feed pager's current page) *and* the carousel's current
/// page — swiping horizontally to a video starts it, swiping away pauses it;
/// everywhere else (or once isActive goes false) video is tap-to-play.
class _Media extends StatefulWidget {
  final List<WallPostMedia> media;
  final bool isActive;
  final bool fillAvailable;

  const _Media({
    required this.media,
    required this.isActive,
    this.fillAvailable = false,
  });

  @override
  State<_Media> createState() => _MediaState();
}

class _MediaState extends State<_Media> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    Widget buildItem(int i) {
      final item = widget.media[i];
      if (!item.isVideo) {
        return CachedNetworkImage(
          imageUrl: item.url,
          fit: BoxFit.cover,
          placeholder: (_, _) => Container(color: colors.muted),
          errorWidget: (_, _, _) => Container(
            color: colors.muted,
            alignment: Alignment.center,
            child: Icon(FLucideIcons.imageOff,
                color: colors.mutedForeground),
          ),
        );
      }
      return _VideoPage(
        key: ValueKey(item.path),
        media: item,
        shouldAutoplay: widget.isActive && i == _index,
      );
    }

    // A one-item PageView still enters Flutter's gesture arena. Because the
    // media fills most of the screen, a forceful diagonal swipe could let
    // that horizontal pager beat the outer vertical Feed pager even though
    // it had nowhere to scroll. Render the item directly in the common
    // single-media case; only real carousels compete for horizontal drags.
    final pager = widget.media.length == 1
        ? buildItem(0)
        : PageView.builder(
            controller: _controller,
            itemCount: widget.media.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => buildItem(i),
          );

    final media = ClipRRect(
      borderRadius: context.theme.style.borderRadius.md,
      child: widget.fillAvailable
          ? pager
          : AspectRatio(aspectRatio: 4 / 3, child: pager),
    );

    return Column(
      children: [
        // Feed media flexes to consume the page; shared cards keep a stable
        // 4:3 box so they do not jump while media loads.
        if (widget.fillAvailable) Expanded(child: media) else media,
        if (widget.media.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.media.length; i++)
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _index ? colors.primary : colors.border,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// One video item. Effective playing state is `_userOverride ?? shouldAutoplay`:
/// [shouldAutoplay] alone drives it in the Feed pager (the only surface where
/// it's ever true), a tap sets [_userOverride] which wins until
/// [shouldAutoplay] itself flips (a fresh autoplay/no-autoplay occasion clears
/// any stale override). Swiping this page out of the carousel disposes the
/// controller entirely via normal PageView.builder recycling — no explicit
/// reset needed for that path, only for the isActive-flips-while-still-mounted
/// path that didUpdateWidget below handles.
class _VideoPage extends ConsumerStatefulWidget {
  final WallPostMedia media;
  final bool shouldAutoplay;

  const _VideoPage({
    super.key,
    required this.media,
    required this.shouldAutoplay,
  });

  @override
  ConsumerState<_VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends ConsumerState<_VideoPage> {
  VideoPlayerController? _controller;
  bool? _userOverride;

  bool get _playing => _userOverride ?? widget.shouldAutoplay;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant _VideoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shouldAutoplay != widget.shouldAutoplay) {
      _userOverride = null;
      _sync();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _ensureController() async {
    if (_controller != null) return;
    final controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.media.url));
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(ref.read(feedVideoMutedProvider) ? 0 : 1);
      if (!mounted) return;
      setState(() {});
      _sync();
    } catch (_) {
      // Leave the poster frame showing — no player, no crash.
    }
  }

  void _sync() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      if (_playing) _ensureController();
      return;
    }
    if (_playing) {
      c.play();
    } else {
      c.pause();
    }
  }

  void _toggleTap() {
    setState(() => _userOverride = !_playing);
    _sync();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final muted = ref.watch(feedVideoMutedProvider);
    final controller = _controller;

    ref.listen(feedVideoMutedProvider, (_, next) {
      controller?.setVolume(next ? 0 : 1);
    });

    return GestureDetector(
      onTap: _toggleTap,
      child: ColoredBox(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.media.thumbnailUrl != null)
              CachedNetworkImage(
                imageUrl: widget.media.thumbnailUrl!,
                fit: BoxFit.contain,
                placeholder: (_, _) => Container(color: colors.muted),
                errorWidget: (_, _, _) => const SizedBox.shrink(),
              ),
            if (controller != null && controller.value.isInitialized)
              FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              ),
            if (!_playing)
              Container(
                color: Colors.black26,
                alignment: Alignment.center,
                child: const Icon(FLucideIcons.play,
                    color: Colors.white, size: 40),
              ),
            if (controller != null && controller.value.isInitialized)
              Positioned(
                right: 8,
                bottom: 8,
                child: GestureDetector(
                  onTap: () =>
                      ref.read(feedVideoMutedProvider.notifier).toggle(),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      muted ? FLucideIcons.volumeX : FLucideIcons.volume2,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Tagged people. Tapping a chip opens their page — this is the intended
/// befriend funnel, so the chips have to be reachable, not decorative.
class _Tags extends StatelessWidget {
  final List<WallPostTag> tags;

  const _Tags({required this.tags});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final tag in tags)
          GestureDetector(
            onTap: () =>
                UserRoute(id: tag.userId, $extra: tag.username).push(context),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colors.secondary,
                borderRadius: context.theme.style.borderRadius.sm,
              ),
              child: ConstrainedBox(
                // A username is up to 16 chars; cap the chip so five of them
                // can't push the wrap into absurd rows on a narrow screen.
                constraints: const BoxConstraints(maxWidth: 140),
                child: Text(
                  '@${tag.username}',
                  style: context.theme.typography.body.xs
                      .copyWith(color: colors.secondaryForeground),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
