import 'package:flutter_test/flutter_test.dart';
import 'package:passe/freeplay/model.dart';
import 'package:passe/manage_tab/freeplay_section/schedule_controller.dart';
import 'package:passe/manage_tab/schedule_section/controller.dart';

void main() {
  FreeplayActivity activity(String id, DateTime start) => FreeplayActivity(
    id: id,
    hostId: 'host-1',
    hostName: 'Host',
    description: 'Buổi $id',
    startTime: start,
    endTime: start.add(const Duration(hours: 2)),
    venueName: 'Sân A',
    streetAddress: 'Địa chỉ A',
    capacity: 12,
    acceptedCount: 4,
    malePrice: 100000,
    femalePrice: 80000,
    recommendedSkills: const ['casual'],
  );

  test('keeps every Host activity when several share one timeslot', () {
    final start = DateTime(2026, 8, 15, 18);
    final grouped = groupHostScheduleEvents([
      activity('activity-1', start),
      activity('activity-2', start),
    ]);

    final events = grouped[DateTime(2026, 8, 15)]!;
    expect(events, hasLength(2));
    expect(events.map((event) => event.activityId), [
      'activity-1',
      'activity-2',
    ]);
    expect(
      events.every((event) => event.tone == ScheduleEventTone.freeplay),
      isTrue,
    );
  });
}
