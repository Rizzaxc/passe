import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/model/lobby_public_preview.dart';

part 'lobby_public_preview_controller.g.dart';

/// The public preview for one lobby, fetched on demand (family, keyed by
/// lobby id) rather than watched against the shared filter — this is opened
/// per-tap, not part of a feed. Works unauthenticated: `get_lobby_public_preview`
/// is `anon`-granted so guests can open it straight from Discover.
@riverpod
Future<LobbyPublicPreview?> lobbyPublicPreview(Ref ref, String lobbyId) async {
  final response = await Supabase.instance.client
      .rpc('get_lobby_public_preview', params: {'p_lobby_id': lobbyId})
      .timeout(const Duration(seconds: 5));

  final data = response as Map<String, dynamic>;
  if (data['valid'] != true) return null;
  return LobbyPublicPreview.fromJson(data);
}
