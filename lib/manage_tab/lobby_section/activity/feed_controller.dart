import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/auth_controller.dart';
import 'feed.dart';

part 'feed_controller.g.dart';

/// Activity-tab feed (chat-style action stream) for a lobby.
///
/// Backed by `lobby_feed_item` via the `lobby_feed_data` RPC, which
/// resolves the author username and aggregates poll-vote tallies in a
/// single round-trip. Day dividers (`DayDivItem`) are computed
/// client-side from the row timestamps.
@riverpod
class LobbyFeedController extends _$LobbyFeedController {
  final supabase = Supabase.instance.client;

  @override
  Future<List<FeedItem>> build(String lobbyId) async {
    final response = await supabase
        .rpc('lobby_feed_data', params: {'p_lobby_id': lobbyId})
        .timeout(const Duration(seconds: 5));

    final rows = (response as List).cast<Map<String, dynamic>>();
    // RPC returns newest-first; the renderer wants oldest-first inside
    // each day (the parent ListView reverses, so the very newest item
    // still lands at the visual bottom).
    final ascending = rows.reversed.toList();
    return _withDayDividers(ascending);
  }

  /// Walk an oldest→newest list of feed rows and splice a `DayDivItem`
  /// in whenever the local-time date changes. The divider label uses
  /// "Hôm nay" / "Hôm qua" for the two most recent days, then `dd/MM`.
  List<FeedItem> _withDayDividers(List<Map<String, dynamic>> rows) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String labelFor(DateTime day) {
      if (day == today) return 'Hôm nay';
      if (day == yesterday) return 'Hôm qua';
      return '${day.day.toString().padLeft(2, '0')}/'
          '${day.month.toString().padLeft(2, '0')}';
    }

    final out = <FeedItem>[];
    DateTime? lastDay;
    for (final row in rows) {
      final created = DateTime.parse(row['created_at'] as String).toLocal();
      final day = DateTime(created.year, created.month, created.day);
      if (lastDay != day) {
        out.add(DayDivItem(labelFor(day)));
        lastDay = day;
      }
      out.add(FeedItem.fromRow(row));
    }
    return out;
  }

  /// Cast (or change) the caller's vote on a poll feed item. Upserts on
  /// the `(feed_item_id, user_id)` primary key, so re-tapping a different
  /// option just moves the existing vote. Refetches afterwards so the
  /// tallies + `myVote` reflect the server, rather than faking the count
  /// locally.
  Future<void> vote(String feedItemId, int optionIndex) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    await supabase
        .from('lobby_feed_poll_vote')
        .upsert({
          'feed_item_id': feedItemId,
          'user_id': userId,
          'option_index': optionIndex,
        })
        .timeout(const Duration(seconds: 5));

    ref.invalidateSelf();
    await future;
  }

  /// Post one of the quick "personal" status updates (comeEarly, late,
  /// bringGear, needLift, offerLift, paid, skip, cheer, remindCaptain —
  /// see `PersonalActionKind`). RLS allows any lobby member to insert
  /// `kind = 'personal'` items, unlike `update`/`poll` which are
  /// captain-only.
  Future<void> postPersonalAction(String actionKind) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    await supabase.from('lobby_feed_item').insert({
      'lobby_id': lobbyId,
      'author_id': userId,
      'kind': 'personal',
      'payload': {'action_kind': actionKind},
    }).timeout(const Duration(seconds: 5));

    ref.invalidateSelf();
    await future;
  }
}
