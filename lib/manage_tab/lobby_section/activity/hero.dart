// Pinned activity hero — empty state and expanded state
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:forui/forui.dart';

import '../../../../core/model/enum.dart';
import '../../../../ui/dual_button.dart';
import '../../../../ui/theme.dart';
import '../invite_challenge_sheet.dart';
import '../schedule_activity_sheet.dart';

// ─── Color tokens ──────────────────────────────────────────────
const _crimson = Color(0xFFDC143C);
const _crimsonTint = Color(0xFFFFEBED);
const _green = Color(0xFF959D54);
const _greenTint = Color(0xFFEEF2E4);
const _amber = Color(0xFFC58A1A);
const _amberTint = Color(0xFFFDF3DC);
const _orange = Color(0xFFF97316);

// ─── Entry point ───────────────────────────────────────────────

class ActivityHero extends StatefulWidget {
  final String lobbyId;
  final Sport? sport;
  final bool hasActivity;
  final bool isLeader;

  const ActivityHero({
    super.key,
    required this.lobbyId,
    required this.sport,
    required this.hasActivity,
    required this.isLeader,
  });

  @override
  State<ActivityHero> createState() => _ActivityHeroState();
}

class _ActivityHeroState extends State<ActivityHero> {
  // Local RSVP selection. There's no RSVP table yet — this is a
  // self-managed UI state so the control still feels live in the
  // design. Lift back out to a controller once the schema lands.
  String _myRsvp = 'going';

  @override
  Widget build(BuildContext context) {
    if (!widget.hasActivity) {
      return _HeroEmpty(lobbyId: widget.lobbyId, isLeader: widget.isLeader);
    }
    return _HeroExpanded(
      sport: widget.sport,
      isLeader: widget.isLeader,
      myRsvp: _myRsvp,
      onRsvpChanged: (v) => setState(() => _myRsvp = v),
    );
  }
}

// ─── Empty state ───────────────────────────────────────────────

class _HeroEmpty extends StatelessWidget {
  final String lobbyId;
  final bool isLeader;

  const _HeroEmpty({required this.lobbyId, required this.isLeader});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Padding(
      // 4-px horizontal inset matches FTabs' internal padding so the
      // card edge lines up with the tab pill edge (the FTabs widget
      // itself is wrapped by Padding(horizontal: 14) at the page level).
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(12),
          // Solid border instead of a hand-painted dashed one — the
          // dashed painter produced visibly stepped corners at this
          // width because the dash spacing didn't divide evenly around
          // the perimeter and used butt caps on the rounded arcs.
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: _crimsonTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.calendar_today_outlined,
                    size: 22, color: _crimson),
              ),
              const SizedBox(height: 8),
              const Text(
                'Chưa có buổi chơi nào',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF09090B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isLeader
                    ? 'Lên lịch buổi mới hoặc mời lobby khác thách đấu để khởi động.'
                    : 'Đội trưởng chưa lên lịch buổi nào. Bạn có thể nhắc.',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  color: colors.mutedForeground,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (isLeader)
                PDualButton(
                  onFirstPressed: () =>
                      showScheduleActivitySheet(context, lobbyId),
                  onSecondPressed: () =>
                      showInviteChallengeSheet(context, lobbyId),
                  firstChild: const _CTALabel(
                    icon: Icon(Icons.calendar_month_outlined, size: 20),
                    label: 'Lên Lịch Buổi Chơi',
                  ),
                  secondChild: const _CTALabel(
                    // Match the icon used in Discover ▸ Challenger.
                    icon: FaIcon(FontAwesomeIcons.fireFlameCurved, size: 20),
                    label: 'Mời Thách Đấu',
                  ),
                )
              else
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: colors.secondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FIcons.bell,
                            size: 14, color: colors.secondaryForeground),
                        const SizedBox(width: 6),
                        Text(
                          'Nhắc đội trưởng',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: colors.secondaryForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
    );
  }
}

/// Stacked icon + label used inside the empty hero's PDualButton.
///
/// Each half of the dual button gets one of these; the underlying
/// FButton sizes itself to fit, giving the two CTAs the same tall
/// silhouette the design called for.
class _CTALabel extends StatelessWidget {
  final Widget icon;
  final String label;

  const _CTALabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconTheme.merge(
            data: const IconThemeData(color: Color(0xFFFFF1F2)),
            child: icon,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFFF1F2),
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Expanded state ────────────────────────────────────────────

class _HeroExpanded extends StatelessWidget {
  final Sport? sport;
  final bool isLeader;
  final String myRsvp;
  final ValueChanged<String> onRsvpChanged;

