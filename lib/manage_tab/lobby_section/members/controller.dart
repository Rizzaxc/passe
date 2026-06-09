import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'controller.g.dart';

class LobbyMemberInfo {
  final String userId;
  final String username;
  final String tagNumber;

  const LobbyMemberInfo({
    required this.userId,
    required this.username,
    required this.tagNumber,
  });
}

@riverpod
class LobbyMembersController extends _$LobbyMembersController {
  final supabase = Supabase.instance.client;

  @override
  Future<List<LobbyMemberInfo>> build(String lobbyId) async {
    final response = await supabase
        .from('lobby_member')
        .select('user_id, user!inner(username, tag_number)')
        .eq('lobby_id', lobbyId)
        .timeout(const Duration(seconds: 5));

    return (response as List).map((row) {
      final u = row['user'] as Map<String, dynamic>;
      return LobbyMemberInfo(
        userId: row['user_id'] as String,
        username: u['username'] as String,
        tagNumber: u['tag_number'] as String,
      );
    }).toList();
  }

  Future<void> kick(String lobbyId, String userId) async {
    await supabase
        .from('lobby_member')
        .delete()
        .eq('lobby_id', lobbyId)
        .eq('user_id', userId)
        .timeout(const Duration(seconds: 5));
    ref.invalidateSelf();
  }
}
