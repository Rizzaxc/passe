import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'match.dart';

part 'match_history_controller.g.dart';

/// Played-match history for a lobby — wins, losses, practice sessions.
///
/// Backed by `lobby_match` via the `lobby_match_history_data` RPC,
/// which resolves the opponent lobby name, MVP username and current
/// member usernames in one round-trip.
@riverpod
class LobbyMatchHistoryController extends _$LobbyMatchHistoryController {
  final supabase = Supabase.instance.client;

  @override
  Future<List<LobbyMatch>> build(String lobbyId) async {
    final response = await supabase
        .rpc('lobby_match_history_data', params: {'p_lobby_id': lobbyId})
        .timeout(const Duration(seconds: 5));

    final rows = (response as List).cast<Map<String, dynamic>>();
    return rows.map(_rowToMatch).toList();
  }

  LobbyMatch _rowToMatch(Map<String, dynamic> row) {
    final playedAt = DateTime.parse(row['played_at'] as String).toLocal();

    final rawSets = row['sets'];
    List<(int, int)>? sets;
    if (rawSets is List) {
      sets = rawSets
          .map<(int, int)>((s) => (
                ((s as List)[0] as num).toInt(),
                (s[1] as num).toInt(),
              ))
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
    );
  }

  LobbyMatchResult _parseResult(String db) => switch (db) {
        'win' => LobbyMatchResult.win,
        'loss' => LobbyMatchResult.loss,
        'draw' => LobbyMatchResult.draw,
        'practice' => LobbyMatchResult.practice,
        _ => throw StateError('Unknown lobby_match_result: $db'),
      };

  static const _weekdayShort = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  String _formatDate(DateTime t) {
    final wd = _weekdayShort[t.weekday - 1];
    return '$wd, ${t.day}/${t.month}';
  }

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';
}
