import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'schedule_activity_controller.g.dart';

/// Captain-side "schedule a play session" mutation for a lobby.
///
/// TODO(activity-schedule): currently a no-op so the empty-hero CTA
/// completes its flow without persisting. Wire to a Supabase insert
/// into `activity` (lobby_id, sport_id, start_time, end_time) once
/// the captain-only RLS policy lands.
@riverpod
class ScheduleActivityController extends _$ScheduleActivityController {
  @override
  bool build(String lobbyId) => false; // in-flight flag

  Future<void> schedule({
    required DateTime start,
    required DateTime end,
  }) async {
    state = true;
    try {
      // No-op for now. Real call:
      //   await supabase.from('activity').insert({...});
      await Future<void>.delayed(const Duration(milliseconds: 300));
    } finally {
      state = false;
    }
  }
}
