import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../ui/theme.dart';

// ─── Block types ──────────────────────────────────────────────────────────────

enum _BlockType { warmup, drill, scrim, cool, game, review }

Color _blockColor(_BlockType t) => switch (t) {
      _BlockType.warmup => pbGreen,
      _BlockType.drill => pbBlue,
      _BlockType.scrim => const Color(0xFFDC143C),
      _BlockType.cool => const Color(0xFF71717A),
      _BlockType.game => const Color(0xFFDC143C),
      _BlockType.review => pbBlue,
    };

// ─── Data models ──────────────────────────────────────────────────────────────

class _Block {
  final _BlockType type;
  final String name;
  final int duration;
  final String? sets;
  final String? note;

  const _Block({
    required this.type,
    required this.name,
    required this.duration,
    this.sets,
    this.note,
  });
}

class _Coach {
  final String name;
  final String title;
  final int years;
  final double rating;
  final int reviewCount;
  final String initials;
  final Color color;
  final bool verified;

  const _Coach({
    required this.name,
    required this.title,
    required this.years,
    required this.rating,
    required this.reviewCount,
    required this.initials,
    required this.color,
    required this.verified,
  });
}

enum _CourseType { package, retainer, group }

// ignore: unused_field
enum _PaymentMode { handshake, da, mixed }

enum _SessionStatus { done, upcoming, cancelled }

class _Course {
  final String id;
  final String title;
  final _CourseType type;
  final int? totalSessions;
  final int completedSessions;
  final String schedule;
  final String venue;
  final int pricePerSession;
  final _PaymentMode paymentMode;
  final int paidSessions;
  final bool ongoing;
  final bool structured;
  final bool reviewed;

  const _Course({
    required this.id,
    required this.title,
    required this.type,
    this.totalSessions,
    required this.completedSessions,
    required this.schedule,
    required this.venue,
    required this.pricePerSession,
    required this.paymentMode,
    required this.paidSessions,
    required this.ongoing,
    required this.structured,
    this.reviewed = false,
  });
}

class _Session {
  final String id;
  final String courseId;
  final int index;
  final DateTime at;
  final _SessionStatus status;
  final bool paid;
  final List<_Block>? blocks;
  final String? notes;

  const _Session({
    required this.id,
    required this.courseId,
    required this.index,
    required this.at,
    required this.status,
    required this.paid,
    this.blocks,
    this.notes,
  });
}

// ─── Mock data ────────────────────────────────────────────────────────────────

const _kCoach = _Coach(
  name: 'Hoàng Vũ',
  title: 'HLV Bóng đá',
  years: 7,
  rating: 4.8,
  reviewCount: 142,
  initials: 'HV',
  color: Color(0xFFDC143C),
  verified: true,
);

const _kBlocks = [
  _Block(type: _BlockType.warmup, name: 'Khởi động', duration: 10, note: '2 vòng sân + ép dẻo'),
  _Block(type: _BlockType.drill, name: 'Chuyền ngắn', duration: 15, sets: '4 × 25'),
  _Block(type: _BlockType.drill, name: 'Cone dribble', duration: 15, sets: '3 × 30s'),
  _Block(type: _BlockType.scrim, name: 'Đá nhỏ 3v3', duration: 20),
  _Block(type: _BlockType.cool, name: 'Giãn cơ', duration: 10),
];

const _kActiveCourse = _Course(
  id: 'c-hv-8',
  title: 'Kĩ thuật cá nhân 8 buổi',
  type: _CourseType.package,
  totalSessions: 8,
  completedSessions: 5,
  schedule: 'T3, T6 · 18h00',
  venue: 'Sân Tao Đàn 3',
  pricePerSession: 350,
  paymentMode: _PaymentMode.handshake,
  paidSessions: 4,
  ongoing: true,
  structured: true,
);

