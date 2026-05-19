import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../ui/calendar.dart';
import '../../ui/theme.dart';

class ScheduleSection extends StatefulWidget {
  const ScheduleSection({super.key});

  @override
  State<ScheduleSection> createState() => _ScheduleSectionState();
}

class _ScheduleSectionState extends State<ScheduleSection> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final breakpoints = context.theme.breakpoints;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isPhone = screenWidth < breakpoints.sm;
    final daysToShow = isPhone ? 5 : 7;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          PCalendar(
            start: yesterday,
            daysToShow: daysToShow,
            selectedDate: _selectedDate,
            onDateSelected: (date) => setState(() => _selectedDate = date),
          ),
          const SizedBox(height: 8),
          _ScheduleBody(selectedDate: _selectedDate),
        ],
      ),
    );
  }
}

// ─── Mock event data ─────────────────────────────────────────────────────────

class _ScheduleEvent {
  final String time;
  final String date;
  final String title;
  final String meta;
  final _EventTone tone;

  const _ScheduleEvent({
    required this.time,
    required this.date,
    required this.title,
    required this.meta,
    required this.tone,
  });
}

enum _EventTone { sport, coach }

final _mockEventsToday = [
  _ScheduleEvent(
    time: '18:00',
    date: DateFormat('d/M').format(DateTime.now()),
    title: 'Chơi cầu lông cùng CLB Bách Khoa',
    meta: 'NTĐ Bách Khoa · 4/8 người',
    tone: _EventTone.sport,
  ),
];

final _mockEventsTomorrow = [
  _ScheduleEvent(
    time: '07:30',
    date: DateFormat('d/M').format(DateTime.now().add(const Duration(days: 1))),
    title: 'Buổi 3/10 — HLV Hữu Thắng',
    meta: 'Khoá Smash cơ bản · NTĐ Bách Khoa',
    tone: _EventTone.coach,
  ),
  _ScheduleEvent(
    time: '20:00',
    date: DateFormat('d/M').format(DateTime.now().add(const Duration(days: 1))),
    title: 'Thách đấu — Vĩnh Phú Smash',
    meta: 'NTĐ Vĩnh Phú · TvT 5v5',
    tone: _EventTone.sport,
  ),
];

// ─── Schedule body ────────────────────────────────────────────────────────────

class _ScheduleBody extends StatelessWidget {
  final DateTime selectedDate;

  const _ScheduleBody({required this.selectedDate});

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final isToday = _isSameDay(selectedDate, now);
    final isTomorrow = _isSameDay(selectedDate, tomorrow);

    // Determine events to show for selected date
    List<_ScheduleEvent> events;
    if (isToday) {
      events = _mockEventsToday;
    } else if (isTomorrow) {
      events = _mockEventsTomorrow;
    } else {
      events = [];
    }

    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
        child: Column(
          children: [
            Icon(FIcons.calendar, size: 48, color: context.theme.colors.mutedForeground),
            const SizedBox(height: 12),
            Text(
              'manageTab.schedule.stub'.tr(),
              style: context.theme.typography.sm.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          _SectionLabel(
            label: isToday
                ? 'manageTab.schedule.today'.tr()
                : isTomorrow
                    ? 'manageTab.schedule.tomorrow'.tr()
                    : DateFormat.yMMMMd().format(selectedDate),
          ),
          ...events.map((ev) => _EventCard(event: ev)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontFamily: context.theme.typography.xs.fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: context.theme.colors.mutedForeground,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final _ScheduleEvent event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final accent = event.tone == _EventTone.sport ? colors.primary : pbBlue;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.border),
        borderRadius: context.theme.style.borderRadius.md,
        boxShadow: context.theme.style.shadow,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left: time + date
            Container(
              width: 64,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: colors.border)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    event.time,
                    style: TextStyle(
                      fontFamily: context.theme.typography.xl.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: accent,
                      letterSpacing: -0.3,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.date,
                    style: TextStyle(
                      fontFamily: context.theme.typography.xs.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.mutedForeground,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),

            // Right: title + meta
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 4,
                  children: [
                    Text(
                      event.title,
                      style: context.theme.typography.sm.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      event.meta,
                      style: context.theme.typography.xs.copyWith(
                        color: colors.mutedForeground,
                        height: 1.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
