import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/auth_controller.dart';
import '../../../core/model/enum.dart';
import '../../../discover_tab/teammate_section/feed_controller.dart';

part 'my_pending_requests_controller.g.dart';

/// One of the user's own still-pending "Xin vào" requests.
class MyPendingRequest {
  final String lobbyId;
  final String lobbyName;
  final Sport sport;
  final DateTime createdAt;

  const MyPendingRequest({
    required this.lobbyId,
    required this.lobbyName,
    required this.sport,
    required this.createdAt,
  });
}

/// The user's pending join requests across **every** sport — a request
/// shouldn't vanish from view because the context sport changed. Before this,
/// a sent request only existed as the "Đã gửi" state on a Discover card.
/// Rebuilds when [joinRequestStateProvider] changes, so sending or undoing
/// from Discover shows up here without a manual refresh.
@riverpod
Future<List<MyPendingRequest>> myPendingRequests(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  ref.watch(joinRequestStateProvider);
  if (userId == null) return const [];

  // RLS: the initiator may read its own befriend records; `lobby` is
  // world-readable, so the embedded name/sport resolve for a non-member.
  final rows = await Supabase.instance.client
      .from('lobby_befriend_record')
      .select('created_at, lobby!target_lobby_id(id, name, sport_id)')
      .eq('initiator_user_id', userId)
      .eq('interaction_type', 'request')
      .eq('status', 'pending')
      .order('created_at', ascending: false)
      .timeout(const Duration(seconds: 5));

  return [
    for (final row in rows)
      if (row['lobby'] case final Map<String, dynamic> lobby)
        MyPendingRequest(
          lobbyId: lobby['id'] as String,
          lobbyName: lobby['name'] as String? ?? '',
          sport: Sport.values[(lobby['sport_id'] as num).toInt()],
          createdAt: DateTime.parse(row['created_at'] as String),
        ),
  ];
}
