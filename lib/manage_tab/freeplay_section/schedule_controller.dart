import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../freeplay/model.dart';
import '../../freeplay/repository.dart';
import '../schedule_section/controller.dart';

/// The Host's upcoming drop-ins, adapted to the shared Manage calendar model.
///
/// Unlike a player's schedule, a Host can publish several sessions at the
/// same time. Keep every activity in the date bucket; the calendar timeline
/// assigns overlapping entries to separate columns when it renders them.
final hostScheduleEventsProvider =
    FutureProvider.autoDispose<Map<DateTime, List<ScheduleEvent>>>((ref) async {
      final activities = await ref.watch(hostFreeplayProvider(false).future);
      return groupHostScheduleEvents(activities);
    });

Map<DateTime, List<ScheduleEvent>> groupHostScheduleEvents(
  Iterable<FreeplayActivity> activities,
) {
  final byDate = <DateTime, List<ScheduleEvent>>{};

  for (final activity in activities) {
    final start = activity.startTime;
    final key = DateTime(start.year, start.month, start.day);
    final description = activity.description.trim();
    final venue = activity.venueName.trim();
    final title = description.isNotEmpty
        ? description
        : venue.isNotEmpty
        ? venue
        : activity.hostName;

    (byDate[key] ??= []).add(
      ScheduleEvent(
        activityId: activity.id,
        title: title,
        meta: venue,
        tone: ScheduleEventTone.freeplay,
        startAt: start,
        endAt: activity.endTime,
      ),
    );
  }

  for (final events in byDate.values) {
    events.sort((a, b) {
      final byStart = a.startAt.compareTo(b.startAt);
      return byStart != 0 ? byStart : a.activityId.compareTo(b.activityId);
    });
  }

  return byDate;
}
