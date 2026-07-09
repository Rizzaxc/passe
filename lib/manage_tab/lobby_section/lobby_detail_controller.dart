import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/auth_controller.dart';
import '../../core/model/lobby.dart';

part 'lobby_detail_controller.g.dart';

class LobbyDetailInfo {
  final Lobby lobby;
  final String? homeGroundName;

  const LobbyDetailInfo({required this.lobby, this.homeGroundName});
}

@riverpod
class LobbyDetailController extends _$LobbyDetailController {
  @override
  Future<LobbyDetailInfo> build(String lobbyId) async {
    final supabase = Supabase.instance.client;

    final row = await supabase
        .from('lobby')
        .select('*, location(name)')
        .eq('id', lobbyId)
        .single()
        .timeout(const Duration(seconds: 5));

    final data = Map<String, dynamic>.from(row as Map)..remove('location');
    final lobby = Lobby.fromJson(data);
    final locName = (row['location'] as Map?)?['name'] as String?;
    return LobbyDetailInfo(lobby: lobby, homeGroundName: locName);
  }
}

/// The current user's standing in one lobby. `canManage` covers everything
/// a captain does except kicking members and editing lobby info (those stay
/// [isCaptain]-only — see `schema/lobby_coordinator_role.sql`).
class LobbyPermission {
  final bool isCaptain;
  final bool isCoordinator;

  const LobbyPermission({required this.isCaptain, required this.isCoordinator});

  bool get canManage => isCaptain || isCoordinator;

  static const none = LobbyPermission(isCaptain: false, isCoordinator: false);
}

@riverpod
Future<LobbyPermission> myLobbyPermission(Ref ref, String lobbyId) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return LobbyPermission.none;

  final row = await Supabase.instance.client
      .from('lobby')
      .select('captain_id, lobby_member!inner(role)')
      .eq('id', lobbyId)
      .eq('lobby_member.user_id', userId)
      .maybeSingle()
      .timeout(const Duration(seconds: 5));

  if (row == null) return LobbyPermission.none;

  final isCaptain = row['captain_id'] == userId;
  final memberRows = row['lobby_member'] as List?;
  final role = (memberRows != null && memberRows.isNotEmpty)
      ? LobbyMemberRole.fromValue(memberRows.first['role'] as String?)
      : LobbyMemberRole.member;

  return LobbyPermission(
    isCaptain: isCaptain,
    isCoordinator: role == LobbyMemberRole.coordinator,
  );
}
