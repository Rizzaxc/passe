import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/auth_controller.dart';

part 'has_lobby_state.g.dart';

/// Whether the signed-in user belongs to any lobby, in any sport. Read once
/// at cold start by the router to pick the landing tab: a player with no
/// lobby yet has nothing to manage, so they land on Discover ▸ Teammates
/// instead of an empty Manage list. `false` for guests / signed-out.
@riverpod
Future<bool> hasAnyLobby(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return false;

  final ids = await Supabase.instance.client
      .rpc('get_my_lobby_ids')
      .timeout(const Duration(seconds: 5));
  return (ids as List).isNotEmpty;
}
