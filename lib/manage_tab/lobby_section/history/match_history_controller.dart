import 'package:easy_localization/easy_localization.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../activity/upcoming_controller.dart';
import 'match.dart';

part 'match_history_controller.g.dart';

/// Lobby history combines recorded matches with completed activities that do
/// not have a match record yet. The latter retain their post-session actions
/// without being incorrectly counted as competitive results.
///
/// Match details come from `lobby_match_history_data`; completed activities
/// use the member-visible `activity` rows. A matching `activity_id` is
/// de-duplicated in the client because challenge matches already render their
/// richer match record.
@riverpod
class LobbyMatchHistoryController extends _$LobbyMatchHistoryController {
  final supabase = Supabase.instance.client;

  @override
  Future<LobbyHistory> build(String lobbyId) async {
    final now = DateTime.now().toUtc();
    final responses = await Future.wait([
      supabase
          .rpc(
            'lobby_match_history_data',
            params: {'p_lobby_id': lobbyId, 'p_page_size': 100},
          )
          .timeout(const Duration(seconds: 5)),
      supabase
          .from('activity')
          .select(lobbyActivitySelect)
          .eq('lobby_id', lobbyId)
          .lte('start_time', now.toIso8601String())
          .order('start_time', ascending: false)
          .limit(100)
          .timeout(const Duration(seconds: 5)),
    ]);

    final matches = (responses[0] as List)
        .cast<Map<String, dynamic>>()
        .map(_rowToMatch)
        .toList();
    final recordedActivityIds = {
      for (final match in matches)
        if (match.activityId != null) match.activityId!,
    };
    final completedActivities = (responses[1] as List)
        .cast<Map<String, dynamic>>()
        .map((row) => _rowToPastActivity(row, lobbyId))
        .whereType<PastLobbyActivity>()
        .where((activity) => !recordedActivityIds.contains(activity.id))
        .toList();
    final entries = <LobbyHistoryEntry>[...matches, ...completedActivities]
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return LobbyHistory(entries);
  }

  LobbyMatch _rowToMatch(Map<String, dynamic> row) {
    final playedAt = DateTime.parse(row['played_at'] as String).toLocal();

    final rawSets = row['sets'];
    List<(int, int)>? sets;
    if (rawSets is List) {
      sets = rawSets
          .map<(int, int)>(
            (s) => (((s as List)[0] as num).toInt(), (s[1] as num).toInt()),
          )
          .toList();
    }

    return LobbyMatch(
      id: row['id'] as String,
      date: _formatDate(playedAt),
      when: (row['duration_label'] as String?) ?? _formatTime(playedAt),
      opponent: row['opponent_name'] as String?,
      opponentTag: row['opponent_tag'] as String,
      result: _parseResult(row['result'] as String),
      sets: sets,
      mvp: row['mvp_username'] as String?,
      venue: row['venue_label'] as String,
      members: ((row['member_usernames'] as List?) ?? const [])
          .map((e) => e as String)
          .toList(),
      note: row['note'] as String?,
      refereeBookingId: row['referee_booking_id'] as String?,
      refereeName: row['referee_name'] as String?,
      activityId: row['activity_id'] as String?,
      occurredAt: playedAt,
    );
  }

  PastLobbyActivity? _rowToPastActivity(
    Map<String, dynamic> row,
    String lobbyId,
  ) {
    final activity = UpcomingActivity.fromRow(row, lobbyId);
    final completedAt = activity.nextEnd ?? activity.nextStart;
    if (!completedAt.isBefore(DateTime.now())) return null;
    return PastLobbyActivity(activity);
  }

  LobbyMatchResult _parseResult(String db) => switch (db) {
    'win' => LobbyMatchResult.win,
    'loss' => LobbyMatchResult.loss,
    'draw' => LobbyMatchResult.draw,
    'practice' => LobbyMatchResult.practice,
    _ => throw StateError('Unknown lobby_match_result: $db'),
  };

  static List<String> get _weekdayShort => [
    'lobbyHub.schedule.weekdaysShort.monday'.tr(),
    'lobbyHub.schedule.weekdaysShort.tuesday'.tr(),
    'lobbyHub.schedule.weekdaysShort.wednesday'.tr(),
    'lobbyHub.schedule.weekdaysShort.thursday'.tr(),
    'lobbyHub.schedule.weekdaysShort.friday'.tr(),
    'lobbyHub.schedule.weekdaysShort.saturday'.tr(),
    'lobbyHub.schedule.weekdaysShort.sunday'.tr(),
  ];

  String _formatDate(DateTime t) {
    final wd = _weekdayShort[t.weekday - 1];
    return '$wd, ${t.day}/${t.month}';
  }

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';
}