  const _HeroExpanded({
    required this.sport,
    required this.isLeader,
    required this.myRsvp,
    required this.onRsvpChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return Padding(
      // See _HeroEmpty above — 4-px inset aligns with tab pill edges.
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
      child: Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Court bleed background
            Positioned(
              top: -10,
              right: -28,
              width: 156,
              height: 196,
              child: Opacity(
                opacity: 0.10,
                child: CustomPaint(
                  painter: _CourtPainter(sport ?? Sport.badminton),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Crimson top strip
                Container(height: 3, color: _crimson),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Label row
                      Row(
                        children: [
                          const Icon(Icons.push_pin_outlined,
                              size: 12, color: _crimson),
                          const SizedBox(width: 4),
                          const Text(
                            'GHIM · BUỔI TIẾP THEO',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _crimson,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const Spacer(),
                          _Tag(
                            text: 'còn 2 ngày',
                            icon: Icons.access_time_rounded,
                            tone: 'crimson',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Date + sport icon
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'T7, 21/5',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF09090B),
                                    letterSpacing: -0.5,
                                    height: 1.05,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '18:00 – 20:00',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: _crimson,
                                    letterSpacing: -0.2,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: colors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color:
                                      colors.border.withValues(alpha: 0.6)),
                            ),
                            child: Center(
                              child: sport?.getIcon(size: 34) ??
                                  const Icon(Icons.sports, size: 34),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Location
                      Row(
                        children: [
                          Icon(FIcons.mapPin,
                              size: 14, color: colors.mutedForeground),
                          const SizedBox(width: 6),
                          Text(
                            'NTĐ Bách Khoa',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: colors.secondaryForeground,
                            ),
                          ),
                          Text(
                            ' · ',
                            style: TextStyle(
                              color: colors.mutedForeground
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              'Q.10, Tp Hồ Chí Minh',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: colors.mutedForeground,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Tags
                      const Wrap(
                        spacing: 6,
                        children: [
                          _Tag(text: 'Sân 3', tone: 'neutral'),
                          _Tag(text: 'Đôi nam nữ', tone: 'neutral'),
                          _Tag(text: '80k/người', tone: 'neutral'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // RSVP avatars + summary
                      Row(
                        children: [
                          const _RsvpAvatarRow(),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text.rich(
                              TextSpan(children: const [
                                TextSpan(
                                  text: '4 có mặt',
                                  style: TextStyle(
                                    color: _green,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11.5,
                                  ),
                                ),
                                TextSpan(
                                  text: ' · ',
                                  style: TextStyle(fontSize: 11.5),
                                ),
                                TextSpan(
                                  text: '1 có thể',
                                  style: TextStyle(
                                    color: _amber,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11.5,
                                  ),
                                ),
                                TextSpan(
                                  text: ' · ',
                                  style: TextStyle(fontSize: 11.5),
                                ),
                                TextSpan(
                                  text: '1 vắng',
                                  style: TextStyle(
                                    color: _orange,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ]),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // RSVP segmented control
                      _RsvpControl(
                          value: myRsvp, onChange: onRsvpChanged),
                      const SizedBox(height: 12),
                      // Quick actions
                      Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const ClampingScrollPhysics(),
                              child: Row(
                                children: [
                                  _QuickAction(
                                    icon: Icons.navigation_outlined,
                                    label: 'Chỉ Đường',
                                    onTap: () {},
                                  ),
                                  const SizedBox(width: 6),
                                  if (isLeader) ...[
                                    _QuickAction(
                                      icon: Icons.calendar_month_outlined,
                                      label: 'Đổi Giờ',
                                      onTap: () {},
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  _QuickAction(
                                    icon: Icons.person_add_alt_1_outlined,
                                    label: 'Mời',
                                    onTap: () {},
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.more_horiz_rounded,
                                size: 18,
                                color: colors.secondaryForeground,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── RSVP avatar strip ──────────────────────────────────────────

class _RsvpAvatarRow extends StatelessWidget {
  const _RsvpAvatarRow();

  static const _going = [
    ('T', Color(0xFF6366F1)),
    ('A', Color(0xFF0EA5E9)),
    ('L', Color(0xFF10B981)),
    ('Lo', Color(0xFF8B5CF6)),
  ];
  static const _maybe = [
    ('M', Color(0xFFF59E0B)),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 5,
      children: [
        for (final (l, c) in _going)
          _RsvpAvatar(letter: l, bg: c, ring: 'going'),
        for (final (l, c) in _maybe)
          _RsvpAvatar(letter: l, bg: c, ring: 'maybe'),
      ],
    );
  }
}

class _RsvpAvatar extends StatelessWidget {
  final String letter;
  final Color bg;
  final String ring;

  const _RsvpAvatar({
    required this.letter,
    required this.bg,
    required this.ring,
  });

  @override
  Widget build(BuildContext context) {
    final ringColor = ring == 'going'
        ? _green
        : ring == 'maybe'
            ? _amber
            : _orange;
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: Border.all(color: ringColor, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ─── RSVP segmented control ────────────────────────────────────

class _RsvpControl extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChange;

  const _RsvpControl({required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          _RsvpBtn(
            id: 'going',
            label: 'Có Mặt',
            icon: Icons.check_rounded,
            active: value == 'going',
            tone: 'green',
            onTap: onChange,
          ),
          _RsvpBtn(
            id: 'maybe',
            label: 'Có Thể',
            icon: Icons.help_outline_rounded,
            active: value == 'maybe',
            tone: 'amber',
            onTap: onChange,
          ),
          _RsvpBtn(
            id: 'out',
            label: 'Vắng',
            icon: Icons.close_rounded,
            active: value == 'out',
            tone: 'red',
            onTap: onChange,
          ),
        ],
      ),
    );
  }
}

class _RsvpBtn extends StatelessWidget {
  final String id;
  final String label;
  final IconData icon;
  final bool active;
  final String tone;
  final ValueChanged<String> onTap;

  const _RsvpBtn({
    required this.id,
    required this.label,
    required this.icon,
    required this.active,
    required this.tone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final fg = tone == 'green'
        ? _green
        : tone == 'amber'
            ? _amber
            : _orange;
    final bg = tone == 'green'
        ? _greenTint
        : tone == 'amber'
            ? _amberTint
            : const Color(0x25F97316);

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: active ? bg : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 14,
                  color: active ? fg : colors.mutedForeground),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        active ? FontWeight.w700 : FontWeight.w600,
                    color: active ? fg : colors.secondaryForeground,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Quick action chip ─────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: colors.border.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: pbBlue),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: colors.secondaryForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Inline tag ────────────────────────────────────────────────

class _Tag extends StatelessWidget {
  final String text;
  final IconData? icon;
  final String tone;

  const _Tag({required this.text, this.icon, this.tone = 'neutral'});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final Color fg = tone == 'crimson'
        ? _crimson
        : tone == 'green'
            ? _green
            : colors.secondaryForeground;
    final Color bg = tone == 'crimson'
        ? _crimsonTint
        : tone == 'green'
            ? _greenTint
            : colors.secondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: 3),
          ],
          Text(
            text,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
  }
}

// ─── Court bleed painter ───────────────────────────────────────

class _CourtPainter extends CustomPainter {
  final Sport sport;
  const _CourtPainter(this.sport);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _crimson
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Scale from viewBox 120x160
    canvas.scale(size.width / 120, size.height / 160);

    switch (sport) {
      case Sport.badminton:
      case Sport.others:
        _badminton(canvas, paint);
      case Sport.soccer:
        _soccer(canvas, paint);
      case Sport.basketball:
        _basketball(canvas, paint);
      case Sport.tennis:
        _tennis(canvas, paint);
      case Sport.pickleball:
        _pickleball(canvas, paint);
    }
  }

  void _badminton(Canvas c, Paint p) {
    c.drawRect(const Rect.fromLTWH(2, 2, 116, 156), p);
    c.drawLine(const Offset(2, 80), const Offset(118, 80), p);
    c.drawLine(const Offset(60, 2), const Offset(60, 158), p);
    c.drawRect(const Rect.fromLTWH(20, 20, 80, 120), p);
    c.drawLine(const Offset(20, 55), const Offset(100, 55), p);
    c.drawLine(const Offset(20, 105), const Offset(100, 105), p);
  }

  void _soccer(Canvas c, Paint p) {
    c.drawRect(const Rect.fromLTWH(2, 2, 116, 156), p);
    c.drawLine(const Offset(2, 80), const Offset(118, 80), p);
    c.drawCircle(const Offset(60, 80), 22, p);
    c.drawRect(const Rect.fromLTWH(30, 2, 60, 22), p);
    c.drawRect(const Rect.fromLTWH(30, 136, 60, 22), p);
  }

  void _basketball(Canvas c, Paint p) {
    c.drawRect(const Rect.fromLTWH(2, 2, 116, 156), p);
    c.drawLine(const Offset(2, 80), const Offset(118, 80), p);
    c.drawCircle(const Offset(60, 80), 18, p);
    final path1 = Path()
      ..moveTo(2, 22)
      ..cubicTo(40, 22, 40, 60, 60, 60)
      ..cubicTo(80, 60, 80, 22, 118, 22);
    c.drawPath(path1, p);
    final path2 = Path()
      ..moveTo(2, 138)
      ..cubicTo(40, 138, 40, 100, 60, 100)
      ..cubicTo(80, 100, 80, 138, 118, 138);
    c.drawPath(path2, p);
  }

  void _tennis(Canvas c, Paint p) {
    c.drawRect(const Rect.fromLTWH(2, 2, 116, 156), p);
    c.drawLine(const Offset(2, 80), const Offset(118, 80), p);
    c.drawLine(const Offset(60, 40), const Offset(60, 120), p);
    c.drawRect(const Rect.fromLTWH(20, 40, 80, 80), p);
  }

  void _pickleball(Canvas c, Paint p) {
    c.drawRect(const Rect.fromLTWH(2, 2, 116, 156), p);
    c.drawLine(const Offset(2, 80), const Offset(118, 80), p);
    c.drawLine(const Offset(60, 2), const Offset(60, 60), p);
    c.drawLine(const Offset(60, 100), const Offset(60, 158), p);
    c.drawRect(const Rect.fromLTWH(2, 60, 116, 40), p);
  }

  @override
  bool shouldRepaint(_CourtPainter old) => old.sport != sport;
}

