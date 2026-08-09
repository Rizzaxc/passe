// Chat-style trigger bar + action picker overlay
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../auth/auth_controller.dart';
import '../../../../core/model/user_avatar.dart';
import '../../../../ui/sheet.dart';
import '../../../../ui/theme.dart';
import '../../../../ui/user_avatar.dart';
import '../../../feed_tab/compose_post_sheet.dart';
import '../invite_member_sheet.dart';
import 'money_sheet.dart';
import 'poll_sheet.dart';

const _crimson = Color(0xFFDC143C);
const _crimsonTint = Color(0xFFFFEBED);
const _greenTint = Color(0xFFEEF2E4);
const _amberTint = Color(0xFFFDF3DC);
const _blueTint = Color(0xFFEBF5FF);
const _amber = Color(0xFFC58A1A);

// ─── Action catalog ────────────────────────────────────────────

class _ActionDef {
  final String id;
  final IconData icon;
  final String tone;
  final String label;

  const _ActionDef({
    required this.id,
    required this.icon,
    required this.tone,
    required this.label,
  });
}

// Captain-only per RLS ("Captain can post updates and polls" covers
// 'poll'). Reschedule/bookCoach moved to the Planner tab's per-card
// actions — they're activity-scoped, not lobby-scoped, so they don't
// belong in this lobby-wide picker anymore.
const _captainActions = [
  _ActionDef(
    id: 'poll',
    icon: Icons.bar_chart_rounded,
    tone: 'blue',
    label: 'Tạo bình chọn',
  ),
];

const _sharedActions = [
  _ActionDef(
    id: 'money',
    icon: Icons.payments_outlined,
    tone: 'green',
    label: 'Tiền trong lobby',
  ),
  _ActionDef(
    id: 'invite',
    icon: Icons.person_add_alt_1_outlined,
    tone: 'blue',
    label: 'Mời thành viên',
  ),
  // Restored now that wall posts exist. This was pulled in the 2026-07 pass
  // for want of a storage bucket; it now opens the wall composer scoped to
  // this lobby rather than writing a lobby-only photo item.
  _ActionDef(
    id: 'photo',
    icon: Icons.photo_camera_outlined,
    tone: 'amber',
    label: 'Đăng ảnh buổi chơi',
  ),
];

// ─── Chat trigger bar ──────────────────────────────────────────

class ChatTriggerBar extends ConsumerWidget {
  final bool isLeader;
  final VoidCallback onOpen;

  const ChatTriggerBar({
    super.key,
    required this.isLeader,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final me = ref.watch(authControllerProvider).value;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          // User avatar
          if (me?.id != null)
            PUserAvatar(
              userId: me!.id!,
              username: me.username,
              generatedAvatar: UserAvatar.encode(me.details?.avatar),
              radius: 15,
            ),
          const SizedBox(width: 8),
          // Field-style trigger (tappable, opens overlay)
          Expanded(
            child: GestureDetector(
              onTap: onOpen,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                decoration: BoxDecoration(
                  color: colors.secondary,
                  borderRadius: context.theme.style.borderRadius.md,
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        isLeader
                            ? 'Bạn muốn đăng gì cho lobby?'
                            : 'Bạn muốn đăng gì?',
                        style: context.theme.typography.body.sm.copyWith(
                          fontStyle: FontStyle.italic,
                          color: colors.mutedForeground,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: _crimson,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        FLucideIcons.plus,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action picker sheet ───────────────────────────────────────

/// Opens the action picker as a proper modal sheet on the root
/// navigator — sharing the app's standard PSheet chrome. The old
/// implementation rendered the picker as a `Positioned.fill` overlay
/// inside the activity tab's `Stack`, which meant it lived under a
/// child navigator and never dimmed the appbar / tab bar properly.
void showActionPickerSheet(
  BuildContext context, {
  required bool isLeader,
  required String lobbyId,
}) {
  showPSheet(
    context: context,
    padding: EdgeInsets.zero,
    builder: (_) => _ActionPickerSheet(isLeader: isLeader, lobbyId: lobbyId),
  );
}

class _ActionPickerSheet extends StatelessWidget {
  final bool isLeader;
  final String lobbyId;

  const _ActionPickerSheet({required this.isLeader, required this.lobbyId});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PSheetTitle(
                label: 'Đăng hoạt động',
                trailing: FButton.icon(
                  variant: .ghost,
                  onPress: () => Navigator.of(context).pop(),
                  child: const Icon(FLucideIcons.x),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Chọn một hành động để đăng vào feed của lobby',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: colors.mutedForeground,
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(color: colors.border.withValues(alpha: 0.5), height: 1),
        // Actions
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isLeader) ...[
                  const SizedBox(height: 8),
                  PSheetSectionLabel(
                    label: 'Đội trưởng',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          FLucideIcons.crown,
                          size: 11,
                          color: context.theme.colors.mutedForeground,
                        ),
                        const SizedBox(width: 6),
                        _SectionDescription('Chỉ đội trưởng'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  _ActionGroup(actions: _captainActions, lobbyId: lobbyId),
                ],
                const SizedBox(height: 14),
                PSheetSectionLabel(
                  label: 'Khác',
                  trailing: _SectionDescription('Mọi thành viên đều đăng được'),
                ),
                const SizedBox(height: 6),
                _ActionGroup(actions: _sharedActions, lobbyId: lobbyId),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Right-aligned italic helper text that pairs with [PSheetSectionLabel]
/// inside the action-picker sheet. Kept slightly smaller and more muted
/// than the label so the eye lands on the label first.
class _SectionDescription extends StatelessWidget {
  final String text;

  const _SectionDescription(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontStyle: FontStyle.italic,
        color: context.theme.colors.mutedForeground.withValues(alpha: 0.6),
      ),
    );
  }
}

class _ActionGroup extends StatelessWidget {
  final List<_ActionDef> actions;
  final String? lobbyId;

  const _ActionGroup({required this.actions, this.lobbyId});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            _ActionRow(def: actions[i], lobbyId: lobbyId),
            if (i < actions.length - 1)
              Divider(
                height: 1,
                indent: 56,
                color: colors.border.withValues(alpha: 0.5),
              ),
          ],
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final _ActionDef def;
  final String? lobbyId;

  const _ActionRow({required this.def, this.lobbyId});

  void _onPress(BuildContext context) {
    Navigator.of(context).pop();
    if (lobbyId == null) return;
    switch (def.id) {
      case 'money':
        showLobbyMoneySheet(context, lobbyId: lobbyId!);
      case 'invite':
        showInviteMemberSheet(context, lobbyId!);
      case 'photo':
        showComposePostSheet(context, lobbyId: lobbyId);
      case 'poll':
        showCreatePollSheet(context, lobbyId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final fg = _toneFg(def.tone);
    final bg = _toneBg(def.tone, colors);

    return FTappable(
      onPress: () => _onPress(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(def.icon, size: 16, color: fg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    def.label,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF09090B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              FLucideIcons.chevronRight,
              size: 16,
              color: colors.mutedForeground.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  static Color _toneFg(String tone) => switch (tone) {
    'crimson' => _crimson,
    'blue' => pbBlue,
    'green' => pbGreen,
    'amber' => _amber,
    _ => const Color(0xFF71717A),
  };

  static Color _toneBg(String tone, dynamic colors) => switch (tone) {
    'crimson' => _crimsonTint,
    'blue' => _blueTint,
    'green' => _greenTint,
    'amber' => _amberTint,
    _ => const Color(0xFFF4F4F5),
  };
}
