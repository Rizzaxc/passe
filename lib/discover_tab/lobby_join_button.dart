import 'package:easy_localization/easy_localization.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../auth/guest_prompt.dart';
import '../logger/talker.dart';
import '../notifications/notification_service.dart';
import 'teammate_section/feed_controller.dart';

/// "Xin vào" for a lobby you're not in — on the Teammates card and pinned to
/// the bottom of the lobby preview sheet. Both read the same
/// [joinRequestStateProvider] override, so requesting in one place flips the
/// other. Once sent it becomes "Đã gửi" + an undo.
class LobbyJoinButton extends ConsumerWidget {
  final String lobbyId;
  final bool alreadyRequested;

  /// Full-width (sheet footer) instead of the card's compact size.
  final bool expand;

  const LobbyJoinButton({
    super.key,
    required this.lobbyId,
    required this.alreadyRequested,
    this.expand = false,
  });

  void _onError(BuildContext context, Object e, StackTrace st, String log) {
    talker.handle(e, st, log);
    showFToast(
      context: context,
      icon: const Icon(FLucideIcons.circleX),
      variant: .destructive,
      title: Text('error'.tr()),
      description: Text('errorGeneric'.tr()),
      alignment: .bottomCenter,
    );
  }

  Future<void> _request(BuildContext context, WidgetRef ref) async {
    // Guests can't send a join request (RLS/NOT NULL) — prompt sign-in
    // instead of letting the tap fail silently.
    if (!ensureSignedIn(context, ref)) return;
    try {
      await ref.read(joinRequestStateProvider.notifier).request(lobbyId);
      if (!context.mounted) return;
      // Say what happens next — the request goes to a captain, not straight
      // into the lobby, and the answer arrives as a notification.
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.send),
        title: Text('homeTab.teammate.sentToast'.tr()),
        description: Text('homeTab.teammate.sentToastBody'.tr()),
        alignment: .bottomCenter,
      );
      await ref
          .read(notificationServiceProvider)
          .maybePromptAndRegister(
            context,
            ref,
            reason: 'notification.permission.joinReason'.tr(),
          );
    } catch (e, st) {
      if (context.mounted) _onError(context, e, st, 'Lobby join request failed');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requested = ref.watch(
      joinRequestStateProvider.select((m) => m[lobbyId] ?? alreadyRequested),
    );

    if (requested) {
      final undo = FButton(
        size: .sm,
        variant: .outline,
        prefix: const Icon(FLucideIcons.undo2),
        onPress: () async {
          try {
            await ref.read(joinRequestStateProvider.notifier).unrequest(lobbyId);
          } catch (e, st) {
            if (context.mounted) {
              _onError(context, e, st, 'Lobby join cancel failed');
            }
          }
        },
        child: Text('homeTab.teammate.undo'.tr()),
      );
      final sent = Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          Icon(
            FLucideIcons.circleCheck,
            size: 16,
            color: context.theme.colors.mutedForeground,
          ),
          Text(
            'homeTab.teammate.sent'.tr(),
            style: context.theme.typography.body.sm.copyWith(
              color: context.theme.colors.mutedForeground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
      return Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: expand
            ? MainAxisAlignment.spaceBetween
            : MainAxisAlignment.end,
        spacing: 8,
        children: [sent, undo],
      );
    }

    final button = FButton(
      size: expand ? .md : .sm,
      onPress: () => _request(context, ref),
      child: Text(
        'homeTab.teammate.join'.tr(),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
