import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../core/model/lobby.dart';
import '../../notifications/notification_service.dart';
import '../../router.dart';
import '../../ui/main.dart';
import 'lobby_invite_response_controller.dart';

/// `/lobby-invite/:recordId` — reached from a `lobby_invite` notification tap
/// (bell/notification-center, or an OS push/cold start, which can't cheaply
/// pre-check status the way the in-app notification list can). Shows a
/// preview of the lobby and lets the user accept/reject right here — this is
/// now the only accept surface; the old Manage▸Lobby mail-icon sheet is
/// retired.
///
/// Deliberately not coupled to "reached from a notification": reject doesn't
/// route anywhere (same "nothing happens" behavior as the notification
/// card's own inline reject), so this page stays reusable if something else
/// links here later.
class LobbyInvitePreviewPage extends ConsumerStatefulWidget {
  final String recordId;

  const LobbyInvitePreviewPage({super.key, required this.recordId});

  @override
  ConsumerState<LobbyInvitePreviewPage> createState() =>
      _LobbyInvitePreviewPageState();
}

class _LobbyInvitePreviewPageState
    extends ConsumerState<LobbyInvitePreviewPage> {
  bool _accepting = false;
  bool _rejecting = false;

  bool get _busy => _accepting || _rejecting;

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      const DiscoverRoute().go(context);
    }
  }

  void _showError() {
    if (!mounted) return;
    showFToast(
      context: context,
      icon: const Icon(FLucideIcons.circleX),
      variant: .destructive,
      title: Text('lobby.inviteReview.error'.tr()),
      alignment: .bottomCenter,
    );
  }

  Future<void> _accept(LobbyInvitePreview preview) async {
    setState(() => _accepting = true);
    try {
      await ref
          .read(lobbyInviteResponseControllerProvider.notifier)
          .respond(widget.recordId, accept: true);
      if (!mounted) return;
      await ref
          .read(notificationServiceProvider)
          .maybePromptAndRegister(context, ref);
      if (!mounted) return;
      LobbyDetailRoute(
        id: preview.lobbyId!,
        $extra: preview.lobbyName,
      ).go(context);
    } catch (e, st) {
      Talker().handle(e, st, 'lobby invite accept failed');
      _showError();
      if (mounted) setState(() => _accepting = false);
    }
  }

  Future<void> _reject() async {
    setState(() => _rejecting = true);
    try {
      await ref
          .read(lobbyInviteResponseControllerProvider.notifier)
          .respond(widget.recordId, accept: false);
      // No navigation — respond() invalidates lobbyInvitePreviewProvider, so
      // this page just rebuilds straight into its own declined state below.
    } catch (e, st) {
      Talker().handle(e, st, 'lobby invite reject failed');
      _showError();
    } finally {
      if (mounted) setState(() => _rejecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewAsync = ref.watch(
      lobbyInvitePreviewProvider(widget.recordId),
    );

    // Already resolved to accepted elsewhere (e.g. the notification card's
    // own inline Accept) by the time this loads, or resolves to accepted
    // while this page is open — skip straight to the lobby, no button flash.
    ref.listen<AsyncValue<LobbyInvitePreview>>(
      lobbyInvitePreviewProvider(widget.recordId),
      (previous, next) {
        final preview = next.value;
        if (preview != null &&
            preview.valid &&
            preview.status == 'accepted' &&
            preview.lobbyId != null) {
          LobbyDetailRoute(
            id: preview.lobbyId!,
            $extra: preview.lobbyName,
          ).go(context);
        }
      },
    );

    return FScaffold(
      header: FHeader.nested(
        title: Text('lobby.inviteReview.title'.tr()),
        prefixes: [FHeaderAction.back(onPress: () => _back(context))],
      ),
      child: previewAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _MessageState(text: 'lobby.inviteReview.error'.tr()),
        data: (preview) {
          if (!preview.valid) {
            return _MessageState(text: 'lobby.inviteReview.notFound'.tr());
          }
          switch (preview.status) {
            case 'declined':
              return _MessageState(
                text: 'lobby.inviteReview.declinedTitle'.tr(),
              );
            case 'accepted':
              // Handled by the ref.listen effect above — this is the brief
              // frame before it forwards.
              return const Center(child: CircularProgressIndicator());
            default:
              return _PendingState(
                preview: preview,
                accepting: _accepting,
                rejecting: _rejecting,
                busy: _busy,
                onAccept: () => _accept(preview),
                onReject: _reject,
              );
          }
        },
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final String text;

  const _MessageState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: PEmptySectionPlaceholder(subtitle: text),
      ),
    );
  }
}