const _kPastCourse = _Course(
  id: 'c-hv-prev',
  title: 'Kĩ thuật cơ bản 6 buổi',
  type: _CourseType.package,
  totalSessions: 6,
  completedSessions: 6,
  schedule: 'T2, T5 · 17h30',
  venue: 'Sân Hoa Lư',
  pricePerSession: 320,
  paymentMode: _PaymentMode.handshake,
  paidSessions: 6,
  ongoing: false,
  structured: true,
  reviewed: false,
);

List<_Session> _buildSessions() {
  final now = DateTime.now();

  DateTime at(int offsetDays, int hour, [int minute = 0]) {
    final d = now.add(Duration(days: offsetDays));
    return DateTime(d.year, d.month, d.day, hour, minute);
  }

  return [
    _Session(id: 's1', courseId: 'c-hv-8', index: 1, at: at(-14, 18), status: _SessionStatus.done, paid: true, blocks: _kBlocks, notes: 'Tốt. Bài chuyền đã ổn.'),
    _Session(id: 's2', courseId: 'c-hv-8', index: 2, at: at(-11, 18), status: _SessionStatus.done, paid: true, blocks: _kBlocks, notes: 'Cần kiểm soát bóng tốt hơn.'),
    _Session(id: 's3', courseId: 'c-hv-8', index: 3, at: at(-7, 18), status: _SessionStatus.done, paid: true, blocks: _kBlocks, notes: 'Cone drill cải thiện rõ. Tăng tốc cuối còn chậm 1 nhịp.'),
    _Session(id: 's4', courseId: 'c-hv-8', index: 4, at: at(-4, 18), status: _SessionStatus.done, paid: true, blocks: _kBlocks, notes: 'Tốt. Tập trung tốt suốt 70 phút.'),
    _Session(id: 's5', courseId: 'c-hv-8', index: 5, at: at(-1, 18), status: _SessionStatus.done, paid: false, blocks: _kBlocks, notes: 'Đá nhỏ 3v3 — kiểm soát bóng dưới áp lực còn yếu.'),
    _Session(id: 's6', courseId: 'c-hv-8', index: 6, at: at(0, 18), status: _SessionStatus.upcoming, paid: false, blocks: _kBlocks, notes: null),
    _Session(id: 's7', courseId: 'c-hv-8', index: 7, at: at(3, 18), status: _SessionStatus.upcoming, paid: false, blocks: _kBlocks, notes: null),
    _Session(id: 's8', courseId: 'c-hv-8', index: 8, at: at(7, 18), status: _SessionStatus.upcoming, paid: false, blocks: _kBlocks, notes: null),
    _Session(id: 'p1', courseId: 'c-hv-prev', index: 1, at: at(-60, 17, 30), status: _SessionStatus.done, paid: true, notes: 'Bước chân và đặt chân trụ ổn.'),
    _Session(id: 'p2', courseId: 'c-hv-prev', index: 2, at: at(-57, 17, 30), status: _SessionStatus.done, paid: true, notes: 'Chuyền dài còn yếu — về tập thêm.'),
    _Session(id: 'p3', courseId: 'c-hv-prev', index: 3, at: at(-53, 17, 30), status: _SessionStatus.done, paid: true, notes: 'Buổi tốt nhất tới giờ. Đột phá bằng vai trái rất tự nhiên.'),
    _Session(id: 'p4', courseId: 'c-hv-prev', index: 4, at: at(-50, 17, 30), status: _SessionStatus.done, paid: true, notes: 'Mỏi nhẹ vai. Buổi tới tập light.'),
    _Session(id: 'p5', courseId: 'c-hv-prev', index: 5, at: at(-46, 17, 30), status: _SessionStatus.done, paid: true, notes: 'Đá tập 3v3 — kiểm soát bóng tiến bộ rõ.'),
    _Session(id: 'p6', courseId: 'c-hv-prev', index: 6, at: at(-43, 17, 30), status: _SessionStatus.done, paid: true, notes: 'Hoàn thành khóa. Sẵn sàng cho khóa 8 buổi.'),
  ];
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

bool _isToday(DateTime d) {
  final now = DateTime.now();
  return d.year == now.year && d.month == now.month && d.day == now.day;
}

String _fmtTime(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}h${d.minute.toString().padLeft(2, '0')}';

String _relDay(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(d.year, d.month, d.day);
  final diff = target.difference(today).inDays;

  if (diff == 0) return 'Hôm nay';
  if (diff == 1) return 'Ngày mai';
  if (diff == -1) return 'Hôm qua';
  if (diff > 1 && diff < 7) {
    const names = ['CN', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy'];
    return names[d.weekday % 7];
  }
  return '${d.day}/${d.month}';
}

// ─── Root widget ──────────────────────────────────────────────────────────────

class CoachingSection extends StatefulWidget {
  const CoachingSection({super.key});

  @override
  State<CoachingSection> createState() => _CoachingSectionState();
}

class _CoachingSectionState extends State<CoachingSection> {
  late final List<_Session> _sessions = _buildSessions();

  Future<void> _refresh() async {
    await Future.delayed(const Duration(milliseconds: 600));
  }

  void _showSessionPreview(_Session session, _Course course) {
    showFSheet<void>(
      context: context,
      useRootNavigator: true,
      side: .btt,
      mainAxisMaxRatio: 0.85,
      builder: (_) => _SessionPreviewSheet(session: session, course: course, coach: _kCoach),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeSessions = _sessions.where((s) => s.courseId == _kActiveCourse.id).toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    final pastSessions = _sessions.where((s) => s.courseId == _kPastCourse.id).toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    final nextSession = activeSessions.firstWhere(
      (s) => _isToday(s.at),
      orElse: () => activeSessions.firstWhere(
        (s) => s.status == _SessionStatus.upcoming,
        orElse: () => activeSessions.last,
      ),
    );

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          _CoachStrip(coach: _kCoach),
          const SizedBox(height: 16),
          _NextUpHero(session: nextSession, course: _kActiveCourse),
          const SizedBox(height: 16),
          _CurrentJourneySection(
            course: _kActiveCourse,
            sessions: activeSessions,
            onCellTap: (s) => _showSessionPreview(s, _kActiveCourse),
          ),
          const SizedBox(height: 16),
          _PastJourneysSection(
            courses: [_kPastCourse],
            sessions: pastSessions,
            onCellTap: (s) => _showSessionPreview(s, _kPastCourse),
          ),
          const SizedBox(height: 8),
          _BrowseMoreCta(),
        ],
      ),
    );
  }
}

