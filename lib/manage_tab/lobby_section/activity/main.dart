// Activity tab — single scroll view (hero + feed) + fixed chat trigger bar
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/model/enum.dart';
import 'feed.dart';
import 'feed_controller.dart';
import 'hero.dart';
import 'trigger_bar.dart';
import 'upcoming_controller.dart';

class ActivityTab extends ConsumerWidget {
  final String lobbyId;
  final bool isLeader;
  final Sport? sport;

  const ActivityTab({
    super.key,
    required this.lobbyId,
    required this.isLeader,
    required this.sport,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Whether the lobby currently has an upcoming activity pinned. The
    // hero's expanded vs. empty branch keys off this flag.
    final upcoming =
        ref.watch(lobbyUpcomingActivityControllerProvider(lobbyId));
    final hasActivity = upcoming.value != null;
    // The chat-style action feed. Empty while loading / on error — the
    // hero still renders so the screen isn't blank.
    final feed =
        ref.watch(lobbyFeedControllerProvider(lobbyId)).value ??
            const <FeedItem>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Pinned context block — sits between the tab bar and the
        // scrolling feed so the next-session card stays visible no
        // matter how far the user scrolls into older messages.
        ActivityHero(
          lobbyId: lobbyId,
          sport: sport,
          hasActivity: hasActivity,
          isLeader: isLeader,
        ),
        Expanded(
          // Chat-anchored: newest message at the bottom (initial view),
          // scroll up to reveal older messages.
          child: ListView(
            reverse: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              // Children laid out bottom-up: index 0 sits at the bottom.
              for (final item in feed.reversed)
                FeedItemWidget(item: item),
            ],
          ),
        ),
        ChatTriggerBar(
          isLeader: isLeader,
          onOpen: () => showActionPickerSheet(
            context,
            isLeader: isLeader,
            hasActivity: hasActivity,
          ),
        ),
      ],
    );
  }
}
