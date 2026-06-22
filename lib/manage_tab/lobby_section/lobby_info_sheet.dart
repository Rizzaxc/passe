import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../auth/auth_controller.dart';
import '../../core/model/lobby.dart';
import '../../ui/sheet.dart';
import 'feed/lobby_controller.dart';
import 'feed/lobby_form_sheet.dart';
import 'join_requests_controller.dart';
import 'join_requests_sheet.dart';
import 'lobby_detail_controller.dart';
import 'members/controller.dart';

const _crimson = Color(0xFFDC143C);
const _crimsonTint = Color(0xFFFFEBED);

void showLobbyInfoSheet(
  BuildContext context,
  LobbyDetailInfo info,
  String lobbyId,
) {
  showPSheet(
    context: context,
    maxHeightRatio: 1.0,
    builder: (_) => _LobbyInfoSheet(info: info, lobbyId: lobbyId),
  );
}

class _LobbyInfoSheet extends ConsumerStatefulWidget {
  final LobbyDetailInfo info;
  final String lobbyId;

  const _LobbyInfoSheet({required this.info, required this.lobbyId});

  @override
  ConsumerState<_LobbyInfoSheet> createState() => _LobbyInfoSheetState();
}

class _LobbyInfoSheetState extends ConsumerState<_LobbyInfoSheet> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _confirmLeave() {
    showFDialog(
      context: context,
      builder: (dialogCtx, style, animation) => FDialog(
        animation: animation,
        title: Text('lobby.leave.title'.tr()),
        body: Text('lobby.leave.message'.tr()),
        direction: Axis.horizontal,
        actions: [
          FButton(
            variant: .outline,
            onPress: () => Navigator.of(dialogCtx).pop(),
            child: Text('lobby.leave.cancel'.tr()),
          ),
          FButton(
            variant: .destructive,
            onPress: () {
              Navigator.of(dialogCtx).pop();
              _doLeave();
            },
            child: Text('lobby.leave.confirm'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _doLeave() async {
    final router = GoRouter.of(context);
    final sheetNav = Navigator.of(context);
    try {
      await ref
          .read(userLobbiesControllerProvider.notifier)
          .leave(widget.lobbyId);
      sheetNav.pop(); // close the info sheet
      router.pop();   // exit the detail page → back to the lobby list
    } catch (e, st) {
      Talker().handle(e, st, 'Leaving lobby failed');
      if (!mounted) return;
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleX),
        variant: .destructive,
        title: Text('error'.tr()),
        description: Text('errorGeneric'.tr()),
        alignment: .bottomCenter,
      );
    }
  }

  void _confirmDelete() {
    showFDialog(
      context: context,
      builder: (dialogCtx, style, animation) => FDialog(
        animation: animation,
        title: Text('lobby.delete.title'.tr()),
        body: Text('lobby.delete.message'.tr()),
        direction: Axis.horizontal,
        actions: [
          FButton(
            variant: .outline,
            onPress: () => Navigator.of(dialogCtx).pop(),
            child: Text('lobby.leave.cancel'.tr()),
          ),
          FButton(
            variant: .destructive,
            onPress: () {
              Navigator.of(dialogCtx).pop();
              _runAndExit(
                () => ref
                    .read(userLobbiesControllerProvider.notifier)
                    .delete(widget.lobbyId),
                'Delete lobby failed',
                'lobby.delete.failed'.tr(),
              );
            },
            child: Text('lobby.delete.confirm'.tr()),
          ),
        ],
      ),
    );
  }

  /// Runs an action that closes the sheet AND leaves the detail page on success.
  Future<void> _runAndExit(
    Future<void> Function() action,
    String logMsg,
    String errorMsg,
  ) async {
    final router = GoRouter.of(context);
    final sheetNav = Navigator.of(context);
    try {
      await action();
      sheetNav.pop();
      router.pop();
    } catch (e, st) {
      Talker().handle(e, st, logMsg);
      if (!mounted) return;
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleX),
        variant: .destructive,
        title: Text('error'.tr()),
        description: Text(errorMsg),
        alignment: .bottomCenter,
      );
    }
  }

  void _transferCaptaincy() {
    final members =
        ref.read(lobbyMembersControllerProvider(widget.lobbyId)).value ??
            const [];
    final me = ref.read(authControllerProvider).value?.id;
    final others = members.where((m) => m.userId != me).toList();
    if (others.isEmpty) {
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.info),
        title: Text('lobby.captainTransfer.noOthers'.tr()),
        alignment: .bottomCenter,
      );
      return;
    }
    showFDialog(
      context: context,
      builder: (dialogCtx, style, animation) => FDialog(
        animation: animation,
        title: Text('lobby.captainTransfer.title'.tr()),
        body: Text('lobby.captainTransfer.message'.tr()),
        direction: Axis.vertical,
        actions: [
          for (final m in others)
            FButton(
              variant: .outline,
              onPress: () {
                Navigator.of(dialogCtx).pop();
                _doTransfer(m);
              },
              child: Text('${m.username} #${m.tagNumber}'),
            ),
          FButton(
            variant: .ghost,
            onPress: () => Navigator.of(dialogCtx).pop(),
            child: Text('lobby.leave.cancel'.tr()),
          ),
        ],
      ),
    );
  }

  String? _pendingBadge(WidgetRef ref, String lobbyId) {
    final count = ref
        .watch(joinRequestsControllerProvider(lobbyId))
        .value
        ?.length;
    if (count == null || count == 0) return null;
    return 'lobby.pendingRequests'.tr(namedArgs: {'count': count.toString()});
  }

  Future<void> _editLobby(BuildContext context, Lobby lobby) async {
    final updated = await showLobbyFormSheet(
      context: context,
      ref: ref,
      lobbyId: widget.lobbyId,
      existingLobby: lobby,
    );
    if (updated != null && mounted) {
      ref.invalidate(lobbyDetailControllerProvider(widget.lobbyId));
    }
  }

  void _showInviteUserSheet(BuildContext context, String lobbyId) {
    showPSheet(
      context: context,
      builder: (_) => _InviteUserSheet(lobbyId: lobbyId),
    );
  }

  Future<void> _doTransfer(LobbyMemberInfo member) async {
    try {
      await ref
          .read(userLobbiesControllerProvider.notifier)
          .transferCaptaincy(widget.lobbyId, member.userId);
      ref.invalidate(lobbyDetailControllerProvider(widget.lobbyId));
      ref.invalidate(lobbyMembersControllerProvider(widget.lobbyId));
      if (!mounted) return;
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.check),
        title: Text('lobby.captainTransfer.success'.tr(namedArgs: {'username': member.username})),
        alignment: .bottomCenter,
      );
    } catch (e, st) {
      Talker().handle(e, st, 'Transfer captaincy failed');
      if (!mounted) return;
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleX),
        variant: .destructive,
        title: Text('error'.tr()),
        description: Text('lobby.captainTransfer.failed'.tr()),
        alignment: .bottomCenter,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final infoAsync = ref.watch(lobbyDetailControllerProvider(widget.lobbyId));
    final lobby = infoAsync.value?.lobby ?? widget.info.lobby;
    final currentUserId = ref.watch(authControllerProvider).value?.id;
    final isCaptain = currentUserId != null && lobby.captainId == currentUserId;
    final colors = context.theme.colors;
    final membersAsync =
        ref.watch(lobbyMembersControllerProvider(widget.lobbyId));
    final isSoleMember = (membersAsync.value?.length ?? 2) <= 1;
    final initial =
        lobby.name.isNotEmpty ? lobby.name[0].toUpperCase() : '?';

    final visLabel = switch (lobby.visibility) {
      LobbyVisibility.private => 'lobby.visibility.private'.tr(),
      LobbyVisibility.discoverable => 'lobby.visibility.discoverable'.tr(),
      LobbyVisibility.public => 'lobby.visibility.public'.tr(),
    };

    return SingleChildScrollView(
      controller: _scrollController,
      primary: false,
      child: Column(
        spacing: 18,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
              PSheetTitle(
                label: 'lobby.info'.tr(),
                trailing: FButton.icon(
                  variant: .ghost,
                  onPress: () => Navigator.of(context).pop(),
                  child: const Icon(FLucideIcons.x),
                ),
              ),

              // Lobby info card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: _crimsonTint,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colors.border),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initial,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: _crimson,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lobby.name,
                                style: context.theme.typography.body.lg.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  lobby.sport.getIcon(size: 12),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      lobby.sport.getLocalizedName(context),
                                      style: context.theme.typography.body.sm
                                          .copyWith(
                                        color: colors.mutedForeground,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    ' · ',
                                    style: TextStyle(
                                      color: colors.mutedForeground
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                                  _VisTag(label: visLabel),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Search ID
                    if (lobby.searchableId != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: colors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: colors.border.withValues(alpha: 0.6)),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'SearchID',
                              style: context.theme.typography.body.xs.copyWith(
                                color: colors.mutedForeground,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                lobby.searchableId!,
                                style: context.theme.typography.body.sm.copyWith(
                                  color: colors.secondaryForeground,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                            FButton.icon(
                              variant: .ghost,
                              onPress: () async {
                                await Clipboard.setData(ClipboardData(
                                    text: lobby.searchableId!));
                                if (!context.mounted) return;
                                showFToast(
                                  context: context,
                                  icon: const Icon(FLucideIcons.copy),
                                  title:
                                      Text('lobby.searchIDCopied'.tr()),
                                  alignment: .bottomCenter,
                                );
                              },
                              child: const Icon(FLucideIcons.copy, size: 14),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Location
                    if (widget.info.homeGroundName != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(FLucideIcons.mapPin,
                              size: 12, color: colors.mutedForeground),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              widget.info.homeGroundName!,
                              style: context.theme.typography.body.sm.copyWith(
                                color: colors.mutedForeground,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Members section
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PSheetSectionLabel(
                    label: membersAsync.value != null
                        ? '${'lobby.detail.members'.tr()} · ${membersAsync.value!.length}'
                        : 'lobby.detail.members'.tr(),
                    trailing: isCaptain
                        ? _SectionActionButton(
                            icon: FLucideIcons.userPlus,
                            label: 'lobby.invite'.tr(),
                            onTap: () => _showInviteUserSheet(
                                context, widget.lobbyId),
                          )
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: membersAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, _) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('errorGeneric'.tr()),
                      ),
                      data: (members) => members.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'lobby.detail.noMembers'.tr(),
                                style: TextStyle(
                                    color: colors.mutedForeground),
                              ),
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (var i = 0; i < members.length; i++) ...[
                                  _MemberRow(
                                    member: members[i],
                                    lobbyId: widget.lobbyId,
                                    captainId: lobby.captainId,
                                    currentUserId: currentUserId,
                                    isCaptain: isCaptain,
                                  ),
                                  if (i < members.length - 1)
                                    Divider(
                                      height: 1,
                                      indent: 60,
                                      color: colors.border
                                          .withValues(alpha: 0.5),
                                    ),
                                ],
                              ],
                            ),
                    ),
                  ),
                ],
              ),

              // Settings section
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PSheetSectionLabel(label: 'lobby.settings'.tr()),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCaptain) ...[
                          _SettingsRow(
                            icon: FLucideIcons.pencil,
                            label: 'lobby.edit'.tr(),
                            onTap: () => _editLobby(context, lobby),
                          ),
                          Divider(
                            height: 1,
                            indent: 50,
                            color: colors.border.withValues(alpha: 0.5),
                          ),
                          _SettingsRow(
                            icon: FLucideIcons.userPlus,
                            label: 'lobby.manageRequests'.tr(),
                            badge: _pendingBadge(ref, widget.lobbyId),
                            onTap: () => showJoinRequestsSheet(
                                context, widget.lobbyId),
                          ),
                          Divider(
                            height: 1,
                            indent: 50,
                            color: colors.border.withValues(alpha: 0.5),
                          ),
                        ],
                        _SettingsRow(
                          icon: FLucideIcons.bell,
                          label: 'lobby.notifications'.tr(),
                          onTap: () => showFToast(
                            context: context,
                            icon: const Icon(FLucideIcons.bell),
                            title: Text('lobby.comingSoon'.tr()),
                            alignment: .bottomCenter,
                          ),
                        ),
                        Divider(
                          height: 1,
                          indent: 50,
                          color: colors.border.withValues(alpha: 0.5),
                        ),
                        if (isCaptain) ...[
                          _SettingsRow(
                            icon: FLucideIcons.crown,
                            label: 'lobby.captainTransfer.title'.tr(),
                            onTap: _transferCaptaincy,
                          ),
                          if (isSoleMember) ...[
                            Divider(
                              height: 1,
                              indent: 50,
                              color: colors.border.withValues(alpha: 0.5),
                            ),
                            _SettingsRow(
                              icon: FLucideIcons.trash2,
                              label: 'lobby.delete.confirm'.tr(),
                              destructive: true,
                              onTap: _confirmDelete,
                            ),
                          ],
                        ] else
                          _SettingsRow(
                            icon: FLucideIcons.logOut,
                            label: 'lobby.leave.confirm'.tr(),
                            destructive: true,
                            onTap: _confirmLeave,
                          ),
                      ],
                    ),
                  ),
                ],
              ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Helper widgets ────────────────────────────────────────────

