import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/auth_controller.dart';
import '../../core/model/lobby.dart';
import '../../core/model/lobby_homeground.dart';

part 'lobby_detail_controller.g.dart';

class LobbyDetailInfo {
  final Lobby lobby;

  /// Ordered — the first entry is primary. Empty for a lobby with no
  /// homegrounds set.
  final List<LobbyHomeground> homeGrounds;

  const LobbyDetailInfo({required this.lobby, this.homeGrounds = const []});

  String? get homeGroundName =>
      homeGrounds.isEmpty ? null : homeGrounds.first.name;

  int get extraHomeGroundCount =>
      homeGrounds.length > 1 ? homeGrounds.length - 1 : 0;
}

@riverpod
class LobbyDetailController extends _$LobbyDetailController {
  @override
  Future<LobbyDetailInfo> build(String lobbyId) async {
    final supabase = Supabase.instance.client;

    final row = await supabase
        .from('lobby')
        .select(
          '*, lobby_homeground(location_id, is_primary, created_at, location(name))',
        )
        .eq('id', lobbyId)
        .single()
        .timeout(const Duration(seconds: 5));

    final data = Map<String, dynamic>.from(row as Map)
      ..remove('lobby_homeground');
    final ghRows = ((row['lobby_homeground'] as List?) ?? [])
        .cast<Map<String, dynamic>>()
        .toList()
      ..sort((a, b) {
        if (a['is_primary'] == true) return -1;
        if (b['is_primary'] == true) return 1;
        return (a['created_at'] as String? ?? '').compareTo(
          b['created_at'] as String? ?? '',
        );
      });
    final homeGrounds = [
      for (final g in ghRows)
        LobbyHomeground(
          id: g['location_id'] as String,
          name: (g['location'] as Map?)?['name'] as String? ?? '',
          isPrimary: g['is_primary'] as bool? ?? false,
        ),
    ];
    data['home_ground_ids'] = [for (final h in homeGrounds) h.id];
    final lobby = Lobby.fromJson(data);
    return LobbyDetailInfo(lobby: lobby, homeGrounds: homeGrounds);
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
