// Activity tab — single scroll view (hero + feed) + fixed chat trigger bar
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/model/enum.dart';
import 'feed.dart';
import 'feed_controller.dart';
import 'hero.dart';
import 'trigger_bar.dart';
import 'upcoming_controller.dart';

/// Overscroll threshold (px away from the newest message) past which the
/// hero collapses to its compact form. Hysteresis (enter/exit at
/// different offsets) avoids flicker right at the boundary.
const _kCompactEnter = 48.0;
const _kCompactExit = 16.0;

class ActivityTab extends HookConsumerWidget {
  final String lobbyId;
  final bool isLeader;
  final Sport? sport;
  final String? captainId;

  const ActivityTab({
    super.key,
    required this.lobbyId,
    required this.isLeader,
    required this.sport,
    this.captainId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Whether the lobby currently has an upcoming activity pinned. The
    // hero's expanded vs. empty branch keys off this flag.
    final upcoming = ref.watch(
      lobbyUpcomingActivityControllerProvider(lobbyId),
    );
    final upcomingActivity = upcoming.value;
    final hasActivity = upcomingActivity != null;
    // The chat-style action feed. Empty while loading / on error — the
    // hero still renders so the screen isn't blank.
    final feed =
        ref.watch(lobbyFeedControllerProvider(lobbyId)).value ??
        const <FeedItem>[];

    final scrollController = useScrollController();
    final compact = useState(false);

    useEffect(() {
      void onScroll() {
        final offset = scrollController.position.pixels;
        if (!compact.value && offset > _kCompactEnter) {
          compact.value = true;
        } else if (compact.value && offset < _kCompactExit) {
          compact.value = false;
        }
      }

      scrollController.addListener(onScroll);
      return () => scrollController.removeListener(onScroll);
    }, [scrollController]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Pinned context block — sits between the tab bar and the
        // scrolling feed so the next-session card stays visible no
        // matter how far the user scrolls into older messages. Shrinks
        // to a compact date/hour/confirmed-count strip once the user
        // has scrolled away from the newest message, to give the feed
        // more room.
        ActivityHero(
          lobbyId: lobbyId,
          upcoming: upcomingActivity,
          sport: sport,
          isLeader: isLeader,
          captainId: captainId,
          compact: compact.value,
        ),
        Expanded(
          // Chat-anchored: newest message at the bottom (initial view),
          // scroll up to reveal older messages. Pull-down (from the top of
          // the reversed list) refetches the feed + pinned activity.
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(lobbyFeedControllerProvider(lobbyId));
              ref.invalidate(lobbyUpcomingActivityControllerProvider(lobbyId));
              await ref.read(lobbyFeedControllerProvider(lobbyId).future);
            },
            child: ListView(
              controller: scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              reverse: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Children laid out bottom-up: index 0 sits at the bottom.
                for (final item in feed.reversed)
                  FeedItemWidget(
                    item: item,
                    lobbyId: lobbyId,
                    captainId: captainId,
                  ),
              ],
            ),
          ),
        ),
        ChatTriggerBar(
          isLeader: isLeader,
          onOpen: () => showActionPickerSheet(
            context,
            isLeader: isLeader,
            hasActivity: hasActivity,
            lobbyId: lobbyId,
            upcoming: upcomingActivity,
          ),
        ),
      ],
    );
  }
}
