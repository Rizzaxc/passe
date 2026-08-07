import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../../auth/guest_prompt.dart';
import '../../../core/model/enum.dart';
import '../../../router.dart';
import '../../../ui/main.dart';
import 'invite_landing_controller.dart';

/// `/invite/:code` — lands here from a verified
/// `https://passe.vn/invite/CODE` link or a direct push. Shows a preview of
/// the lobby, then redeems the code on tap — instant auto-join, no approval
/// step (see `redeem_lobby_invite_link`). Guests are routed through the
/// existing sign-in prompt (`ensureSignedIn`); the router's own
/// `pendingDestination` bookkeeping already bounces them back here once
/// signed in, so no extra hand-off state is needed.
class InviteLandingPage extends ConsumerStatefulWidget {
  final String code;

  const InviteLandingPage({super.key, required this.code});

  @override
  ConsumerState<InviteLandingPage> createState() => _InviteLandingPageState();
}

class _InviteLandingPageState extends ConsumerState<InviteLandingPage> {
  bool _joining = false;

  Future<void> _join() async {
    if (!ensureSignedIn(context, ref)) return;

    setState(() => _joining = true);
    try {
      final result = await redeemInviteLink(widget.code);
      final status = result['status'] as String?;
      if (!mounted) return;

      if (status == 'joined' || status == 'already_member') {
        final lobbyId = result['lobby_id'] as String?;
        final lobbyName = result['lobby_name'] as String?;
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.partyPopper),
          title: Text(
            status == 'joined'
                ? 'lobby.inviteLink.joined'.tr(
                    namedArgs: {'name': lobbyName ?? ''},
                  )
                : 'lobby.inviteLink.alreadyMember'.tr(),
          ),
          alignment: .bottomCenter,
        );
        if (lobbyId != null) {
          LobbyDetailRoute(id: lobbyId, $extra: lobbyName).go(context);
        }
        return;
      }

      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleAlert),
        variant: .destructive,
        title: Text('lobby.inviteLink.invalid'.tr()),
        alignment: .bottomCenter,
      );
    } catch (e, st) {
      Talker().handle(e, st, 'invite redeem failed');
      if (!mounted) return;
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleX),
        variant: .destructive,
        title: Text('lobby.inviteLink.error'.tr()),
        alignment: .bottomCenter,
      );
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      const HomeRoute().go(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewAsync = ref.watch(inviteLinkPreviewProvider(widget.code));

    return FScaffold(
      header: FHeader.nested(
        title: Text('lobby.inviteLink.landingTitle'.tr()),
        prefixes: [FHeaderAction.back(onPress: () => _back(context))],
      ),
      child: previewAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _ErrorState(message: 'lobby.inviteLink.notFound'.tr()),
        data: (preview) {
          if (!preview.valid) {
            final message = switch (preview.reason) {
              'expired' => 'lobby.inviteLink.expired'.tr(),
              'revoked' => 'lobby.inviteLink.revoked'.tr(),
              _ => 'lobby.inviteLink.notFound'.tr(),
            };
            return _ErrorState(message: message);
          }
          return _PreviewState(
            preview: preview,
            joining: _joining,
            onJoin: _join,
          );
        },
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: PEmptySectionPlaceholder(subtitle: message),
      ),
    );
  }
}

class _PreviewState extends StatelessWidget {
  final InvitePreview preview;
  final bool joining;
  final VoidCallback onJoin;

  const _PreviewState({
    required this.preview,
    required this.joining,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final sport =
        preview.sportId != null && preview.sportId! < Sport.values.length
        ? Sport.values[preview.sportId!]
        : null;

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
              spacing: 8,
              children: [
                Text(
                  'lobby.inviteLink.invitedTo'.tr(),
                  style: context.theme.typography.body.sm.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
                Text(
                  preview.lobbyName ?? '',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: context.theme.typography.body.lg.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Row(
                  spacing: 8,
                  children: [
                    if (sport != null) ...[
                      sport.getIcon(size: 14),
                      Flexible(
                        child: Text(
                          sport.getLocalizedName(context),
                          overflow: TextOverflow.ellipsis,
                          style: context.theme.typography.body.sm.copyWith(
                            color: colors.mutedForeground,
                          ),
                        ),
                      ),
                      Text(
                        '·',
                        style: TextStyle(
                          color: colors.mutedForeground.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                    Flexible(
                      child: Text(
                        'lobby.inviteLink.memberCount'.tr(
                          namedArgs: {'count': '${preview.memberCount ?? 0}'},
                        ),
                        overflow: TextOverflow.ellipsis,
                        style: context.theme.typography.body.sm.copyWith(
                          color: colors.mutedForeground,
                        ),
                      ),
                    ),
                  ],
                ),
                if (preview.captainUsername != null)
                  Text(
                    'lobby.inviteLink.captainedBy'.tr(
                      namedArgs: {'name': preview.captainUsername!},
                    ),
                    overflow: TextOverflow.ellipsis,
                    style: context.theme.typography.body.xs.copyWith(
                      color: colors.mutedForeground,
                    ),
                  ),
              ],
            ),
          ),
          FButton(
            onPress: joining ? null : onJoin,
            child: joining
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text('lobby.inviteLink.join'.tr()),
          ),
        ],
      ),
    );
  }
}
