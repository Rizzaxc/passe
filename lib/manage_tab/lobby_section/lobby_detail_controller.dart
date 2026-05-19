import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
