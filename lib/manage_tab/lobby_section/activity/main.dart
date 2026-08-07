// Feed tab — chat-style action feed + fixed trigger bar. Split out from
// the old combined activity tab; activity scheduling/management now lives
// in the Planner tab (planner_tab.dart).
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'feed.dart';
import 'feed_controller.dart';
import 'trigger_bar.dart';

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
    final feed = generalFeedItems(
      ref.watch(lobbyFeedControllerProvider(lobbyId)).value ??
          const <FeedItem>[],
    );

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(lobbyFeedControllerProvider(lobbyId));
              await ref.read(lobbyFeedControllerProvider(lobbyId).future);
            },
            child: ListView(
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
