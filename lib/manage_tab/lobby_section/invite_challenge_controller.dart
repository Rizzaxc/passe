import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'invite_challenge_controller.g.dart';

/// Send a challenge invite from one lobby to another.
///
/// TODO(challenger-system): the `lobby_challenge` table hasn't been
/// designed yet (see CLAUDE.md ▸ Challenger System). Today this is a
/// no-op so the empty-hero CTA flow runs end-to-end. Once the table
/// + handshake RPC land, wire the insert here.
@riverpod
class InviteChallengeController extends _$InviteChallengeController {
  @override
  bool build(String initiatorLobbyId) => false; // in-flight flag

  Future<void> invite({
    required String targetSearchId,
    DateTime? proposedAt,
    String? note,
  }) async {
    state = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    } finally {
      state = false;
    }
  }
}
