import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../../ui/theme.dart';

class LobbyCardActivitySlot extends StatelessWidget {
  final DateTime? nextActivity;
  final bool isLeader;

  const LobbyCardActivitySlot({
    super.key,
    required this.nextActivity,
    required this.isLeader,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    if (nextActivity != null) {
      // State 3: confirmed upcoming activity
      final formatted = DateFormat('EEE, d MMM · HH:mm').format(nextActivity!);
      return FButton(
        suffix: Icon(FIcons.check, size: 16, color: colors.primary),
        variant: .secondary,
        size: .xs,
        onPress: () {},
        child: Text(formatted),
      );
    }

    if (isLeader) {
      // State 1: leader, no activity — prompt to schedule
      return FButton(
        suffix: const Icon(FIcons.calendarPlus, size: 16),
        variant: .primary,
        size: .xs,
        onPress: () => showFToast(context: context, title: Text('TODO')),
        // TODO: open schedule form
        child: Text('lobby.scheduleActivity'.tr()),
      );
    }

    // State 2: member, no activity — waiting
    return FButton(
      suffix: Icon(FIcons.ellipsis, size: 16, color: colors.primary),
      variant: .secondary,
      size: .xs,
      onPress: null,
      child: Text(
        'lobby.lookingForActivity'.tr(),
        style: context.theme.typography.xs,
      ),
    );
  }
}