class _VisTag extends StatelessWidget {
  final String label;
  const _VisTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF5FF),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFF3090F2),
        ),
      ),
    );
  }
}

class _SectionActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SectionActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF3090F2)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF3090F2),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends ConsumerWidget {
  final LobbyMemberInfo member;
  final String lobbyId;
  final String? captainId;
  final String? currentUserId;
  final bool isCaptain;

  const _MemberRow({
    required this.member,
    required this.lobbyId,
    required this.captainId,
    required this.currentUserId,
    required this.isCaptain,
  });

  bool get _isMemberTheCaptain => member.userId == captainId;
  bool get _isMemberCurrentUser => member.userId == currentUserId;

  void _showMemberMenu(BuildContext context, WidgetRef ref) {
    showFDialog(
      context: context,
      builder: (dialogCtx, style, animation) => FDialog(
        animation: animation,
        title: Text('${member.username} #${member.tagNumber}'),
        direction: Axis.vertical,
        actions: [
          FButton(
            variant: .destructive,
            onPress: () {
              Navigator.of(dialogCtx).pop();
              _confirmKick(context, ref);
            },
            child: Text('lobby.kick.action'.tr()),
          ),
          FButton(
            variant: .ghost,
            onPress: () => Navigator.of(dialogCtx).pop(),
            child: Text('lobby.leave.cancel'.tr()),
          ),
        ],
      ),
    );
  }

