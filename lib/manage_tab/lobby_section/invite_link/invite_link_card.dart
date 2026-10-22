import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../../../auth/auth_controller.dart';
import '../../../logger/talker.dart';
import '../../../ui/main.dart';
import '../lobby_detail_controller.dart';
import 'invite_link_controller.dart';

String buildInviteLinkUrl(String code) =>
    Uri.https('passe.vn', '/invite/$code').toString();

/// The text a shared invite link travels with. A bare URL in a chat app
/// reads as spam; naming the lobby, sport and inviter tells the recipient
/// what they're tapping before they tap it. Any missing piece just drops out.
String buildInviteShareText({
  required String url,
  String? inviter,
  String? lobbyName,
  String? sportName,
}) {
  final lobby = [
    if (lobbyName != null && lobbyName.isNotEmpty) lobbyName,
    if (sportName != null && sportName.isNotEmpty) '($sportName)',
  ].join(' ');
  if (lobby.isEmpty) return url;
  final key = inviter != null && inviter.isNotEmpty
      ? 'lobby.inviteLink.shareTextFrom'
      : 'lobby.inviteLink.shareText';
  return key.tr(
    namedArgs: {'inviter': inviter ?? '', 'lobby': lobby, 'url': url},
  );
}

/// Captain/coordinator-only card in the lobby info sheet: shows the lobby's
/// current invite link (or a create button if none exists yet), with
/// copy/share/regenerate/remove actions. Discord-style — anyone who opens the
/// link joins instantly, no approval step (see `redeem_lobby_invite_link`).
class InviteLinkCard extends ConsumerStatefulWidget {
  final String lobbyId;
  final bool canManage;

  const InviteLinkCard({
    super.key,
    required this.lobbyId,
    required this.canManage,
  });

  @override
  ConsumerState<InviteLinkCard> createState() => _InviteLinkCardState();
}

class _InviteLinkCardState extends ConsumerState<InviteLinkCard> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e, st) {
      talker.handle(e, st, 'invite link action failed');
      if (!mounted) return;
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleX),
        variant: .destructive,
        title: Text('lobby.inviteLink.error'.tr()),
        alignment: .bottomCenter,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copy(String code) async {
    await Clipboard.setData(ClipboardData(text: buildInviteLinkUrl(code)));
    if (!mounted) return;
    showFToast(
      context: context,
      icon: const Icon(FLucideIcons.copy),
      title: Text('lobby.inviteLink.copied'.tr()),
      alignment: .bottomCenter,
    );
  }

  Future<void> _share(String code) async {
    final lobby = ref
        .read(lobbyDetailControllerProvider(widget.lobbyId))
        .value
        ?.lobby;
    final user = ref.read(authControllerProvider).value;
    final text = buildInviteShareText(
      url: buildInviteLinkUrl(code),
      inviter: user == null || user.isGuest ? null : user.username,
      lobbyName: lobby?.name,
      sportName: lobby?.sport.getLocalizedName(context),
    );
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  /// Regenerating or removing kills the link everyone already has, so both
  /// ask first — a mis-tap here silently breaks every invite in flight.
  Future<bool> _confirm({
    required String title,
    required String body,
    required String action,
  }) async {
    final ok = await showFDialog<bool>(
      context: context,
      builder: (dialogCtx, style, animation) => PConfirmDialog(
        animation: animation,
        title: Text(title),
        body: Text(body),
        actions: [
          FButton(
            variant: .outline,
            onPress: () => Navigator.of(dialogCtx).pop(false),
            child: Text('cancel'.tr()),
          ),
          FButton(
            variant: .destructive,
            onPress: () => Navigator.of(dialogCtx).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _regenerate() async {
    final ok = await _confirm(
      title: 'lobby.inviteLink.regenerateConfirmTitle'.tr(),
      body: 'lobby.inviteLink.regenerateConfirmBody'.tr(),
      action: 'lobby.inviteLink.regenerate'.tr(),
    );
    if (!ok || !mounted) return;
    await _run(
      () => ref
          .read(inviteLinkControllerProvider(widget.lobbyId).notifier)
          .generate(),
    );
  }

  Future<void> _remove() async {
    final ok = await _confirm(
      title: 'lobby.inviteLink.removeConfirmTitle'.tr(),
      body: 'lobby.inviteLink.removeConfirmBody'.tr(),
      action: 'lobby.inviteLink.remove'.tr(),
    );
    if (!ok || !mounted) return;
    await _run(
      () => ref
          .read(inviteLinkControllerProvider(widget.lobbyId).notifier)
          .revoke(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.canManage) return const SizedBox.shrink();

    final colors = context.theme.colors;
    final linkAsync = ref.watch(inviteLinkControllerProvider(widget.lobbyId));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: linkAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Center(child: FCircularProgress()),
        ),
        error: (_, _) => Text(
          'lobby.inviteLink.error'.tr(),
          style: TextStyle(color: colors.destructive),
        ),
        data: (link) => link == null ? _buildEmpty() : _buildActive(link),
      ),
    );
  }

  Widget _buildEmpty() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        Text(
          'lobby.inviteLink.title'.tr(),
          style: context.theme.typography.body.sm.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          'lobby.inviteLink.description'.tr(),
          style: context.theme.typography.body.xs.copyWith(
            color: context.theme.colors.mutedForeground,
          ),
        ),
        FButton(
          onPress: _busy
              ? null
              : () => _run(
                  () => ref
                      .read(
                        inviteLinkControllerProvider(widget.lobbyId).notifier,
                      )
                      .generate(),
                ),
          child: _busy
              ? const FCircularProgress()
              : Text('lobby.inviteLink.create'.tr()),
        ),
      ],
    );
  }

  Widget _buildActive(LobbyInviteLink link) {
    final colors = context.theme.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 10,
      children: [
        Row(
          children: [
            Text(
              'lobby.inviteLink.title'.tr(),
              style: context.theme.typography.body.sm.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                link.code,
                overflow: TextOverflow.ellipsis,
                style: context.theme.typography.body.sm.copyWith(
                  color: colors.secondaryForeground,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
        Row(
          spacing: 8,
          children: [
            Expanded(
              child: FButton(
                variant: .outline,
                onPress: _busy ? null : () => _copy(link.code),
                child: Text('lobby.inviteLink.copy'.tr()),
              ),
            ),
            Expanded(
              child: FButton(
                variant: .outline,
                onPress: _busy ? null : () => _share(link.code),
                child: Text('lobby.inviteLink.share'.tr()),
              ),
            ),
          ],
        ),
        Row(
          spacing: 8,
          children: [
            Expanded(
              child: FButton(
                variant: .ghost,
                onPress: _busy ? null : _regenerate,
                child: _busy
                    ? const FCircularProgress()
                    : Text('lobby.inviteLink.regenerate'.tr()),
              ),
            ),
            Expanded(
              child: FButton(
                variant: .ghost,
                onPress: _busy ? null : _remove,
                child: Text(
                  'lobby.inviteLink.remove'.tr(),
                  style: TextStyle(color: colors.destructive),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
