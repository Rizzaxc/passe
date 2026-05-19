// Feed item models + renderers — action-based, no free-text chat
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../../../ui/theme.dart';

// ─── Color tokens ──────────────────────────────────────────────
const _crimson = Color(0xFFDC143C);
const _crimsonTint = Color(0xFFFFEBED);
const _greenTint = Color(0xFFEEF2E4);
const _amberTint = Color(0xFFFDF3DC);
const _blueTint = Color(0xFFEBF5FF);
const _orange = Color(0xFFF97316);
const _amber = Color(0xFFC58A1A);

// ─── Feed item sealed hierarchy ─────────────────────────────────

sealed class FeedItem {
  const FeedItem();
}

final class DayDivItem extends FeedItem {
  final String label;
  const DayDivItem(this.label);
}

final class UpdateItem extends FeedItem {
  final String author;
  final String time;
  final String title;
  final IconData icon;
  final String tone; // 'crimson' | 'blue' | 'green' | 'amber'
  final List<(String, String)> fields;
  final String? ctaLabel;
  const UpdateItem({
    required this.author,
    required this.time,
    required this.title,
    required this.icon,
    required this.tone,
    required this.fields,
    this.ctaLabel,
  });
}

final class PersonalItem extends FeedItem {
  final String author;
  final String time;
  final String actionLabel;
  final Color actionColor;
  final Color actionBg;
  final IconData actionIcon;
  final String? detail;
  final List<String>? reactions;
  const PersonalItem({
    required this.author,
    required this.time,
    required this.actionLabel,
    required this.actionColor,
    required this.actionBg,
    required this.actionIcon,
    this.detail,
    this.reactions,
  });
}

final class SystemItem extends FeedItem {
  final String text;
  final bool hasApprove;
  const SystemItem({required this.text, this.hasApprove = false});
}

final class PollItem extends FeedItem {
  final String author;
  final String time;
  final String question;
  final List<(String, int)> options; // (label, voteCount)
  final int totalMembers;
  final String deadline;
  const PollItem({
    required this.author,
    required this.time,
    required this.question,
    required this.options,
    required this.totalMembers,
    required this.deadline,
  });
}

final class PhotoItem extends FeedItem {
  final String author;
  final String time;
  final String? caption;
  const PhotoItem({required this.author, required this.time, this.caption});
}

// ─── Mock feed data ─────────────────────────────────────────────

final List<FeedItem> kMockFeed = [
  const DayDivItem('Hôm qua'),

  UpdateItem(
    author: 'Trang', time: '08:50',
    title: 'Đã lên lịch buổi mới',
    icon: Icons.calendar_month_outlined,
    tone: 'crimson',
    fields: const [
      ('Thời gian', 'T7, 21/5 · 18:00 – 20:00'),
      ('Sân', 'NTĐ Bách Khoa · Sân 3'),
      ('Chi phí', '80k/người · Đôi nam nữ'),
    ],
  ),

  PersonalItem(
    author: 'An', time: '09:14',
    actionLabel: 'Mang thêm gear',
    actionColor: pbGreen,
    actionBg: _greenTint,
    actionIcon: Icons.sports_tennis_outlined,
    detail: '+1 ống cầu Yonex',
    reactions: const ['👍 3'],
  ),

  const SystemItem(text: 'Lan đã xin vào lobby.', hasApprove: true),

  PersonalItem(
    author: 'Long', time: '09:30',
    actionLabel: 'Đến sớm khởi động',
    actionColor: _amber,
    actionBg: _amberTint,
    actionIcon: Icons.local_fire_department_outlined,
    detail: '17:30 ra trước khởi động',
    reactions: const ['🔥 2'],
  ),

  PersonalItem(
    author: 'Lan', time: '09:38',
    actionLabel: 'Cần đi nhờ',
    actionColor: pbBlue,
    actionBg: _blueTint,
    actionIcon: Icons.directions_car_outlined,
    detail: 'Từ Q.1 — ai cùng tuyến cho đi nhờ',
  ),

  PersonalItem(
    author: 'Minh', time: '09:42',
    actionLabel: 'Cho đi nhờ',
    actionColor: pbBlue,
    actionBg: _blueTint,
    actionIcon: Icons.directions_car_outlined,
    detail: 'Xe oto, đi từ Q.3 lúc 17:00',
    reactions: const ['🤝 1'],
  ),

  UpdateItem(
    author: 'Trang', time: '10:02',
    title: 'Đã đặt HLV',
    icon: Icons.school_outlined,
    tone: 'green',
    fields: const [
      ('HLV', 'Nguyễn Minh · ★ 4.8'),
      ('Khi nào', 'T7, 28/5 · 14:00 – 16:00'),
      ('Chi phí', '200k/người · 3/6 đăng ký'),
    ],
    ctaLabel: 'Tham Gia',
  ),

  PollItem(
    author: 'Trang', time: '12:40',
    question: 'Tuần sau dời từ 18h → 19h được không?',
    options: const [
      ('Được, 19h hợp lý hơn', 4),
      ('18h như cũ luôn', 1),
    ],
    totalMembers: 6,
    deadline: 'Hết bình chọn T6',
  ),

  const PhotoItem(author: 'An', time: '11:05', caption: 'Sân tối nay sáng đẹp ghê'),

  const DayDivItem('Hôm nay'),

  PersonalItem(
    author: 'Phúc', time: '08:12',
    actionLabel: 'Vắng buổi này',
    actionColor: _crimson,
    actionBg: _crimsonTint,
    actionIcon: Icons.close_rounded,
    detail: 'Đi công tác Đà Nẵng',
  ),

  PersonalItem(
    author: 'Minh', time: '14:14',
    actionLabel: 'Đã chuyển tiền sân',
    actionColor: pbGreen,
    actionBg: _greenTint,
    actionIcon: Icons.account_balance_wallet_outlined,
    detail: '80k vào tài khoản Trang',
  ),
];

