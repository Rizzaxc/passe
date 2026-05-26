import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/model/lobby.dart';
import '../../ui/sheet.dart';
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

  @override
  Widget build(BuildContext context) {
    final lobby = widget.info.lobby;
    final colors = context.theme.colors;
    final membersAsync =
        ref.watch(lobbyMembersControllerProvider(widget.lobbyId));
    final initial =
        lobby.name.isNotEmpty ? lobby.name[0].toUpperCase() : '?';

    final visLabel = switch (lobby.visibility) {
      LobbyVisibility.private => 'Nội Bộ',
      LobbyVisibility.discoverable => 'Mặc Định',
      LobbyVisibility.public => 'Công Khai',
    };

    return SingleChildScrollView(
      controller: _scrollController,
      primary: false,
      child: Column(
        spacing: 18,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
              PSheetTitle(
                label: 'Thông tin lobby',
                trailing: FButton.icon(
                  variant: .ghost,
                  onPress: () => Navigator.of(context).pop(),
                  child: const Icon(FIcons.x),
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
                                style: context.theme.typography.lg.copyWith(
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
                                      style: context.theme.typography.sm
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
                              style: context.theme.typography.xs.copyWith(
                                color: colors.mutedForeground,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                lobby.searchableId!,
                                style: context.theme.typography.sm.copyWith(
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
                                  icon: const Icon(FIcons.copy),
                                  title:
                                      Text('lobby.searchIDCopied'.tr()),
                                  alignment: .bottomCenter,
                                );
                              },
                              child: const Icon(FIcons.copy, size: 14),
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
                          Icon(FIcons.mapPin,
                              size: 12, color: colors.mutedForeground),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              widget.info.homeGroundName!,
                              style: context.theme.typography.sm.copyWith(
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
                    label:
                        'Thành viên${membersAsync.value != null ? " · ${membersAsync.value!.length}" : ""}',
                    trailing: _SectionActionButton(
                      icon: FIcons.userPlus,
                      label: 'Mời',
                      onTap: () {},
                    ),
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
                                'Chưa có thành viên nào.',
                                style: TextStyle(
                                    color: colors.mutedForeground),
                              ),
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (var i = 0; i < members.length; i++) ...[
                                  _MemberRow(member: members[i]),
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
                  const PSheetSectionLabel(label: 'Cài đặt'),
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
                        _SettingsRow(
                          icon: FIcons.pencil,
                          label: 'Chỉnh sửa lobby',
                          onTap: () {},
                        ),
                        Divider(
                          height: 1,
                          indent: 50,
                          color: colors.border.withValues(alpha: 0.5),
                        ),
                        _SettingsRow(
                          icon: FIcons.userPlus,
                          label: 'Quản lý lời mời gia nhập',
                          badge: '2 đang chờ',
                          onTap: () {},
                        ),
                        Divider(
                          height: 1,
                          indent: 50,
                          color: colors.border.withValues(alpha: 0.5),
                        ),
                        _SettingsRow(
                          icon: FIcons.bell,
                          label: 'Thông báo',
                          onTap: () {},
                        ),
                        Divider(
                          height: 1,
                          indent: 50,
                          color: colors.border.withValues(alpha: 0.5),
                        ),
                        _SettingsRow(
                          icon: FIcons.logOut,
                          label: 'Rời lobby',
                          destructive: true,
                          onTap: () {},
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

class _MemberRow extends StatelessWidget {
  final LobbyMemberInfo member;
  const _MemberRow({required this.member});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final initial = member.username.isNotEmpty
        ? member.username[0].toUpperCase()
        : '?';

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
                Text(
                  member.username,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF09090B),
                  ),
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
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: colors.border.withValues(alpha: 0.6)),
              ),
              child: Icon(FIcons.ellipsis,
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
              FIcons.chevronRight,
              size: 14,
              color: colors.mutedForeground.withValues(alpha: 0.5),
            ),
          ],
        ),
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
