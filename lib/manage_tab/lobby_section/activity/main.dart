// Activity tab — single scroll view (hero + feed) + fixed chat trigger bar
import 'package:flutter/material.dart';

import '../../../../core/model/enum.dart';
import 'feed.dart';
import 'hero.dart';
import 'trigger_bar.dart';

class ActivityTab extends StatefulWidget {
  final String lobbyId;
  final bool isLeader;
  final Sport? sport;
  final bool hasActivity;
  final String myRsvp;
  final ValueChanged<String> onRsvpChanged;

  const ActivityTab({
    super.key,
    required this.lobbyId,
    required this.isLeader,
    required this.sport,
    required this.hasActivity,
    required this.myRsvp,
    required this.onRsvpChanged,
  });

  @override
  State<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<ActivityTab> {
  bool _pickerOpen = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              // Chat-anchored: newest message at the bottom (initial view),
              // scroll up to reveal older messages and finally the hero.
              child: ListView(
                reverse: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // Children laid out bottom-up: index 0 sits at the bottom.
                  for (final item in kMockFeed.reversed)
                    FeedItemWidget(item: item),
                  ActivityHero(
                    sport: widget.sport,
                    hasActivity: widget.hasActivity,
                    isLeader: widget.isLeader,
                    myRsvp: widget.myRsvp,
                    onRsvpChanged: widget.onRsvpChanged,
                  ),
                ],
              ),
            ),
            ChatTriggerBar(
              isLeader: widget.isLeader,
              onOpen: () => setState(() => _pickerOpen = true),
            ),
          ],
        ),
        if (_pickerOpen)
          Positioned.fill(
            child: ActionPickerOverlay(
              isLeader: widget.isLeader,
              hasActivity: widget.hasActivity,
              onClose: () => setState(() => _pickerOpen = false),
            ),
          ),
      ],
    );
  }
}