// ─── Feed item widget router ────────────────────────────────────

class FeedItemWidget extends StatelessWidget {
  final FeedItem item;
  const FeedItemWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return switch (item) {
      final DayDivItem d => _DayDivider(item: d),
      final UpdateItem u => _UpdateCard(item: u),
      final PersonalItem p => _PersonalCard(item: p),
      final SystemItem s => _SystemEvent(item: s),
      final PollItem po => _PollCard(item: po),
      final PhotoItem ph => _PhotoCard(item: ph),
    };
  }
}

// ─── Day divider ───────────────────────────────────────────────

class _DayDivider extends StatelessWidget {
  final DayDivItem item;
  const _DayDivider({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
      child: Row(
        children: [
          Expanded(child: Divider(color: colors.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              item.label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: colors.mutedForeground,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Expanded(child: Divider(color: colors.border)),
        ],
      ),
    );
  }
}

// ─── Author row (shared) ───────────────────────────────────────

class _AuthorRow extends StatelessWidget {
  final String name;
  final String time;

  const _AuthorRow({required this.name, required this.time});

  static const _captainName = 'Trang';

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final isLeader = name == _captainName;

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _memberColor(name),
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          name,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isLeader ? _crimson : colors.secondaryForeground,
          ),
        ),
        if (isLeader) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: _crimsonTint,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'ĐỘI TRƯỞNG',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: _crimson,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
        const Spacer(),
        Text(
          time,
          style: TextStyle(
            fontSize: 10.5,
            fontStyle: FontStyle.italic,
            color: colors.mutedForeground.withValues(alpha: 0.7),
          ),
        ),
      ],
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

// ─── Personal action card ──────────────────────────────────────

