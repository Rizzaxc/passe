import 'dart:math' show min;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../router.dart';
import '../../ui/main.dart';
import 'controller.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

enum _ViewMode { timeline, cards }

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _fmtTime(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

void _openActivity(BuildContext context, ScheduleEvent event) {
  final lobbyId = event.lobbyId;
  if (lobbyId == null) return;
  LobbyDetailRoute(
    id: lobbyId,
    tab: event.isCompletedAt(DateTime.now()) ? 2 : 1,
    highlightActivityId: event.activityId,
  ).go(context);
}

// Card-mode window: yesterday → max(today+4, this week's Sunday).
//
// Yesterday is included for short-term context (just-passed events);
// the end always extends through the current week's weekend so the
// user can plan for it from any weekday, clamped to a 5-day minimum
// forward window so it doesn't shrink late in the week. e.g.:
//   Mon → Sun         (8 days; Sun yesterday + Mon…Sun)
//   Wed → Sun         (6 days)
//   Fri → next Tue    (6 days, last weekend already inside)
//   Sun → next Thu    (6 days)
List<DateTime> get _cardRange {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  // weekday: Mon = 1 … Sun = 7. Days until (or to) Sunday of this week.
  final daysToSunday = (7 - today.weekday) % 7;
  final thisWeekSunday = today.add(Duration(days: daysToSunday));
  final minEnd = today.add(const Duration(days: 4));
  final end = minEnd.isAfter(thisWeekSunday) ? minEnd : thisWeekSunday;
  final totalDays = end.difference(yesterday).inDays + 1;
  return List.generate(totalDays, (i) => yesterday.add(Duration(days: i)));
}

String _dayLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final diff = target.difference(today).inDays;
  return switch (diff) {
    -1 => 'Hôm qua',
    0 => 'Hôm nay',
    1 => 'Ngày mai',
    _ => const [
      'Chủ nhật',
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
    ][date.weekday % 7],
  };
}

// ─── Root widget ──────────────────────────────────────────────────────────────

class ScheduleSection extends ConsumerStatefulWidget {
  const ScheduleSection({super.key});

  @override
  ConsumerState<ScheduleSection> createState() => _ScheduleSectionState();
}

class _ScheduleSectionState extends ConsumerState<ScheduleSection> {
  DateTime _selectedDate = DateTime.now();
  _ViewMode _viewMode = _ViewMode.timeline;
  final ScrollController _scrollCtrl = ScrollController();
  bool _needsScrollToNow = true;

  /// Events keyed by local date, from the latest provider value.
  Map<DateTime, List<ScheduleEvent>> _eventsByDate = const {};

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  List<ScheduleEvent> _eventsFor(DateTime date) =>
      _eventsByDate[DateTime(date.year, date.month, date.day)] ?? const [];

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Hour at which the time grid starts; -1 = whole day is empty.
  int _gridStartHour(List<ScheduleEvent> events, bool isToday) {
    if (events.isEmpty) return -1;
    int boundaryHour = events.map((e) => e.start.hour).reduce(min);
    if (isToday) boundaryHour = min(boundaryHour, TimeOfDay.now().hour);
    return boundaryHour.clamp(0, 23);
  }

  /// True end of the empty leading range shown in collapsed/empty labels.
  String _emptyRangeEnd(List<ScheduleEvent> events) {
    if (events.isEmpty) return '24:00';
    final first = events.reduce(
      (a, b) =>
          (a.start.hour * 60 + a.start.minute) <=
              (b.start.hour * 60 + b.start.minute)
          ? a
          : b,
    );
    return _fmtTime(first.start);
  }

  void _switchMode(_ViewMode m) {
    setState(() {
      _viewMode = m;
      _needsScrollToNow = m == _ViewMode.timeline;
    });
    if (_scrollCtrl.hasClients) _scrollCtrl.jumpTo(0);
  }

  void _maybeScrollToNow(int startHour, bool isToday) {
    if (!_needsScrollToNow ||
        _viewMode != _ViewMode.timeline ||
        !isToday ||
        startHour < 0) {
      return;
    }

    _needsScrollToNow = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollCtrl.hasClients) return;

