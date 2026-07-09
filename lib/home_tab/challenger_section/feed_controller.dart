import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/auth_controller.dart';
import '../../core/model/lobby_feed_item.dart';
import '../../core/state/selected_sport_state.dart';
import '../filter_controller.dart';

part 'feed_controller.g.dart';

class ContextLobby {
  final String id;
  final String name;

  const ContextLobby({required this.id, required this.name});
}

/// All of the caller's lobbies for the current sport — challenges are
/// lobby-vs-lobby, so the user picks which one they're challenging *as*
/// via the dropdown under the section title.
@riverpod
Future<List<ContextLobby>> contextLobbyOptions(Ref ref) async {
  final sport = ref.watch(selectedSportStateProvider.select((v) => v.value));
  if (sport == null) return [];

  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final rows = await Supabase.instance.client
      .from('lobby')
      .select('id, name, lobby_member!inner(user_id)')
      .eq('sport_id', sport.index)
      .eq('lobby_member.user_id', userId)
      .timeout(const Duration(seconds: 5));

  return (rows as List)
      .map(
        (row) => ContextLobby(
          id: (row as Map)['id'] as String,
          name: row['name'] as String,
        ),
      )
      .toList();
}

/// The user's explicit pick from the context-lobby dropdown. Null means
/// "no explicit pick yet" — [contextLobby] falls back to the first option.
@riverpod
class ContextLobbySelection extends _$ContextLobbySelection {
  @override
  String? build() => null;

  void select(String? lobbyId) => state = lobbyId;
}

/// The effective context lobby: the user's explicit pick if it's still a
/// valid option, otherwise the first lobby for the current sport.
@riverpod
Future<ContextLobby?> contextLobby(Ref ref) async {
  final options = await ref.watch(contextLobbyOptionsProvider.future);
  if (options.isEmpty) return null;

  final selectedId = ref.watch(contextLobbySelectionProvider);
  return options.firstWhere(
    (o) => o.id == selectedId,
    orElse: () => options.first,
  );
}

@riverpod
class ChallengerFeed extends _$ChallengerFeed {
  @override
  Future<List<LobbyFeedItem>> build() async {
    final filter = ref.watch(filterStateProvider);
    final sport = ref.watch(selectedSportStateProvider.select((v) => v.value));
    if (sport == null) return [];

    final ctx = await ref.watch(contextLobbyProvider.future);
    if (ctx == null) return [];

    final districtIds = filter.districts.map((d) => d.id).toList();

    final response = await Supabase.instance.client
        .rpc(
          'home_challenger_lobby_data',
          params: {
            'p_context_lobby_id': ctx.id,
            'p_sport_id': sport.index,
            'p_city': filter.city.dbIndex,
            'p_districts': districtIds,
            'p_search': filter.search,
            'p_page_size': 20,
            'p_page_number': 1,
          },
        )
        .timeout(const Duration(seconds: 5));

    return (response as List)
        .map((e) => LobbyFeedItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
