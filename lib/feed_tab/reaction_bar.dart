import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../auth/auth_controller.dart';
import '../core/model/wall_post.dart';
import 'feed_controller.dart';

/// The reaction palette. Fixed and small on purpose: a closed set needs no
/// moderation, unlike free-text comments, and keeps the tally readable.
const kWallReactions = ['🔥', '👏', '😂', '💪', '😮'];

/// Tap to react, tap your own again to clear it. One reaction per person —
/// the DB enforces it with a (post_id, user_id) primary key, so a second
/// choice replaces the first rather than stacking.
class ReactionBar extends ConsumerWidget {
  final WallPost post;

  const ReactionBar({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final isGuest = ref.watch(currentUserIdProvider) == null;

    Future<void> react(String emoji) async {
      if (isGuest) return;
      final next = post.myReaction == emoji ? null : emoji;
      try {
        await ref.read(wallFeedControllerProvider.notifier).react(post.id, next);
      } catch (e, st) {
        Talker().handle(e, st, 'React failed');
        if (!context.mounted) return;
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.circleX),
          variant: .destructive,
          title: Text('feed.reactFailed'.tr()),
          alignment: .bottomCenter,
        );
      }
    }

    return Row(
      children: [
        for (final emoji in kWallReactions) ...[
          _ReactionChip(
            emoji: emoji,
            count: post.reactions[emoji] ?? 0,
            selected: post.myReaction == emoji,
            onTap: isGuest ? null : () => react(emoji),
          ),
          const SizedBox(width: 6),
        ],
        const Spacer(),
        // Total is a short, bounded string (a count), so it needs no guard —
        // unlike the name/venue rows above.
        if (post.reactions.isNotEmpty)
          Text(
            '${post.reactions.values.fold<int>(0, (a, b) => a + b)}',
            style: context.theme.typography.body.xs
                .copyWith(color: colors.mutedForeground),
          ),
      ],
    );
  }
}

class _ReactionChip extends StatelessWidget {
  final String emoji;
  final int count;
  final bool selected;
  final VoidCallback? onTap;

  const _ReactionChip({
    required this.emoji,
    required this.count,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? colors.primary.withValues(alpha: 0.12) : null,
          borderRadius: context.theme.style.borderRadius.sm,
          border: Border.all(
            color: selected ? colors.primary : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            if (count > 0) ...[
              const SizedBox(width: 3),
              Text(
                '$count',
                style: context.theme.typography.body.xs.copyWith(
                  color: selected ? colors.primary : colors.mutedForeground,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
