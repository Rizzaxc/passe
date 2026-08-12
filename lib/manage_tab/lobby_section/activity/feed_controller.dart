import 'package:easy_localization/easy_localization.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/auth_controller.dart';
import 'feed.dart';
import 'money_controller.dart';

part 'feed_controller.g.dart';

/// Thrown by `postPersonalAction('late', ...)` when the caller already has a
/// `late` report for this activity — races the DB's partial unique index
/// (`lobby_feed_item_one_late_per_activity_idx`), same pattern as
/// `UsernameTakenException` in `lib/auth/auth_controller.dart`.
class AlreadyMarkedLateException implements Exception {
  const AlreadyMarkedLateException();
  @override
  String toString() =>
      'AlreadyMarkedLateException: already posted a late report for this activity';
}

/// Thrown when the caller already posted their one note for an activity.
class AlreadyPostedActivityNoteException implements Exception {
  const AlreadyPostedActivityNoteException();
  @override
  String toString() =>
      'AlreadyPostedActivityNoteException: already posted a note for this activity';
}

const maxActivityNoteLength = 72;

/// Trims and validates an activity note before it reaches Supabase.
///
/// `String.runes` matches PostgreSQL `char_length` for ordinary Unicode code
/// points more closely than UTF-16 `String.length` does.
String normalizeActivityNote(String value) {
  final note = value.trim();
  if (note.isEmpty) {
    throw ArgumentError.value(value, 'value', 'activity note cannot be empty');
  }
  if (note.runes.length > maxActivityNoteLength) {
    throw ArgumentError.value(
      value,
      'value',
      'activity note cannot exceed $maxActivityNoteLength characters',
    );
  }
  return note;
}

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
      if (day == today) return 'lobbyHub.feed.today'.tr();
      if (day == yesterday) return 'lobbyHub.feed.yesterday'.tr();
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
  ///
  /// [activityId] scopes the post to one activity — only ever passed for
  /// `late` (fired from a specific `ActivityCard`), which is also the only
  /// action kind the DB gates to one-per-(activity, author) via a partial
  /// unique index. Every other caller (e.g. `remind_captain` from the
  /// Planner tab's empty state, where there's no activity yet) omits it, so
  /// the post stays lobby-wide and shows on the general Feed tab — see
  /// `FeedItemActivityScope` in `feed.dart`.
  ///
  /// Callers include the Planner tab's activity card (`_postLate`) and its
  /// empty state, neither of which watches this provider — the Feed tab is
  /// a separate subtab and may not be mounted. Without `ref.keepAlive()`
  /// this autoDispose provider can get disposed the moment this method
  /// yields (right after the insert, at `ref.invalidateSelf()`), so the
  /// `await future` below throws on a disposed Ref even though the insert
  /// already succeeded — surfacing as a spurious error toast over a feed
  /// item that *did* get posted (same failure mode `ScheduleActivityController.cancel`
  /// hit for the same reason).
  Future<void> postPersonalAction(
    String actionKind, {
    String? activityId,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final keepAliveLink = ref.keepAlive();
    try {
      await supabase
          .from('lobby_feed_item')
          .insert({
            'lobby_id': lobbyId,
            'author_id': userId,
            'kind': 'personal',
            'activity_id': ?activityId,
            'payload': {'action_kind': actionKind},
          })
          .timeout(const Duration(seconds: 5));

      ref.invalidateSelf();
      await future;
    } on PostgrestException catch (e) {
      // Unique-violation race on lobby_feed_item_one_late_per_activity_idx —
      // two rapid taps (or a stale disabled-button check) both reaching the
      // insert. The client-side gate in ActivityCard should normally prevent
      // this; this is the DB-side backstop.
      if (e.code == '23505') {
        throw const AlreadyMarkedLateException();
      }
      rethrow;
    } finally {
      keepAliveLink.close();
    }
  }

  /// Post the caller's one free-text note for [activityId]. The database
  /// independently validates lobby membership, activity scope, message
  /// length, and the one-note-per-member rule.
  Future<void> postActivityNote({
    required String activityId,
    required String note,
  }) async {
    final normalized = normalizeActivityNote(note);
    final keepAliveLink = ref.keepAlive();
    try {
      await supabase
          .rpc(
            'post_activity_note',
            params: {'p_activity_id': activityId, 'p_note': normalized},
          )
          .timeout(const Duration(seconds: 5));

      ref.invalidateSelf();
      await future;
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const AlreadyPostedActivityNoteException();
      }
      rethrow;
    } finally {
      keepAliveLink.close();
    }
  }

  /// Start an ancillary payment request ("đòi tiền trà đá") against tagged
  /// lobby mates — any confirmed (going) attendee of [activityId] can call
  /// this, not just the captain/coordinator. Splits [amount] equally
  /// (rounded up to the nearest 1000đ, server-side) across [taggedUserIds].
  ///
  /// Called from `payment_request_sheet.dart`, which doesn't watch this
  /// provider — same bare-`ref.read()`-with-no-watcher hazard as
  /// `postPersonalAction` above, so it needs the same `ref.keepAlive()`.
  Future<void> createAncillaryPaymentRequest({
    required String activityId,
    required num amount,
    String? note,
    required List<String> taggedUserIds,
  }) async {
    final keepAliveLink = ref.keepAlive();
    try {
      await supabase
          .rpc(
            'create_ancillary_payment_request',
            params: {
              'p_activity_id': activityId,
              'p_total_amount': amount,
              'p_note': note,
              'p_tagged_users': taggedUserIds,
            },
          )
          .timeout(const Duration(seconds: 5));

      ref.invalidateSelf();
      await future;
    } finally {
      keepAliveLink.close();
    }
  }

  /// Self-report "I've paid" on a payment-request feed item
  /// (`mark_payment_request_paid`). Best-effort — no ledger backs this, it's
  /// just a per-user ack the RPC turns into a `lobby_feed_item_reaction` row.
  /// Once every tagged payee has acked, the RPC notifies the recipient.
  Future<void> markPaymentRequestPaid(String feedItemId) async {
    await supabase
        .rpc(
          'mark_payment_request_paid',
          params: {'p_feed_item_id': feedItemId},
        )
        .timeout(const Duration(seconds: 5));

    ref.invalidate(lobbyMoneyControllerProvider(lobbyId));
    ref.invalidateSelf();
    await future;
  }
}