  void _confirmKick(BuildContext context, WidgetRef ref) {
    showFDialog(
      context: context,
      builder: (dialogCtx, style, animation) => FDialog(
        animation: animation,
        title: Text('lobby.kick.title'.tr(namedArgs: {'username': member.username})),
        body: Text('lobby.kick.message'.tr()),
        direction: Axis.horizontal,
        actions: [
          FButton(
            variant: .outline,
            onPress: () => Navigator.of(dialogCtx).pop(),
            child: Text('lobby.leave.cancel'.tr()),
          ),
          FButton(
            variant: .destructive,
            onPress: () async {
              Navigator.of(dialogCtx).pop();
              try {
                await ref
                    .read(lobbyMembersControllerProvider(lobbyId).notifier)
                    .kick(lobbyId, member.userId);
              } catch (e, st) {
                Talker().handle(e, st, 'Kick member failed');
                if (context.mounted) {
                  showFToast(
                    context: context,
                    icon: const Icon(FLucideIcons.circleX),
                    variant: .destructive,
                    title: Text('error'.tr()),
                    description: Text('lobby.kick.failed'.tr()),
                    alignment: .bottomCenter,
                  );
                }
              }
            },
            child: Text('lobby.kick.confirm'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final initial = member.username.isNotEmpty
        ? member.username[0].toUpperCase()
        : '?';

    // Captain can kick any non-captain member who isn't themselves.
    final canKick =
        isCaptain && !_isMemberTheCaptain && !_isMemberCurrentUser;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _memberColor(member.username),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member.username,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF09090B),
                      ),
                    ),
                    if (_isMemberTheCaptain) ...[
                      const SizedBox(width: 4),
                      Icon(FLucideIcons.crown,
                          size: 11, color: colors.mutedForeground),
                    ],
                  ],
                ),
                Text(
                  '#${member.tagNumber}',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          if (canKick)
            GestureDetector(
              onTap: () => _showMemberMenu(context, ref),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: colors.border.withValues(alpha: 0.6)),
                ),
                child: Icon(FLucideIcons.ellipsis,
                    size: 14, color: colors.mutedForeground),
              ),
            ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final bool destructive;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    this.badge,
    this.destructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final fg = destructive
        ? colors.destructive
        : colors.foreground;
    final iconColor = destructive
        ? colors.destructive
        : colors.secondaryForeground;

