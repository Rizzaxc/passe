// Feed tab — chat-style action feed + fixed trigger bar. Split out from
// the old combined activity tab; activity scheduling/management now lives
// in the Planner tab (planner_tab.dart).
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../members/controller.dart';
import 'feed.dart';
import 'feed_controller.dart';
import 'getting_started_card.dart';
import 'trigger_bar.dart';
import 'upcoming_controller.dart';

class LobbyFeedTab extends HookConsumerWidget {
  final String lobbyId;
  final bool isLeader;
  final String? captainId;

  const LobbyFeedTab({
    super.key,
    required this.lobbyId,
    required this.isLeader,
    this.captainId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(lobbyFeedControllerProvider(lobbyId));
    // Only the first load: a refresh keeps the previous value on screen.
    final feedLoading = !feedAsync.hasValue && !feedAsync.hasError;
    final feed = generalFeedItems(feedAsync.value ?? const <FeedItem>[]);

    final scrollController = useScrollController();

    // Land on the newest message like a chat, but lay items out in normal
    // (oldest → newest, top → bottom) reading order instead of a
    // `reverse: true` list. A reversed list anchors its content to the
    // *bottom* of the viewport, so a short feed leaves a large empty gap
    // at the *top* — jarring now that this tab has no hero above it to
    // fill that space. Top-down order means any leftover space trails
    // harmlessly below the last message, next to the trigger bar.
    useEffect(() {
      if (feed.isEmpty) return null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!scrollController.hasClients) return;
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      });
      return null;
    }, [feed.length]);

    final hasScheduledBefore = feed.any(
      (i) => i is UpdateItem && i.kind == UpdateKind.scheduled,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Pinned above the list, not inside it: the list jumps to the newest
        // message on load, which scrolled an in-list card (and its dismiss
        // button) out of sight in any lobby with a few items already.
        // Its checklist reads the feed (`hasScheduledBefore`), so hold it back
        // until the feed is known rather than flashing an all-undone state.
        if (isLeader && !feedLoading)
          LobbyGettingStartedCard(
            lobbyId: lobbyId,
            hasScheduledBefore: hasScheduledBefore,
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(lobbyFeedControllerProvider(lobbyId));
              if (isLeader) {
                // The checklist ticks off real data — refresh it too.
                ref.invalidate(lobbyMembersControllerProvider(lobbyId));
                ref.invalidate(
                  lobbyUpcomingActivitiesControllerProvider(lobbyId),
                );
              }
              await ref.read(lobbyFeedControllerProvider(lobbyId).future);
            },
            child: feedLoading
                ? const Center(child: FCircularProgress())
                : ListView(
                    controller: scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      for (final item in feed)
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
            lobbyId: lobbyId,
          ),
        ),
      ],
    );
  }
}