// ─── Coach strip ──────────────────────────────────────────────────────────────

class _CoachStrip extends StatelessWidget {
  final _Coach coach;

  const _CoachStrip({required this.coach});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return FCard(
      child: Row(
        spacing: 12,
        children: [
          _Avatar(initials: coach.initials, color: coach.color, size: 44),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 3,
              children: [
                Row(
                  spacing: 6,
                  children: [
                    Flexible(
                      child: Text(
                        coach.name,
                        style: context.theme.typography.body.sm.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (coach.verified)
                      Icon(FLucideIcons.badgeCheck, size: 14, color: pbBlue),
                  ],
                ),
                Text(
                  '${coach.title} · ${coach.years}năm KN',
                  style: context.theme.typography.body.xs.copyWith(color: colors.mutedForeground),
                ),
              ],
            ),
          ),
          _RatingBadge(rating: coach.rating, reviewCount: coach.reviewCount),
        ],
      ),
    );
  }
}

// ─── Next-up hero ─────────────────────────────────────────────────────────────

class _NextUpHero extends StatelessWidget {
  final _Session session;
  final _Course course;

  const _NextUpHero({required this.session, required this.course});

  @override
  Widget build(BuildContext context) {
    const crimson = Color(0xFFDC143C);
    final isToday = _isToday(session.at);
    final totalDur = (session.blocks ?? []).fold(0, (s, b) => s + b.duration);

    return Material(
      color: crimson,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(18),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Decorative numeral
              Positioned(
                right: -20,
                top: -32,
                child: Text(
                  '${session.index}',
                  style: TextStyle(
                    fontFamily: context.theme.typography.body.xl8.fontFamily,
                    fontSize: 160,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.08),
                    height: 1,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 14,
                children: [
                  // Label row
                  Row(
                    spacing: 6,
                    children: [
                      Text(
                        isToday ? 'Buổi tới · Hôm nay' : 'Buổi tới · ${_relDay(session.at)}',
                        style: context.theme.typography.body.xs.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Container(
                        width: 4, height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        _fmtTime(session.at),
                        style: context.theme.typography.body.xs.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  // Title block
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 6,
                    children: [
                      Text(
                        course.title,
                        style: context.theme.typography.body.xl2.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                          height: 1.15,
                        ),
                      ),
                      if (course.totalSessions != null)
                        Text(
                          'Buổi ${session.index} / ${course.totalSessions}',
                          style: context.theme.typography.body.sm.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                    ],
                  ),
                  // Divider + venue + CTA
                  Column(
                    spacing: 12,
                    children: [
                      Container(height: 1, color: Colors.white.withValues(alpha: 0.15)),
                      Row(
                        spacing: 8,
                        children: [
                          Icon(FLucideIcons.mapPin, size: 13, color: Colors.white.withValues(alpha: 0.85)),
                          Expanded(
                            child: Text(
                              course.venue,
                              style: context.theme.typography.body.xs.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              spacing: 4,
                              children: [
                                Text(
                                  'Xem chi tiết',
                                  style: context.theme.typography.body.xs.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Icon(FLucideIcons.forward, size: 11, color: Colors.white),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Block preview bar
                  if ((session.blocks ?? []).isNotEmpty && totalDur > 0)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: SizedBox(
                        height: 6,
                        child: Row(
                          children: [
                            for (final block in session.blocks!)
                              Flexible(
                                flex: block.duration,
                                child: Container(color: _blockColor(block.type)),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Current journey section ──────────────────────────────────────────────────

class _CurrentJourneySection extends StatelessWidget {
  final _Course course;
  final List<_Session> sessions;
  final void Function(_Session) onCellTap;

  const _CurrentJourneySection({
    required this.course,
    required this.sessions,
    required this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final total = course.totalSessions ?? (course.completedSessions + 4);
    final openEnded = course.totalSessions == null;
    final unpaidCount = course.completedSessions - course.paidSessions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        _SectionHeader(
          title: 'Lộ trình hiện tại',
          subtitle: '${course.completedSessions}${course.totalSessions != null ? '/${course.totalSessions}' : ''} buổi',
        ),
        FCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              // Course row
              Row(
                spacing: 10,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 4,
                      children: [
                        Text(
                          course.title,
                          style: context.theme.typography.body.sm.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Row(
                          spacing: 6,
                          children: [
                            _CourseTypeBadge(type: course.type),
                            Text(
                              '· ${course.schedule}',
                              style: context.theme.typography.body.xs.copyWith(color: colors.mutedForeground),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(FLucideIcons.chevronRight, size: 16, color: colors.mutedForeground),
                ],
              ),
              // Ribbon
              _JourneyRibbon(
                total: total,
                sessions: sessions,
                openEnded: openEnded,
                onCellTap: onCellTap,
              ),
              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    spacing: 4,
                    children: [
                      Icon(FLucideIcons.info, size: 11, color: colors.mutedForeground),
                      Text(
                        'Chạm vào ô để xem ghi chú',
                        style: context.theme.typography.body.xs.copyWith(
                          color: colors.mutedForeground,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (unpaidCount > 0)
                    Text(
                      '$unpaidCount buổi chưa trả',
                      style: context.theme.typography.body.xs.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Journey ribbon ───────────────────────────────────────────────────────────

class _JourneyRibbon extends StatelessWidget {
  final int total;
  final List<_Session> sessions;
  final bool openEnded;
  final void Function(_Session) onCellTap;

  const _JourneyRibbon({
    required this.total,
    required this.sessions,
    required this.openEnded,
    required this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Row(
      spacing: 3,
      children: [
        for (var i = 1; i <= total; i++)
          Builder(builder: (context) {
            final session = sessions.where((s) => s.index == i).firstOrNull;
            final isToday = session != null && _isToday(session.at);
            final isDone = session?.status == _SessionStatus.done;
            final isPaid = session?.paid ?? false;

            final Color bg;
            final Color textColor;
            final Color borderColor;
            final FontWeight weight;

            if (isToday) {
              bg = colors.primary;
              textColor = colors.primaryForeground;
              borderColor = colors.primary;
              weight = FontWeight.w800;
            } else if (isDone && isPaid) {
              bg = const Color(0xFFDDF0E2);
              textColor = const Color(0xFF3F7E4B);
              borderColor = Colors.transparent;
              weight = FontWeight.w700;
            } else if (isDone && !isPaid) {
              bg = const Color(0xFFFBE7D3);
              textColor = const Color(0xFF8E5D1F);
              borderColor = Colors.transparent;
              weight = FontWeight.w700;
            } else if (session != null) {
              bg = colors.card;
              textColor = colors.foreground;
              borderColor = colors.border;
              weight = FontWeight.w600;
            } else {
              bg = colors.secondary;
              textColor = colors.mutedForeground;
              borderColor = colors.border;
              weight = FontWeight.w500;
            }

            final cell = AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 38,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: borderColor),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$i',
                    style: TextStyle(
                      fontFamily: context.theme.typography.body.xs.fontFamily,
                      fontSize: 12,
                      fontWeight: weight,
                      color: textColor,
                      height: 1,
                    ),
                  ),
                  if (isToday) ...[
                    const SizedBox(height: 2),
                    Container(
                      width: 4, height: 4,
                      decoration: BoxDecoration(
                        color: colors.primaryForeground,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            );

            return Expanded(
              child: session != null
                  ? FTappable(onPress: () => onCellTap(session), child: cell)
                  : cell,
            );
          }),
        if (openEnded)
          SizedBox(
            width: 36, height: 38,
            child: Center(
              child: Text(
                '…',
                style: context.theme.typography.body.lg.copyWith(
                  color: context.theme.colors.mutedForeground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Past journeys section ────────────────────────────────────────────────────

class _PastJourneysSection extends StatelessWidget {
  final List<_Course> courses;
  final List<_Session> sessions;
  final void Function(_Session) onCellTap;

  const _PastJourneysSection({
    required this.courses,
    required this.sessions,
    required this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        _SectionHeader(title: 'Hành trình đã qua', subtitle: '${courses.length} khóa'),
        for (final course in courses)
          _PastCourseCard(
            course: course,
            sessions: sessions.where((s) => s.courseId == course.id).toList()
              ..sort((a, b) => a.index.compareTo(b.index)),
            onCellTap: onCellTap,
          ),
      ],
    );
  }
}

class _PastCourseCard extends StatelessWidget {
  final _Course course;
  final List<_Session> sessions;
  final void Function(_Session) onCellTap;

  const _PastCourseCard({
    required this.course,
    required this.sessions,
    required this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final total = course.totalSessions ?? course.completedSessions;

    return FCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(
                      course.title,
                      style: context.theme.typography.body.sm.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Row(
                      spacing: 6,
                      children: [
                        _StatusChip(label: 'Hoàn thành', color: const Color(0xFF3F7E4B), bg: const Color(0xFFDDF0E2)),
                        Text(
                          '· ${course.schedule}',
                          style: context.theme.typography.body.xs.copyWith(color: colors.mutedForeground),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!course.reviewed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'chưa đánh giá',
                    style: context.theme.typography.body.xs.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Icon(FLucideIcons.chevronRight, size: 16, color: colors.mutedForeground),
            ],
          ),
          _JourneyRibbon(
            total: total,
            sessions: sessions,
            openEnded: false,
            onCellTap: onCellTap,
          ),
          if (!course.reviewed)
            FButton(
              onPress: () {},
              child: const Text('Đánh giá khóa này'),
            ),
        ],
      ),
    );
  }
}

// ─── Browse more CTA ──────────────────────────────────────────────────────────

class _BrowseMoreCta extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return FTappable(
      onPress: () {},
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border, style: BorderStyle.solid),
        ),
        child: Row(
          spacing: 12,
          children: [
            Icon(FLucideIcons.sparkles, size: 16, color: colors.mutedForeground),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    'Đổi sang môn khác',
                    style: context.theme.typography.body.sm.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Chạm biểu tượng thể thao trên góc phải để chuyển HLV.',
                    style: context.theme.typography.body.xs.copyWith(color: colors.mutedForeground),
                  ),
                ],
              ),
            ),
            Icon(FLucideIcons.chevronRight, size: 14, color: colors.mutedForeground),
          ],
        ),
      ),
    );
  }
}

// ─── Session preview sheet ────────────────────────────────────────────────────

class _SessionPreviewSheet extends StatelessWidget {
  final _Session session;
  final _Course course;
  final _Coach coach;

  const _SessionPreviewSheet({
    required this.session,
    required this.course,
    required this.coach,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final isToday = _isToday(session.at);
    final done = session.status == _SessionStatus.done;
    final totalDur = (session.blocks ?? []).fold(0, (s, b) => s + b.duration);

    Color badgeColor;
    if (done && session.paid) {
      badgeColor = const Color(0xFF3F7E4B);
    } else if (done) {
      badgeColor = const Color(0xFFF97316);
    } else if (isToday) {
      badgeColor = colors.primary;
    } else {
      badgeColor = colors.foreground;
    }

    return FSheets(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            // Header row
            Row(
              spacing: 12,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${session.index}',
                    style: context.theme.typography.body.lg.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 3,
                    children: [
                      Text(
                        'BUỔI ${session.index}${course.totalSessions != null ? ' / ${course.totalSessions}' : ''}',
                        style: context.theme.typography.body.xs.copyWith(
                          color: colors.mutedForeground,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.7,
                        ),
                      ),
                      Text(
                        '${isToday ? 'Hôm nay' : _relDay(session.at)} · ${_fmtTime(session.at)}',
                        style: context.theme.typography.body.lg.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${session.at.day}/${session.at.month} · ${course.venue}',
                        style: context.theme.typography.body.xs.copyWith(color: colors.mutedForeground),
                      ),
                    ],
                  ),
                ),
                _StatusChipForSession(status: session.status, paid: session.paid),
              ],
            ),
            // Coach note (past session with notes)
            if (done && session.notes != null && session.notes!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF8F0),
                  border: Border.all(color: const Color(0xFFE8E1CB)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    Row(
                      spacing: 8,
                      children: [
                        _Avatar(initials: coach.initials, color: coach.color, size: 22),
                        Text(
                          'GHI CHÚ TỪ ${coach.name.toUpperCase()}',
                          style: context.theme.typography.body.xs.copyWith(
                            color: const Color(0xFF8E7B3F),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.only(left: 10),
                      decoration: const BoxDecoration(
                        border: Border(left: BorderSide(color: Color(0xFFC9B87C), width: 2)),
                      ),
                      child: Text(
                        '"${session.notes}"',
                        style: context.theme.typography.body.sm.copyWith(
                          color: colors.foreground,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (done && (session.notes == null || session.notes!.isEmpty))
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'HLV chưa ghi chú cho buổi này.',
                  textAlign: TextAlign.center,
                  style: context.theme.typography.body.sm.copyWith(color: colors.mutedForeground),
                ),
              ),
            // Upcoming: block summary
            if (!done && (session.blocks ?? []).isNotEmpty)
              FCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 10,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'GIÁO ÁN DỰ KIẾN',
                          style: context.theme.typography.body.xs.copyWith(
                            color: colors.mutedForeground,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.7,
                          ),
                        ),
                        Text(
                          "$totalDur′",
                          style: context.theme.typography.body.xs.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    for (final block in session.blocks!)
                      Row(
                        spacing: 8,
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(
                              color: _blockColor(block.type),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              block.name,
                              style: context.theme.typography.body.xs.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Text(
                            "${block.duration}′",
                            style: context.theme.typography.body.xs.copyWith(color: colors.mutedForeground),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            if (!done && (session.blocks == null || session.blocks!.isEmpty))
              FCard(
                child: Text(
                  'Freestyle session. HLV sẽ điều chỉnh tại sân.',
                  style: context.theme.typography.body.sm.copyWith(color: colors.mutedForeground),
                ),
              ),
            // Payment CTA
            if (done && !session.paid)
              FButton(
                onPress: () {},
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 8,
                  children: [
                    const Icon(FLucideIcons.wallet, size: 16),
                    Text('Thanh toán ${course.pricePerSession}k VND'),
                  ],
                ),
              ),
            // View full detail
            FButton(
              variant: .secondary,
              onPress: () => Navigator.of(context).pop(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 8,
                children: [
                  const Text('Xem chi tiết buổi'),
                  const Icon(FLucideIcons.forward, size: 13),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared small widgets ─────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          title,
          style: context.theme.typography.body.lg.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            height: 1,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: context.theme.typography.body.xs.copyWith(
              color: colors.mutedForeground,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;
  final Color color;
  final double size;

  const _Avatar({required this.initials, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontFamily: context.theme.typography.body.xs.fontFamily,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final double rating;
  final int reviewCount;

  const _RatingBadge({required this.rating, required this.reviewCount});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: 2,
      children: [
        Row(
          spacing: 3,
          children: [
            const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
            Text(
              rating.toStringAsFixed(1),
              style: context.theme.typography.body.sm.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        Text(
          '($reviewCount)',
          style: context.theme.typography.body.xs.copyWith(
            color: context.theme.colors.mutedForeground,
          ),
        ),
      ],
    );
  }
}

class _CourseTypeBadge extends StatelessWidget {
  final _CourseType type;

  const _CourseTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (type) {
      _CourseType.package => ('Gói', pbBlue.withValues(alpha: 0.12), pbBlue),
      _CourseType.retainer => ('Retainer', pbGreen.withValues(alpha: 0.15), pbGreen),
      _CourseType.group => ('Nhóm', context.theme.colors.secondary, context.theme.colors.mutedForeground),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: context.theme.typography.body.xs.copyWith(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;

  const _StatusChip({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: context.theme.typography.body.xs.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _StatusChipForSession extends StatelessWidget {
  final _SessionStatus status;
  final bool paid;

  const _StatusChipForSession({required this.status, required this.paid});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return switch ((status, paid)) {
      (_SessionStatus.done, true) => _StatusChip(label: 'Đã xong · Đã trả', color: const Color(0xFF3F7E4B), bg: const Color(0xFFDDF0E2)),
      (_SessionStatus.done, false) => _StatusChip(label: 'Đã xong · Chưa trả', color: colors.primary, bg: colors.primary.withValues(alpha: 0.1)),
      (_SessionStatus.upcoming, _) => _StatusChip(label: 'Sắp diễn ra', color: pbBlue, bg: pbBlue.withValues(alpha: 0.12)),
      (_SessionStatus.cancelled, _) => _StatusChip(label: 'Đã hủy', color: colors.mutedForeground, bg: colors.muted),
    };
  }
}
