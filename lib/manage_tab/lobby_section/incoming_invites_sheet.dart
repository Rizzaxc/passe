import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../notifications/notification_service.dart';
import '../../ui/sheet.dart';
import 'incoming_invites_controller.dart';

void showIncomingInvitesSheet(BuildContext context) {
  showPSheet(
    context: context,
    builder: (_) => const _IncomingInvitesSheet(),
  );
}

class _IncomingInvitesSheet extends ConsumerWidget {
  const _IncomingInvitesSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitesAsync = ref.watch(incomingInvitesControllerProvider);
    final colors = context.theme.colors;

    return SingleChildScrollView(
      primary: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          PSheetTitle(
            label: 'lobby.invites.title'.tr(),
            trailing: FButton.icon(
              variant: .ghost,
              onPress: () => Navigator.of(context).pop(),
              child: const Icon(FLucideIcons.x),
            ),
          ),
          invitesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('errorGeneric'.tr(),
                  style: TextStyle(color: colors.destructive)),
            ),
            data: (invites) => invites.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'lobby.invites.empty'.tr(),
                        style: context.theme.typography.body.sm
                            .copyWith(color: colors.mutedForeground),
                      ),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < invites.length; i++) ...[
                          _InviteRow(invite: invites[i]),
                          if (i < invites.length - 1)
                            Divider(
                              height: 1,
                              indent: 60,
                              color: colors.border.withValues(alpha: 0.5),
                            ),
                        ],
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _InviteRow extends ConsumerStatefulWidget {
  final IncomingInvite invite;

  const _InviteRow({required this.invite});

  @override
  ConsumerState<_InviteRow> createState() => _InviteRowState();
}

class _InviteRowState extends ConsumerState<_InviteRow> {
  bool _loading = false;

  Future<void> _act(Future<void> Function() action, {String? successMsg}) async {
    setState(() => _loading = true);
    try {
      await action();
      if (!mounted) return;
      if (successMsg != null) {
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.check),
          title: Text(successMsg),
          alignment: .bottomCenter,
        );
      }
    } catch (e, st) {
      Talker().handle(e, st, 'invite action failed');
      if (!mounted) return;
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleX),
        variant: .destructive,
        title: Text('errorGeneric'.tr()),
        alignment: .bottomCenter,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final invite = widget.invite;

    final title = invite.lobbyName ?? invite.inviterUsername;
    final subtitle = 'lobby.invites.invitedBy'
        .tr(namedArgs: {'name': invite.inviterUsername});

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.secondary,
            ),
            alignment: Alignment.center,
            child: invite.sport?.getIcon(size: 18) ??
                Icon(FLucideIcons.users, size: 16, color: colors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.theme.typography.body.sm.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.foreground,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: context.theme.typography.body.xs
                      .copyWith(color: colors.mutedForeground),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (_loading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else ...[
            FButton.icon(
              variant: .ghost,
              onPress: () => _act(() => ref
                  .read(incomingInvitesControllerProvider.notifier)
                  .decline(invite.id)),
              child:
                  Icon(FLucideIcons.x, size: 16, color: colors.mutedForeground),
            ),
            const SizedBox(width: 4),
            FButton.icon(
              variant: .secondary,
              onPress: () => _act(
                () async {
                  await ref
                      .read(incomingInvitesControllerProvider.notifier)
                      .accept(invite.id);
                  // Joining a lobby is a strong first action → soft-ask for
                  // push permission (no-op if already decided).
                  if (context.mounted) {
                    await ref
                        .read(notificationServiceProvider)
                        .maybePromptAndRegister(context, ref);
                  }
                },
                successMsg: 'lobby.invites.accepted'.tr(),
              ),
              child: const Icon(FLucideIcons.check, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}