      final now = DateTime.now();
      final minutesFromGridStart = (now.hour - startHour) * 60 + now.minute;
      final nowOffset = minutesFromGridStart * _TimeGrid.hourHeight / 60;
      final position = _scrollCtrl.position;
      // Keep a little context above the red current-time indicator instead
      // of pinning it flush against the viewport's top edge.
      final target = (nowOffset - position.viewportDimension * 0.2).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      _scrollCtrl.jumpTo(target);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Surface load errors but keep the calendar usable.
    ref.listen(scheduleEventsProvider, (_, next) {
      if (next is AsyncError && context.mounted) {
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.circleX),
          variant: .destructive,
          title: Text('error'.tr()),
          description: Text('errorGeneric'.tr()),
          alignment: .bottomCenter,
        );
      }
    });
    _eventsByDate = ref.watch(scheduleEventsProvider).value ?? const {};

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isPhone = screenWidth < context.theme.breakpoints.sm;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final events = _eventsFor(_selectedDate);
    final isToday = _isSameDay(_selectedDate, DateTime.now());
    final startHour = _gridStartHour(events, isToday);
    final rangeEnd = _emptyRangeEnd(events);
    _maybeScrollToNow(startHour, isToday);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Section header with view toggle as suffix ────────────────
        PSectionHeader(
          title: 'manageTab.schedule.title'.tr(),
          suffix: PPillToggle<_ViewMode>(
            value: _viewMode,
            options: const [
              PPillOption(value: _ViewMode.timeline, icon: FLucideIcons.clock),
              PPillOption(
                value: _ViewMode.cards,
                icon: FLucideIcons.layoutList,
              ),
            ],
            onChanged: _switchMode,
          ),
        ),

        // ── Date strip — only in timeline mode ───────────────────────
        if (_viewMode == _ViewMode.timeline)
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 10),
            child: PCalendar(
              start: yesterday,
              daysToShow: isPhone ? 5 : 7,
              selectedDate: _selectedDate,
              onDateSelected: (date) {
                setState(() {
                  _selectedDate = date;
                  _needsScrollToNow = _isSameDay(date, DateTime.now());
                });
                if (_scrollCtrl.hasClients) _scrollCtrl.jumpTo(0);
              },
            ),
          )
        else
          const SizedBox(height: 12),

        // ── Scrollable body ───────────────────────────────────────────
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(scheduleEventsProvider);
              await ref.read(scheduleEventsProvider.future);
            },
            child: _viewMode == _ViewMode.timeline && startHour < 0
                ? LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      controller: _scrollCtrl,
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: const _EmptyDayCard(),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    controller: _scrollCtrl,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 40),
                    child: _viewMode == _ViewMode.cards
                        ? _MultiDayCardView(eventsFor: _eventsFor)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (startHour > 0) ...[
                                _CollapsedBlock(from: '00:00', to: rangeEnd),
                                const SizedBox(height: 16),
                              ],
                              _TimeGrid(
                                events: events,
                                startHour: startHour,
                                showNowIndicator: isToday,
                              ),
                            ],
                          ),
                  ),
          ),
        ),
      ],
    );
  }
}

// ─── Multi-day card list ──────────────────────────────────────────────────────

class _MultiDayCardView extends StatelessWidget {
  final List<ScheduleEvent> Function(DateTime) eventsFor;

  const _MultiDayCardView({required this.eventsFor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final day in _cardRange)
          _DaySection(date: day, events: eventsFor(day)),
      ],
    );
  }
}

class _DaySection extends StatelessWidget {
  final DateTime date;
  final List<ScheduleEvent> events;

  const _DaySection({required this.date, required this.events});

  bool get _isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Day header
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _dayLabel(date),
                style: context.theme.typography.body.sm.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _isToday ? colors.primary : colors.foreground,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${date.day}/${date.month}',
                style: context.theme.typography.body.xs.copyWith(
                  color: colors.mutedForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Events or empty line
          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Text(
                'manageTab.schedule.noEvents'.tr(),
                style: context.theme.typography.body.xs.copyWith(
                  color: colors.mutedForeground.withValues(alpha: 0.55),
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            Column(
              spacing: 8,
              children: [for (final event in events) _EventRow(event: event)],
            ),
        ],
      ),
    );
  }
}

// ─── Collapsed / empty blocks ─────────────────────────────────────────────────

