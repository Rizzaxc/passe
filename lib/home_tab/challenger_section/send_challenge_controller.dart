import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'send_challenge_controller.g.dart';

/// Sends a lobby-vs-lobby challenge from the user's "challenging as" context
/// lobby to a lobby they picked off the challenger feed.
///
/// Backed by the `send_challenge` RPC (schema/challenge_flow.sql). The
/// challenger does **not** propose a time or venue: the target published an
/// offer (when / where / cost per team) and this is a taker, so the RPC
/// snapshots that offer onto the challenge row. All the caller adds is an
/// optional note.
///
/// Lived in `manage_tab/lobby_section/invite_challenge_controller.dart` while a
/// lobby could also start a challenge by SearchID; that entry point is retired
/// (challenges start from Discover, against a lobby that actually opted in), so
/// this now sits with its only consumer.
@riverpod
class SendChallengeController extends _$SendChallengeController {
  late String _initiatorLobbyId;

  @override
  bool build(String initiatorLobbyId) {
    _initiatorLobbyId = initiatorLobbyId;
    return false; // in-flight flag
  }

  Future<void> send({required String targetLobbyId, String? note}) async {
    state = true;
    try {
      await Supabase.instance.client.rpc('send_challenge', params: {
        'p_initiator_lobby': _initiatorLobbyId,
        'p_target_lobby': targetLobbyId,
        'p_note': note,
      }).timeout(const Duration(seconds: 5));
    } finally {
      state = false;
    }
  }
}

/// Maps the `send_challenge` guard exceptions onto Vietnamese copy. The RPC
/// raises plain messages rather than error codes, so this matches on their
/// text; anything unrecognised falls back to the generic line.
String challengeErrorMessage(Object e) {
  final msg = e.toString();
  if (msg.contains('not open to challengers')) {
    return 'Lobby này không còn nhận thách đấu';
  }
  if (msg.contains('offer has expired')) return 'Lời mời đã hết hạn';
  if (msg.contains('sport mismatch')) return 'Hai lobby khác môn thể thao';
  if (msg.contains('already pending')) return 'Đã có lời thách đấu đang chờ';
  if (msg.contains('own lobby')) {
    return 'Không thể tự thách đấu lobby của mình';
  }
  if (msg.contains('not a manager')) {
    return 'Chỉ đội trưởng hoặc điều phối viên mới gửi được';
  }
  return 'Không thể gửi lời thách đấu';
}