class _PersonalCard extends StatelessWidget {
  final PersonalItem item;
  const _PersonalCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AuthorRow(name: item.author, time: item.time),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 35),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: item.actionBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: item.actionColor.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                          color: item.actionColor.withValues(alpha: 0.3)),
                    ),
                    child: Icon(item.actionIcon,
                        size: 14, color: item.actionColor),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.actionLabel,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: item.actionColor,
                          ),
                        ),
                        if (item.detail != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.detail!,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: colors.secondaryForeground,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (item.reactions != null && item.reactions!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 35),
              child: Row(
                children: [
                  for (final r in item.reactions!)
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.background,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: colors.border.withValues(alpha: 0.8)),
                      ),
                      child: Text(
                        r,
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Captain update card ───────────────────────────────────────

class _UpdateCard extends StatelessWidget {
  final UpdateItem item;
  const _UpdateCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final fgColor = _toneFg(item.tone);
    final bgColor = _toneBg(item.tone);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AuthorRow(name: item.author, time: item.time),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 35),
            child: Container(
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    color: bgColor,
                    child: Row(
                      children: [
                        Icon(item.icon, size: 13, color: fgColor),
                        const SizedBox(width: 6),
                        Text(
                          item.title.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: fgColor,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final (label, value) in item.fields)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                SizedBox(
                                  width: 64,
                                  child: Text(
                                    label.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                      color: colors.mutedForeground,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    value,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF09090B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (item.ctaLabel != null) ...[
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: pbGreen,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                item.ctaLabel!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Color _toneFg(String tone) => switch (tone) {
        'crimson' => _crimson,
        'blue' => pbBlue,
        'green' => pbGreen,
        _ => _amber,
      };

  static Color _toneBg(String tone) => switch (tone) {
        'crimson' => _crimsonTint,
        'blue' => _blueTint,
        'green' => _greenTint,
        _ => _amberTint,
      };
}

// ─── System event (join request etc.) ─────────────────────────

class _SystemEvent extends StatelessWidget {
  final SystemItem item;
  const _SystemEvent({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: _crimsonTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(FIcons.userPlus, size: 15, color: _crimson),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.text,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: colors.secondaryForeground,
              ),
            ),
          ),
          if (item.hasApprove) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () {},
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _greenTint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Đồng Ý',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: pbGreen,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () {},
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0x25F97316),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Từ Chối',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _orange,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Poll card ─────────────────────────────────────────────────

class _PollCard extends StatefulWidget {
  final PollItem item;
  const _PollCard({required this.item});

  @override
  State<_PollCard> createState() => _PollCardState();
}

class _PollCardState extends State<_PollCard> {
  int? _voted;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final total = widget.item.options.fold<int>(0, (s, o) => s + o.$2) +
        (_voted != null ? 1 : 0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AuthorRow(name: widget.item.author, time: widget.item.time),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 35),
            child: Container(
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                  )
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    color: _blueTint,
                    child: Row(
                      children: [
                        const Icon(Icons.bar_chart_rounded,
                            size: 13, color: pbBlue),
                        const SizedBox(width: 6),
                        const Text(
                          'BÌNH CHỌN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: pbBlue,
                            letterSpacing: 0.7,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          widget.item.deadline,
                          style: TextStyle(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            color: colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.question,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF09090B),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 9),
                        for (var i = 0; i < widget.item.options.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _PollOption(
                              label: widget.item.options[i].$1,
                              votes: widget.item.options[i].$2 +
                                  (_voted == i ? 1 : 0),
                              total: total,
                              selected: _voted == i,
                              onTap: () => setState(() => _voted = i),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          '$total/${widget.item.totalMembers} đã bình chọn',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PollOption extends StatelessWidget {
  final String label;
  final int votes;
  final int total;
  final bool selected;
  final VoidCallback onTap;

  const _PollOption({
    required this.label,
    required this.votes,
    required this.total,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? votes / total : 0.0;
    final colors = context.theme.colors;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 40,
        child: Stack(
          children: [
            // Background
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: selected ? _blueTint : colors.background,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: selected
                        ? pbBlue
                        : colors.border.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
            // Progress fill
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: pct,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Container(
                    color: selected ? _blueTint : colors.secondary,
                  ),
                ),
              ),
            ),
            // Label + count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected ? pbBlue : const Color(0xFF09090B),
                      ),
                    ),
                  ),
                  Text(
                    '$votes · ${(pct * 100).round()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Photo card ────────────────────────────────────────────────

class _PhotoCard extends StatelessWidget {
  final PhotoItem item;
  const _PhotoCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AuthorRow(name: item.author, time: item.time),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 35),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 240,
                    height: 160,
                    child: CustomPaint(painter: _CourtPhotoPainter()),
                  ),
                ),
                if (item.caption != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    item.caption!,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: colors.secondaryForeground,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CourtPhotoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Dark court background
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xFF3D4760), Color(0xFF1C2334)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Wood floor
    canvas.drawRect(
      Rect.fromLTRB(0, size.height * 0.69, size.width, size.height),
      Paint()..color = const Color(0xFFA6804A),
    );

    // Court lines
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final court = Rect.fromLTWH(
      size.width * 0.17,
      size.height * 0.74,
      size.width * 0.66,
      size.height * 0.24,
    );
    canvas.drawRect(court, linePaint);
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.74),
      Offset(size.width * 0.5, size.height * 0.98),
      linePaint,
    );
    // Net line
    canvas.drawLine(
      Offset(size.width * 0.17, size.height * 0.86),
      Offset(size.width * 0.83, size.height * 0.86),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..strokeWidth = 2.0,
    );
  }

  @override
  bool shouldRepaint(_CourtPhotoPainter old) => false;
}
