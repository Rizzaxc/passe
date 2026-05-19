// Chat-style trigger bar + action picker overlay
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../../../ui/theme.dart';

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
  final String? intro;

  const _ActionDef({
    required this.id,
    required this.icon,
    required this.tone,
    required this.label,
    this.intro,
  });
}

const _personalActions = [
  _ActionDef(
    id: 'comeEarly',
    icon: Icons.local_fire_department_outlined,
    tone: 'amber',
    label: 'Đến sớm khởi động',
    intro: 'Báo giờ đến sớm để làm nóng cùng nhau',
  ),
  _ActionDef(
    id: 'late',
    icon: Icons.access_time_rounded,
    tone: 'crimson',
    label: 'Đến muộn',
    intro: 'Thông báo bạn sẽ đến trễ bao lâu',
  ),
  _ActionDef(
    id: 'bringGear',
    icon: Icons.sports_tennis_outlined,
    tone: 'green',
    label: 'Mang thêm gear',
    intro: 'Báo mang thêm cầu, vợt, giày…',
  ),
  _ActionDef(
    id: 'needLift',
    icon: Icons.directions_car_outlined,
    tone: 'blue',
    label: 'Cần đi nhờ',
    intro: 'Tìm người cùng tuyến đi chung',
  ),
  _ActionDef(
    id: 'offerLift',
    icon: Icons.directions_car_outlined,
    tone: 'blue',
    label: 'Cho đi nhờ',
    intro: 'Có chỗ trống trên xe, ai cùng tuyến?',
  ),
  _ActionDef(
    id: 'paid',
    icon: Icons.account_balance_wallet_outlined,
    tone: 'green',
    label: 'Đã chuyển tiền sân',
  ),
  _ActionDef(
    id: 'skip',
    icon: Icons.close_rounded,
    tone: 'crimson',
    label: 'Vắng buổi này',
    intro: 'Xin phép vắng và lý do',
  ),
  _ActionDef(
    id: 'cheer',
    icon: Icons.emoji_emotions_outlined,
    tone: 'neutral',
    label: 'Tăng động năng lượng',
  ),
];

const _captainActions = [
  _ActionDef(
    id: 'reschedule',
    icon: Icons.calendar_month_outlined,
    tone: 'crimson',
    label: 'Đổi giờ buổi',
  ),
  _ActionDef(
    id: 'bookCoach',
    icon: Icons.school_outlined,
    tone: 'green',
    label: 'Đặt HLV / Trọng tài',
  ),
  _ActionDef(
    id: 'invite',
    icon: Icons.person_add_alt_1_outlined,
    tone: 'blue',
    label: 'Mời thành viên',
  ),
];

const _sharedActions = [
  _ActionDef(
    id: 'poll',
    icon: Icons.bar_chart_rounded,
    tone: 'blue',
    label: 'Tạo bình chọn',
  ),
  _ActionDef(
    id: 'photo',
    icon: Icons.image_outlined,
    tone: 'blue',
    label: 'Đính kèm ảnh',
  ),
];

// ─── Chat trigger bar ──────────────────────────────────────────

class ChatTriggerBar extends StatelessWidget {
  final bool isLeader;
  final VoidCallback onOpen;

  const ChatTriggerBar({
    super.key,
    required this.isLeader,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          // User avatar
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF6366F1),
            ),
            alignment: Alignment.center,
            child: const Text(
              'B',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Pill input (tappable, opens overlay)
          Expanded(
            child: GestureDetector(
              onTap: onOpen,
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 7, 6, 7),
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: colors.border.withValues(alpha: 0.7)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        isLeader
                            ? 'Bạn muốn đăng gì cho lobby?'
                            : 'Bạn muốn đăng gì?',
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: colors.mutedForeground,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: _crimson,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(FIcons.plus,
                          size: 14, color: Colors.white),
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

// ─── Action picker overlay ─────────────────────────────────────

class ActionPickerOverlay extends StatelessWidget {
  final bool isLeader;
  final bool hasActivity;
  final VoidCallback onClose;

  const ActionPickerOverlay({
    super.key,
    required this.isLeader,
    required this.hasActivity,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Backdrop
        GestureDetector(
          onTap: onClose,
          child: Container(
            color: Colors.black.withValues(alpha: 0.45),
          ),
        ),
        // Sheet
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _ActionPickerSheet(
            isLeader: isLeader,
            hasActivity: hasActivity,
            onClose: onClose,
          ),
        ),
      ],
    );
  }
}

class _ActionPickerSheet extends StatelessWidget {
  final bool isLeader;
  final bool hasActivity;
  final VoidCallback onClose;

  const _ActionPickerSheet({
    required this.isLeader,
    required this.hasActivity,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: colors.border)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2F140C04),
            blurRadius: 50,
            offset: Offset(0, -20),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.muted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Đăng hoạt động',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF09090B),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Chọn một hành động để đăng vào feed của lobby',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onClose,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colors.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(FIcons.x,
                        size: 16, color: colors.secondaryForeground),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: colors.border.withValues(alpha: 0.5), height: 1),
          // Actions
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasActivity) ...[
                    const SizedBox(height: 8),
                    _SectionHeader(
                      label: 'Cá nhân',
                      description: 'Cập nhật trạng thái của bạn',
                    ),
                    _ActionGroup(actions: _personalActions),
                  ],
                  if (isLeader) ...[
                    const SizedBox(height: 14),
                    _SectionHeader(
                      label: 'Đội trưởng',
                      description: 'Chỉ đội trưởng',
                      showCrown: true,
                    ),
                    _ActionGroup(actions: _captainActions),
                  ],
                  const SizedBox(height: 14),
                  _SectionHeader(
                    label: 'Khác',
                    description: 'Mọi thành viên đều đăng được',
                  ),
                  _ActionGroup(actions: _sharedActions),
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final String description;
  final bool showCrown;

  const _SectionHeader({
    required this.label,
    required this.description,
    this.showCrown = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: colors.mutedForeground,
              letterSpacing: 0.7,
            ),
          ),
          if (showCrown) ...[
            const SizedBox(width: 4),
            Icon(FIcons.crown, size: 10, color: colors.mutedForeground),
          ],
          const Spacer(),
          Text(
            description,
            style: TextStyle(
              fontSize: 10,
              fontStyle: FontStyle.italic,
              color: colors.mutedForeground.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionGroup extends StatelessWidget {
  final List<_ActionDef> actions;

  const _ActionGroup({required this.actions});

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
            _ActionRow(def: actions[i]),
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

  const _ActionRow({required this.def});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final fg = _toneFg(def.tone);
    final bg = _toneBg(def.tone, colors);

    return FTappable(
      onPress: () {
        Navigator.of(context).pop();
      },
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
                  if (def.intro != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      def.intro!,
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.mutedForeground,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(FIcons.chevronRight,
                size: 16,
                color: colors.mutedForeground.withValues(alpha: 0.6)),
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
