import 'package:flutter/material.dart' show TimeOfDay;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'controller.g.dart';

enum ScheduleEventTone { sport, coach, freeplay }

/// A single calendar entry rendered by the schedule grid/card views.
class ScheduleEvent {
  final String activityId;
  final String? lobbyId;
  final String title;
  final String meta;
  final ScheduleEventTone tone;
  final DateTime startAt;
  final DateTime? endAt;

  const ScheduleEvent({
    required this.activityId,
    this.lobbyId,
    required this.title,
    required this.meta,
    required this.tone,
    required this.startAt,
    required this.endAt,
  });

  TimeOfDay get start => TimeOfDay.fromDateTime(startAt);
  TimeOfDay get end =>
      TimeOfDay.fromDateTime(endAt ?? startAt.add(const Duration(hours: 1)));

  /// Completed activities belong in the lobby History tab; an activity that
  /// is still in progress remains in Planner until its actual end time.
  bool isCompletedAt(DateTime now) => !(endAt ?? startAt).isAfter(now);

  DateTime get effectiveEndAt => endAt ?? startAt.add(const Duration(hours: 1));
}

/// Horizontal placement for one event in a calendar overlap group.
class ScheduleEventLayout {
  final ScheduleEvent event;
  final int column;
  final int columnCount;

  const ScheduleEventLayout({
    required this.event,
    required this.column,
    required this.columnCount,
  });
}

/// Assigns overlapping events to side-by-side columns.
///
/// Events that only touch at an endpoint do not overlap. Every connected
/// overlap group uses a common [ScheduleEventLayout.columnCount], which keeps
/// column widths stable from the start to the end of that group.
List<ScheduleEventLayout> layoutOverlappingScheduleEvents(
  Iterable<ScheduleEvent> events,
) {
  final sorted = events.toList()
    ..sort((a, b) {
      final byStart = a.startAt.compareTo(b.startAt);
      if (byStart != 0) return byStart;
      final byEnd = b.effectiveEndAt.compareTo(a.effectiveEndAt);
      return byEnd != 0 ? byEnd : a.activityId.compareTo(b.activityId);
    });
  final result = <ScheduleEventLayout>[];
  var group = <ScheduleEvent>[];
  DateTime? groupEnd;

  void flushGroup() {
    if (group.isEmpty) return;
    final columnEnds = <DateTime>[];
    final placements = <(ScheduleEvent, int)>[];

    for (final event in group) {
      var column = columnEnds.indexWhere((end) => !event.startAt.isBefore(end));
      if (column == -1) {
        column = columnEnds.length;
        columnEnds.add(event.effectiveEndAt);
      } else {
        columnEnds[column] = event.effectiveEndAt;
      }
      placements.add((event, column));
    }

    for (final (event, column) in placements) {
      result.add(
        ScheduleEventLayout(
          event: event,
          column: column,
          columnCount: columnEnds.length,
        ),
      );
    }
    group = <ScheduleEvent>[];
    groupEnd = null;
  }

  for (final event in sorted) {
    if (groupEnd != null && !event.startAt.isBefore(groupEnd!)) flushGroup();
    group.add(event);
    if (groupEnd == null || event.effectiveEndAt.isAfter(groupEnd!)) {
      groupEnd = event.effectiveEndAt;
    }
  }
  flushGroup();
  return result;
}

/// The current user's activities (lobby sessions + coach bookings) for the
/// all sports, keyed by local date. Backed by the `my_schedule_data` RPC —
/// every row, including each occurrence of a recurring series, is its own
/// dated activity, so no client-side expansion is needed.
@riverpod
class ScheduleEvents extends _$ScheduleEvents {
  /// Days before today included for short-term context.
  static const _pastDays = 2;

  /// Days after today the window extends (covers the card view's range).
  static const _futureDays = 30;

  @override
  Future<Map<DateTime, List<ScheduleEvent>>> build() async {
    final now = DateTime.now();
    final from = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: _pastDays));
    final to = from.add(const Duration(days: _pastDays + _futureDays));

    final response = await Supabase.instance.client
        .rpc(
          'my_schedule_data',
          params: {
            'p_sport_id': null,
            'p_from': from.toUtc().toIso8601String(),
            'p_to': to.toUtc().toIso8601String(),
          },
        )
        .timeout(const Duration(seconds: 5));

    final activityIds = <String>{
      for (final raw in response as List)
        if (raw case {'id': final String id}) id,
    };
    final lobbyIdsByActivity = <String, String>{};
    if (activityIds.isNotEmpty) {
      final activityRows = await Supabase.instance.client
          .from('activity')
          .select('id, lobby_id')
          .inFilter('id', activityIds.toList())
          .timeout(const Duration(seconds: 5));
      for (final row in activityRows as List) {
        final activityId = row['id'] as String?;
        final lobbyId = row['lobby_id'] as String?;
        if (activityId != null && lobbyId != null) {
          lobbyIdsByActivity[activityId] = lobbyId;
        }
      }
    }

    final byDate = <DateTime, List<ScheduleEvent>>{};
    void put(DateTime date, ScheduleEvent ev) {
      final key = DateTime(date.year, date.month, date.day);
      (byDate[key] ??= []).add(ev);
    }

    for (final raw in response) {
      final row = raw;
      final activityId = row['id'] as String;
      final start = DateTime.parse(row['start_time'] as String).toLocal();
      final endStr = row['end_time'] as String?;
      final end = endStr != null ? DateTime.parse(endStr).toLocal() : null;

      final ev = ScheduleEvent(
        activityId: activityId,
        lobbyId: lobbyIdsByActivity[activityId],
        title: (row['title'] as String?) ?? '',
        meta: (row['meta'] as String?) ?? '',
        tone: switch (row['tone'] as String?) {
          'coach' => ScheduleEventTone.coach,
          'freeplay' => ScheduleEventTone.freeplay,
          _ => ScheduleEventTone.sport,
        },
        startAt: start,
        endAt: end,
      );

      // Recurring rows are real, independently-dated activity rows now
      // (each week is its own materialized row — see
      // schema/recurring_activity_series.sql), so every row — recurring or
      // not — takes this single path; there's no more client-side weekday
      // expansion of a single anchor row.
      if (!start.isBefore(from) && !start.isAfter(to)) put(start, ev);
    }

    int minutes(TimeOfDay t) => t.hour * 60 + t.minute;
    for (final list in byDate.values) {
      list.sort((a, b) => minutes(a.start).compareTo(minutes(b.start)));
    }
    return byDate;
  }
}
