import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../feed/lobby_controller.dart';
import 'match.dart';
import 'match_history_controller.dart';

part 'record_match_controller.g.dart';

/// Records a played match into `lobby_match`. Captain-only (RLS: "Captain can
/// record matches for their lobby"). v1 records against a free-text opponent
/// (`opponent_lobby_id` stays null, so the referee-required constraint doesn't
/// apply); linking to an opponent lobby + referee booking arrives with the
/// challenge handshake.
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
        'result': result.name, // win / loss / practice
        if (!isPractice && sets != null && sets.isNotEmpty)
          'sets': sets.map((s) => [s.$1, s.$2]).toList(),
        'mvp_user_id': ?mvpUserId,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        'venue_label': venue.trim(),
        'played_at': (playedAt ?? DateTime.now()).toUtc().toIso8601String(),
      }).timeout(const Duration(seconds: 5));

      ref.invalidate(lobbyMatchHistoryControllerProvider(lobbyId));
      // MMR is trigger-recomputed off lobby_match; refresh the list cards.
      ref.invalidate(userLobbiesControllerProvider);
    } finally {
      state = false;
    }
  }
}
