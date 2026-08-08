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
}
