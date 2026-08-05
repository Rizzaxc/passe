import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../feed/lobby_controller.dart';
import 'match.dart';
import 'match_history_controller.dart';

part 'record_match_controller.g.dart';

/// Records a played match into `lobby_match`. Captain/coordinator-only (RLS:
/// "Captain or coordinator can record matches for their lobby"). Always
/// records against a free-text opponent — `opponent_lobby_id` stays null, so
/// the referee-required CHECK and the Elo-rating trigger (both keyed off
/// `opponent_lobby_id IS NOT NULL`) never apply here. A *linked* opponent +
/// referee + rating only happens through the challenge handshake's own path:
/// `record_challenge_match`, called by the referee from pro mode
/// (`professional/pro_mode/record_result_sheet.dart`), not this controller.
@riverpod
class RecordMatchController extends _$RecordMatchController {
  @override
  bool build(String lobbyId) => false; // in-flight flag

  Future<void> record({
    required String lobbyId,
    required LobbyMatchResult result,
    String? opponentName,
    List<(int us, int them)>? sets,
    String? mvpUserId,
    required String venue,
    String? note,
    DateTime? playedAt,
  }) async {
    state = true;
    try {
      final supabase = Supabase.instance.client;
      final isPractice = result == LobbyMatchResult.practice;

      await supabase.from('lobby_match').insert({
        'lobby_id': lobbyId,
        // NOT NULL short label shown in the result strip.
        'opponent_tag': isPractice
            ? 'Nội bộ'
            : (opponentName?.trim().isNotEmpty ?? false
                ? opponentName!.trim()
                : '—'),
        'result': result.name, // win / loss / draw / practice
        if (!isPractice && sets != null && sets.isNotEmpty)
          'sets': sets.map((s) => [s.$1, s.$2]).toList(),
        'mvp_user_id': ?mvpUserId,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        'venue_label': venue.trim(),
        'played_at': (playedAt ?? DateTime.now()).toUtc().toIso8601String(),
      }).timeout(const Duration(seconds: 5));

      ref.invalidate(lobbyMatchHistoryControllerProvider(lobbyId));
      // This free-text path never sets opponent_lobby_id, so it can't move
      // MMR (that only happens via the challenge path's Elo trigger) — this
      // just refreshes the list cards' next-activity/member-count display.
      ref.invalidate(userLobbiesControllerProvider);
    } finally {
      state = false;
    }
  }
}
