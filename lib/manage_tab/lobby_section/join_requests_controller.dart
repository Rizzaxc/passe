import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'members/controller.dart';

part 'join_requests_controller.g.dart';

class JoinRequest {
  final String id;
  final String initiatorUserId;
  final String username;
  final String tagNumber;
  final String? generatedAvatar;

  const JoinRequest({
    required this.id,
    required this.initiatorUserId,
    required this.username,
    required this.tagNumber,
    this.generatedAvatar,
  });
}

@riverpod
class JoinRequestsController extends _$JoinRequestsController {
  final supabase = Supabase.instance.client;

  @override
  Future<List<JoinRequest>> build(String lobbyId) async {
    final response = await supabase
        .from('lobby_befriend_record')
        .select(
            'id, initiator_user_id, user!lobby_befriend_record_initiator_user_id_fkey(username, tag_number, details)')
        .eq('target_lobby_id', lobbyId)
        .eq('interaction_type', 'request')
        .eq('status', 'pending')
        .timeout(const Duration(seconds: 5));

    return (response as List).map((row) {
      final u = row['user'] as Map<String, dynamic>;
      final details = u['details'] as Map<String, dynamic>?;
      return JoinRequest(
        id: row['id'] as String,
        initiatorUserId: row['initiator_user_id'] as String,
        username: u['username'] as String,
        tagNumber: u['tag_number'] as String,
        generatedAvatar: details?['generatedAvatar'] as String?,
      );
    }).toList();
  }

  Future<void> accept(String recordId) async {
    await supabase
        .from('lobby_befriend_record')
        .update({'status': 'accepted'})
        .eq('id', recordId)
        .timeout(const Duration(seconds: 5));
    ref.invalidateSelf();
  }

  Future<void> decline(String recordId) async {
    await supabase
        .from('lobby_befriend_record')
        .update({'status': 'declined'})
        .eq('id', recordId)
        .timeout(const Duration(seconds: 5));
    ref.invalidateSelf();
  }
}

/// Cheap status-only read for the notification card's inline Accept/Reject —
/// avoids pulling the full pending-request list just to know whether this
/// one record still needs a decision. Mirrors `lobbyInviteStatus`.
@riverpod
Future<String?> joinRequestStatus(Ref ref, String recordId) async {
  final row = await Supabase.instance.client
      .from('lobby_befriend_record')
      .select('status')
      .eq('id', recordId)
      .maybeSingle()
      .timeout(const Duration(seconds: 5));
  return row?['status'] as String?;
}

/// Accept/decline a lobby join request. Shared by the notification card's
/// inline buttons and [JoinRequestsController] (the "Manage Requests" sheet).
///
/// `keepAlive: true` — nothing ever watches this controller's (trivial void)
/// state, only its `.notifier` for `respond()`, so a plain autoDispose
/// provider gets disposed the instant the `ref.read` call returns (no
/// listeners) — then `respond()`'s own `ref.invalidate(...)` throws after its
/// `await` gap because its own `ref` is already dead. Mirrors
/// `LobbyInviteResponseController`.
@Riverpod(keepAlive: true)
class JoinRequestResponseController extends _$JoinRequestResponseController {
  final supabase = Supabase.instance.client;

  @override
  void build() {}

  Future<void> respond(
    String recordId, {
    required bool accept,
    String? lobbyId,
  }) async {
    await supabase
        .from('lobby_befriend_record')
        .update({'status': accept ? 'accepted' : 'declined'})
        .eq('id', recordId)
        .timeout(const Duration(seconds: 5));
    ref.invalidate(joinRequestStatusProvider(recordId));
    if (lobbyId != null) {
      ref.invalidate(joinRequestsControllerProvider(lobbyId));
      // Membership itself is added server-side by the accept trigger.
      if (accept) ref.invalidate(lobbyMembersControllerProvider(lobbyId));
    }
  }
}