class _PendingState extends StatelessWidget {
  final LobbyInvitePreview preview;
  final bool accepting;
  final bool rejecting;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _PendingState({
    required this.preview,
    required this.accepting,
    required this.rejecting,
    required this.busy,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final showDiscoverable = preview.visibility != LobbyVisibility.private;
    final showPublic = preview.visibility == LobbyVisibility.public;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 14,
              children: [
                // Every lobby shows this much, regardless of visibility.
                Row(
                  spacing: 12,
                  children: [
                    LobbyAvatar(
                      lobbyId: preview.lobbyId,
                      name: preview.lobbyName ?? '',
                      hasAvatar: preview.hasAvatar,
                      size: 52,
                      borderRadius: BorderRadius.circular(12),
                      backgroundColor: colors.secondary,
                      foregroundColor: colors.secondaryForeground,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 2,
                        children: [
                          Text(
                            preview.lobbyName ?? '',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style: context.theme.typography.body.lg.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'lobby.inviteReview.invitedBy'.tr(
                              namedArgs: {
                                'name': preview.inviterUsername ?? '',
                              },
                            ),
                            overflow: TextOverflow.ellipsis,
                            style: context.theme.typography.body.sm.copyWith(
                              color: colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (showDiscoverable) ...[
                  Divider(height: 1, color: colors.border),
                  _DiscoverableInfo(preview: preview),
                ],
                if (showPublic) ...[
                  Divider(height: 1, color: colors.border),
                  _PublicInfo(preview: preview),
                ],
              ],
            ),
          ),
          Row(
            spacing: 12,
            children: [
              Expanded(
                child: FButton(
                  variant: .outline,
                  onPress: busy ? null : onReject,
                  child: rejecting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('lobby.inviteReview.reject'.tr()),
                ),
              ),
              Expanded(
                child: FButton(
                  onPress: busy ? null : onAccept,
                  child: accepting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('lobby.inviteReview.accept'.tr()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// `discoverable`+: member count, captain, this viewer's relationship to the
/// captain, and FitScore vs. the lobby.
class _DiscoverableInfo extends StatelessWidget {
  final LobbyInvitePreview preview;

  const _DiscoverableInfo({required this.preview});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final rowStyle = context.theme.typography.body.sm.copyWith(
      color: colors.mutedForeground,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        _InfoRow(
          icon: FLucideIcons.users,
          text: 'lobby.inviteReview.memberCount'.tr(
            namedArgs: {'count': '${preview.memberCount ?? 0}'},
          ),
          style: rowStyle,
        ),
        if (preview.captainUsername != null)
          _InfoRow(
            icon: FLucideIcons.crown,
            text: 'lobby.inviteReview.captainedBy'.tr(
              namedArgs: {'name': preview.captainUsername!},
            ),
            style: rowStyle,
          ),
        if (preview.relationship != null)
          _InfoRow(
            icon: FLucideIcons.heartHandshake,
            text: 'lobby.inviteReview.relationship.${preview.relationship}'
                .tr(),
            style: rowStyle,
          ),
        if (preview.fitscore != null)
          _InfoRow(
            icon: FLucideIcons.sparkles,
            text: 'lobby.inviteReview.fitscore'.tr(
              namedArgs: {'score': preview.fitscore!.toStringAsFixed(1)},
            ),
            style: rowStyle,
          ),
      ],
    );
  }
}

/// `public` only: home ground, playtime, MMR, and the full roster.
class _PublicInfo extends StatelessWidget {
  final LobbyInvitePreview preview;

  const _PublicInfo({required this.preview});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final rowStyle = context.theme.typography.body.sm.copyWith(
      color: colors.mutedForeground,
    );
    final playtime = preview.playtime ?? const [];
    final members = preview.members ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        if (preview.homeGroundName != null)
          _InfoRow(
            icon: FLucideIcons.mapPin,
            text: 'lobby.inviteReview.homeGround'.tr(
              namedArgs: {'name': preview.homeGroundName!},
            ),
            style: rowStyle,
          ),
        if (playtime.isNotEmpty)
          _InfoRow(
            icon: FLucideIcons.clock,
            text: playtime
                .map(
                  (t) =>
                      '${t.dayOfWeek.getFullName(context)} · ${t.dayChunk.getFullName(context)}',
                )
                .join(', '),
            style: rowStyle,
          ),
        if (preview.mmr != null)
          _InfoRow(
            icon: FLucideIcons.trophy,
            text: 'lobby.inviteReview.mmr'.tr(
                  namedArgs: {'value': '${preview.mmr}'},
                ) +
                (preview.isMmrCalibrated
                    ? ''
                    : ' · ${'homeTab.challenger.provisional'.tr()}'),
            style: rowStyle,
          ),
        if (members.isNotEmpty) ...[
          Text(
            'lobby.inviteReview.membersTitle'.tr(),
            style: context.theme.typography.body.sm.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: members
                .map(
                  (m) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: colors.muted,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${m.username}#${m.tagNumber}',
                      style: context.theme.typography.body.xs,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final TextStyle style;

  const _InfoRow({required this.icon, required this.text, required this.style});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Icon(icon, size: 14, color: style.color),
        Expanded(child: Text(text, style: style)),
      ],
    );
  }
}
