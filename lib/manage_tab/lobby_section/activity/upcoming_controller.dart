import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/model/activity.dart';

part 'upcoming_controller.g.dart';

/// Next pinned activity for a lobby — `start_time > now`, soonest first.
///
/// The Activity tab's hero binds to this. When the controller returns
/// `null`, the hero falls back to its empty-state CTA.
@riverpod
class LobbyUpcomingActivityController extends _$LobbyUpcomingActivityController {
  final supabase = Supabase.instance.client;

  @override
  Future<Activity?> build(String lobbyId) async {
    final now = DateTime.now().toUtc();

    final response = await supabase
        .from('activity')
        .select()
        .eq('lobby_id', lobbyId)
        .gt('start_time', now.toIso8601String())
        .order('start_time', ascending: true)
        .limit(1)
        .timeout(const Duration(seconds: 5));

    final rows = response as List;
    if (rows.isEmpty) return null;
    return Activity.fromJson(rows.first as Map<String, dynamic>);
  }
}