    return FTappable(
      onPress: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ),
            if (badge != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: _crimsonTint,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _crimson,
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
            Icon(
              FLucideIcons.chevronRight,
              size: 14,
              color: colors.mutedForeground.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Invite user sheet ─────────────────────────────────────────

class _InviteUserSheet extends ConsumerStatefulWidget {
  final String lobbyId;
  const _InviteUserSheet({required this.lobbyId});

  @override
  ConsumerState<_InviteUserSheet> createState() => _InviteUserSheetState();
}

class _InviteUserSheetState extends ConsumerState<_InviteUserSheet> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return;

    final parts = raw.split('#');
    final username = parts[0].trim();
    final tagNumber = parts.length > 1 ? parts[1].trim() : null;

    if (username.isEmpty) {
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleAlert),
        variant: .destructive,
        title: Text('lobby.inviteUser.emptyError'.tr()),
        alignment: .bottomCenter,
      );
      return;
    }

    setState(() => _sending = true);
    try {
      final supabase = Supabase.instance.client;
      var query = supabase
          .from('user')
          .select('id')
          .eq('username', username);
      if (tagNumber != null) query = query.eq('tag_number', tagNumber);
      final rows = await query.limit(1).timeout(const Duration(seconds: 5));

      if (rows.isEmpty) {
        if (!mounted) return;
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.userX),
          variant: .destructive,
          title: Text('lobby.inviteUser.notFound'.tr(namedArgs: {'name': raw})),
          alignment: .bottomCenter,
        );
        return;
      }

      final targetUserId = (rows.first as Map)['id'] as String;
      final captainId = ref.read(authControllerProvider).value?.id;
      if (captainId == null) return;

      await supabase.from('lobby_befriend_record').insert({
        'initiator_user_id': captainId,
        'target_user_id': targetUserId,
        'target_lobby_id': widget.lobbyId,
        'interaction_type': 'invite',
      }).timeout(const Duration(seconds: 5));

      if (!mounted) return;
      Navigator.of(context).pop();
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.userPlus),
        title: Text('lobby.inviteUser.success'.tr(namedArgs: {'username': username})),
        alignment: .bottomCenter,
      );
    } catch (e, st) {
      Talker().handle(e, st, 'Invite user failed');
      if (!mounted) return;
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleX),
        variant: .destructive,
        title: Text('error'.tr()),
        description: Text('lobby.inviteUser.failed'.tr()),
        alignment: .bottomCenter,
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      primary: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          PSheetTitle(
            label: 'lobby.inviteMember'.tr(),
            trailing: FButton.icon(
              variant: .ghost,
              onPress: () => Navigator.of(context).pop(),
              child: const Icon(FLucideIcons.x),
            ),
          ),
          FTextField(
            label: Text('lobby.inviteUser.label'.tr()),
            hint: 'lobby.inviteUser.hint'.tr(),
            control: FTextFieldControl.managed(controller: _controller),
            description: Text('lobby.inviteUser.description'.tr()),
          ),
          FButton(
            onPress: _sending ? null : _invite,
            child: _sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text('lobby.inviteUser.send'.tr()),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

Color _memberColor(String name) {
  const palette = [
    Color(0xFF6366F1),
    Color(0xFF0EA5E9),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
    Color(0xFF8B5CF6),
  ];
  return palette[name.hashCode.abs() % palette.length];
}
