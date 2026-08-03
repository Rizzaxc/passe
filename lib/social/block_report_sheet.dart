import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../ui/main.dart';
import 'friendship_controller.dart';
import 'user_page_controller.dart';

/// Destructive actions on another person: unfriend and block.
///
/// Blocking is symmetric in effect — `block_user` severs any live friendship in
/// the same call and `fn_is_blocked` then hides each party from the other
/// everywhere the visibility predicate is used.
void showUserActionsSheet(
  BuildContext context, {
  required UserProfile profile,
}) {
  showPSheet(
    context: context,
    builder: (_) => _UserActionsSheet(profile: profile),
  );
}

class _UserActionsSheet extends ConsumerStatefulWidget {
  final UserProfile profile;
  const _UserActionsSheet({required this.profile});

  @override
  ConsumerState<_UserActionsSheet> createState() => _UserActionsSheetState();
}

class _UserActionsSheetState extends ConsumerState<_UserActionsSheet> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, String successKey) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(userProfileProvider(widget.profile.userId));
      if (!mounted) return;
      Navigator.of(context).pop();
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.check),
        title: Text(successKey.tr()),
        alignment: .bottomCenter,
      );
    } catch (e, st) {
      Talker().handle(e, st, 'User action failed');
      if (!mounted) return;
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleX),
        variant: .destructive,
        title: Text('social.actionFailed'.tr()),
        alignment: .bottomCenter,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(friendshipControllerProvider.notifier);
    final profile = widget.profile;

    return SingleChildScrollView(
      primary: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          PSheetTitle(
            label: profile.handle,
            trailing: FButton.icon(
              variant: .ghost,
              onPress: () => Navigator.of(context).pop(),
              child: const Icon(FLucideIcons.x),
            ),
          ),
          if (profile.friendState == FriendState.friend)
            FButton(
              variant: .outline,
              onPress: _busy
                  ? null
                  : () => _run(
                        () => notifier.unfriend(profile.userId),
                        'social.unfriended',
                      ),
              prefix: const Icon(FLucideIcons.userMinus),
              child: Text('social.unfriend'.tr()),
            ),
          if (profile.friendState == FriendState.blocked)
            FButton(
              variant: .outline,
              onPress: _busy
                  ? null
                  : () => _run(
                        () => notifier.unblock(profile.userId),
                        'social.unblocked',
                      ),
              prefix: const Icon(FLucideIcons.userCheck),
              child: Text('social.unblock'.tr()),
            )
          else
            FButton(
              variant: .destructive,
              onPress: _busy
                  ? null
                  : () => _run(
                        () => notifier.block(profile.userId),
                        'social.blocked',
                      ),
              prefix: const Icon(FLucideIcons.ban),
              child: Text('social.block'.tr()),
            ),
          Text(
            'social.blockExplainer'.tr(),
            style: context.theme.typography.body.xs.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