class _EmptyDayCard extends StatelessWidget {
  const _EmptyDayCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            FLucideIcons.calendarDays,
            size: 32,
            color: colors.mutedForeground.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'manageTab.schedule.noEvents'.tr(),
            style: context.theme.typography.body.sm.copyWith(
              color: colors.mutedForeground,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '00:00 – 24:00',
            style: context.theme.typography.body.xs.copyWith(
              color: colors.mutedForeground.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollapsedBlock extends StatelessWidget {
  final String from;
  final String to;

  const _CollapsedBlock({required this.from, required this.to});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final style = TextStyle(
      fontFamily: context.theme.typography.body.xs.fontFamily,
      fontSize: 11,
      color: colors.mutedForeground.withValues(alpha: 0.6),
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: colors.muted.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: colors.border.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$from – $to',
            style: style.copyWith(fontWeight: FontWeight.w600),
          ),
          Text('  ·  ${'manageTab.schedule.noEvents'.tr()}', style: style),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              color: colors.border.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Event row (card view) ────────────────────────────────────────────────────

class _EventRow extends StatelessWidget {
  final ScheduleEvent event;

  const _EventRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final accent = event.tone == ScheduleEventTone.sport
        ? colors.primary
        : pbBlue;

    return FTappable(
      onPress: event.lobbyId == null
          ? null
          : () => _openActivity(context, event),
      child: Container(
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
              // Left: start + end time (equal prominence)
              Container(
                width: 68,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border(right: BorderSide(color: colors.border)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 3,
                  children: [
                    _TimeLabel(time: _fmtTime(event.start), color: accent),
                    // En-dash separator — sits between the two times to
                    // signal the range visually, sized smaller than the
                    // numerals so they remain the focal points.
                    Text(
                      '–',
                      style: TextStyle(
                        fontFamily: context.theme.typography.body.lg.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: accent.withValues(alpha: 0.55),
                        height: 1,
                      ),
                    ),
                    _TimeLabel(time: _fmtTime(event.end), color: accent),
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
                        style: context.theme.typography.body.sm.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        event.meta,
                        style: context.theme.typography.body.xs.copyWith(
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
      ),
    );
  }
}

class _TimeLabel extends StatelessWidget {
  final String time;
  final Color color;

  const _TimeLabel({required this.time, required this.color});

  @override
  Widget build(BuildContext context) {
    // Same size/weight/color for both start and end — they read as
    // peers (e.g. "18:00" / "20:00"), not a primary + caption.
    return Text(
      time,
      style: TextStyle(
        fontFamily: context.theme.typography.body.lg.fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.2,
        height: 1,
      ),
    );
  }
}

// ─── Time grid ────────────────────────────────────────────────────────────────

class _TimeGrid extends StatelessWidget {
  final List<ScheduleEvent> events;
  final int startHour;
  final bool showNowIndicator;

  static const double hourHeight = 54.0;
  static const double timeColumnWidth = 52.0;
  static const int _endHour = 24;

  const _TimeGrid({
    required this.events,
    required this.startHour,
    this.showNowIndicator = false,
  });

  double _offsetFor(TimeOfDay t) {
    final mins = (t.hour - startHour) * 60 + t.minute;
    return (mins * hourHeight / 60).clamp(
      0.0,
      (_endHour - startHour) * hourHeight,
    );
  }

  double _blockHeight(ScheduleEvent e) {
    final mins =
        (e.end.hour * 60 + e.end.minute) - (e.start.hour * 60 + e.start.minute);
    return (mins * hourHeight / 60).clamp(28.0, double.infinity);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final gridHeight = (_endHour - startHour) * hourHeight;
    final now = TimeOfDay.now();
    final nowOffset = _offsetFor(now);

    return SizedBox(
      height: gridHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Full-hour lines
          for (var h = startHour; h <= _endHour; h++)
            Positioned(
              top: (h - startHour) * hourHeight,
              left: 0,
              right: 0,
              child: Container(
                height: 1,
                color: colors.border.withValues(
                  alpha: h == startHour ? 0.7 : 0.4,
                ),
              ),
            ),

          // Half-hour lines
          for (var h = startHour; h < _endHour; h++)
            Positioned(
              top: (h - startHour) * hourHeight + hourHeight / 2,
              left: timeColumnWidth,
              right: 0,
              child: Container(
                height: 1,
                color: colors.border.withValues(alpha: 0.18),
              ),
            ),

          // Hour labels
          for (var h = startHour; h < _endHour; h++)
            Positioned(
              top: (h - startHour) * hourHeight - 8,
              left: 0,
              width: timeColumnWidth,
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Text(
                    '${h.toString().padLeft(2, '0')}:00',
                    style: TextStyle(
                      fontFamily: context.theme.typography.body.xs.fontFamily,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: colors.mutedForeground,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),

          // Event blocks
          for (final event in events)
            Positioned(
              top: _offsetFor(event.start),
              left: timeColumnWidth,
              right: 0,
              height: _blockHeight(event),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 1, 0, 1),
                child: _EventBlock(event: event),
              ),
            ),

          // Now indicator
          if (showNowIndicator) ...[
            Positioned(
              top: nowOffset - 4,
              left: timeColumnWidth - 4,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFDC143C),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: nowOffset,
              left: timeColumnWidth,
              right: 0,
              child: Container(height: 1.5, color: const Color(0xFFDC143C)),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Event block (timeline view) ──────────────────────────────────────────────

class _EventBlock extends StatelessWidget {
  final ScheduleEvent event;

  const _EventBlock({required this.event});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final accent = event.tone == ScheduleEventTone.sport
        ? colors.primary
        : pbBlue;

    return FTappable(
      onPress: event.lobbyId == null
          ? null
          : () => _openActivity(context, event),
      child: Container(
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(6),
          border: Border(left: BorderSide(color: accent, width: 3)),
        ),
        padding: const EdgeInsets.fromLTRB(8, 4, 6, 4),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_fmtTime(event.start)} – ${_fmtTime(event.end)}',
              style: TextStyle(
                fontFamily: context.theme.typography.body.xs.fontFamily,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: accent,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              event.title,
              style: context.theme.typography.body.xs.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.foreground,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              event.meta,
              style: context.theme.typography.body.xs.copyWith(
                color: colors.mutedForeground,
                fontSize: 10,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
