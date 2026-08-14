import 'package:flutter_test/flutter_test.dart';
import 'package:passe/manage_tab/schedule_section/controller.dart';

void main() {
  group('ScheduleEvent completion', () {
    final start = DateTime(2026, 8, 8, 18);
    final end = DateTime(2026, 8, 8, 20);
    final event = ScheduleEvent(
      activityId: 'activity-1',
      lobbyId: 'lobby-1',
      title: 'Đá bóng',
      meta: 'Sân A',
      tone: ScheduleEventTone.sport,
      startAt: start,
      endAt: end,
    );

    test('keeps an in-progress activity in Planner', () {
      expect(event.isCompletedAt(DateTime(2026, 8, 8, 19)), isFalse);
    });

    test('moves an activity to History at its end time', () {
      expect(event.isCompletedAt(end), isTrue);
      expect(event.isCompletedAt(DateTime(2026, 8, 8, 21)), isTrue);
    });

    test('treats a missing end time as completed once it starts', () {
      final eventWithoutEnd = ScheduleEvent(
        activityId: 'activity-2',
        title: 'Tập tự do',
        meta: '',
        tone: ScheduleEventTone.sport,
        startAt: start,
        endAt: null,
      );

      expect(eventWithoutEnd.isCompletedAt(start), isTrue);
    });
  });

  group('overlapping schedule event layout', () {
    ScheduleEvent event(String id, int startHour, int endHour) => ScheduleEvent(
      activityId: id,
      title: id,
      meta: '',
      tone: ScheduleEventTone.freeplay,
      startAt: DateTime(2026, 8, 8, startHour),
      endAt: DateTime(2026, 8, 8, endHour),
    );

    test('puts activities sharing a timeslot in separate columns', () {
      final layout = layoutOverlappingScheduleEvents([
        event('first', 18, 20),
        event('second', 18, 20),
      ]);

      expect(layout, hasLength(2));
      expect(layout.map((item) => item.column), [0, 1]);
      expect(layout.map((item) => item.columnCount), [2, 2]);
    });

    test('reuses a column when one activity ends as another starts', () {
      final layout = layoutOverlappingScheduleEvents([
        event('first', 18, 19),
        event('second', 19, 20),
      ]);

      expect(layout.map((item) => item.column), [0, 0]);
      expect(layout.map((item) => item.columnCount), [1, 1]);
    });
  });
}
