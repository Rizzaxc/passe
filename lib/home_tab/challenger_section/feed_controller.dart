import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/auth_controller.dart';
import '../../core/model/lobby_feed_item.dart';
import '../../core/state/selected_sport_state.dart';
import '../filter_controller.dart';

part 'feed_controller.g.dart';

@riverpod
class ChallengerFeed extends _$ChallengerFeed {
  @override
  Future<List<LobbyFeedItem>> build() async {
    final filter = ref.watch(filterStateProvider);
    final sport = ref.watch(selectedSportStateProvider.select((v) => v.value));
    if (sport == null) return [];

    // Challenges are lobby-vs-lobby, so we need a "context lobby" to challenge
    // with — the caller's lobby for the current sport. Most users have exactly
    // one; we take the first. No lobby ⇒ nothing to challenge with.
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return [];

    final supabase = Supabase.instance.client;

    final ctxRows = await supabase
        .from('lobby')
        .select('id, lobby_member!inner(user_id)')
        .eq('sport_id', sport.index)
        .eq('lobby_member.user_id', userId)
        .limit(1)
        .timeout(const Duration(seconds: 5));
    final ctxList = ctxRows as List;
    if (ctxList.isEmpty) return [];
    final contextLobbyId = (ctxList.first as Map)['id'] as String;

    final districtIds = filter.districts.map((d) => d.id).toList();

    final response = await supabase.rpc(
      'home_challenger_lobby_data',
      params: {
        'p_context_lobby_id': contextLobbyId,
        'p_sport_id': sport.index,
        'p_city': filter.city.dbIndex,
        'p_districts': districtIds,
        'p_page_size': 20,
        'p_page_number': 1,
      },
    ).timeout(const Duration(seconds: 5));

    return (response as List)
        .map((e) => LobbyFeedItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
