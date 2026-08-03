import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

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
class PostCard extends ConsumerWidget {
  final WallPost post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final isMine = ref.watch(currentUserIdProvider) == post.authorId;

    return FCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(post: post, isMine: isMine),
          const SizedBox(height: 10),
          _SourceLine(post: post),
          const SizedBox(height: 10),
          _Images(urls: post.imageUrls),
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

class _Header extends ConsumerWidget {
  final WallPost post;
  final bool isMine;

  const _Header({required this.post, required this.isMine});

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

class _Images extends StatefulWidget {
  final List<String> urls;

  const _Images({required this.urls});

  @override
  State<_Images> createState() => _ImagesState();
}

class _ImagesState extends State<_Images> {
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

    return Column(
      children: [
        ClipRRect(
          borderRadius: context.theme.style.borderRadius.md,
          // Fixed aspect ratio: the images aren't measured before they load,
          // so without this the card would jump as each one arrives.
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.urls.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => CachedNetworkImage(
                imageUrl: widget.urls[i],
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(color: colors.muted),
                errorWidget: (_, _, _) => Container(
                  color: colors.muted,
                  alignment: Alignment.center,
                  child: Icon(FLucideIcons.imageOff,
                      color: colors.mutedForeground),
                ),
              ),
            ),
          ),
        ),
        if (widget.urls.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.urls.length; i++)
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
