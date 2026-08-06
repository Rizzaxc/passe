import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/model/lobby.dart';

part 'controller.g.dart';

class LobbyMemberInfo {
  final String userId;
  final String username;
  final String tagNumber;
  final LobbyMemberRole role;
  final String? generatedAvatar;

  const LobbyMemberInfo({
    required this.userId,
    required this.username,
    required this.tagNumber,
    required this.role,
    this.generatedAvatar,
  });
}

@riverpod
class LobbyMembersController extends _$LobbyMembersController {
  final supabase = Supabase.instance.client;

  @override
  Future<List<LobbyMemberInfo>> build(String lobbyId) async {
    final response = await supabase
        .from('lobby_member')
        .select('user_id, role, user!inner(username, tag_number, details)')
        .eq('lobby_id', lobbyId)
        .timeout(const Duration(seconds: 5));

    return (response as List).map((row) {
      final u = row['user'] as Map<String, dynamic>;
      final details = u['details'] as Map<String, dynamic>?;
      return LobbyMemberInfo(
        userId: row['user_id'] as String,
        username: u['username'] as String,
        tagNumber: u['tag_number'] as String,
        role: LobbyMemberRole.fromValue(row['role'] as String?),
        generatedAvatar: details?['generatedAvatar'] as String?,
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

  /// Captain-only role grant/revoke, validated server-side by
  /// `set_lobby_member_role` (schema/lobby_coordinator_role.sql).
  Future<void> setRole(
    String lobbyId,
    String userId,
    LobbyMemberRole role,
  ) async {
    await supabase
        .rpc(
          'set_lobby_member_role',
          params: {
            'p_lobby_id': lobbyId,
            'p_member_user_id': userId,
            'p_role': role.value,
          },
        )
        .timeout(const Duration(seconds: 5));
    ref.invalidateSelf();
  }
}
