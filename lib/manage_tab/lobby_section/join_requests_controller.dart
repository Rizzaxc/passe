import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'join_requests_controller.g.dart';

class JoinRequest {
  final String id;
  final String initiatorUserId;
  final String username;
  final String tagNumber;

  const JoinRequest({
    required this.id,
    required this.initiatorUserId,
    required this.username,
    required this.tagNumber,
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
            'id, initiator_user_id, user!lobby_befriend_record_initiator_user_id_fkey(username, tag_number)')
        .eq('target_lobby_id', lobbyId)
        .eq('interaction_type', 'request')
        .eq('status', 'pending')
        .timeout(const Duration(seconds: 5));

    return (response as List).map((row) {
      final u = row['user'] as Map<String, dynamic>;
      return JoinRequest(
        id: row['id'] as String,
        initiatorUserId: row['initiator_user_id'] as String,
        username: u['username'] as String,
        tagNumber: u['tag_number'] as String,
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
