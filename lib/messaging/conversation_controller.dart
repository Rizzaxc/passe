import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';

import 'model.dart';

part 'conversation_controller.g.dart';

const _rpcTimeout = Duration(seconds: 5);
final _talker = Talker();

/// Live view of one conversation (`schema/messaging.sql` + `messaging_realtime.sql`).
///
/// Realtime delivery is best-effort, so this controller never treats the
/// socket as the source of truth:
///
///   * every `subscribed` transition (the first one *and* every automatic
///     rejoin after a drop) triggers a backfill from the newest message held,
///   * so does an app resume, since a socket killed while backgrounded can
///     rejoin without the SDK noticing a gap,
///   * and `conversation_data` is always the authority — the broadcast payload
///     is a fast path, not a replacement.
///
/// Without that, a dropped socket loses messages silently: the thread simply
/// stops updating and nothing surfaces the gap to the user.
@riverpod
class ConversationController extends _$ConversationController {
  RealtimeChannel? _channel;
  AppLifecycleListener? _lifecycle;
  bool _backfilling = false;

  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<ConversationSnapshot> build(String conversationId) async {
    ref.onDispose(_teardown);

    final snapshot = await _load();
    _subscribe(conversationId);
    _lifecycle = AppLifecycleListener(
      onResume: () => unawaited(_backfill()),
    );
    return snapshot;
  }

  Future<ConversationSnapshot> _load({DateTime? since}) async {
    final rows =
        await _client
                .rpc(
                  'conversation_data',
                  params: {
                    'p_conversation_id': conversationId,
                    'p_since': since?.toUtc().toIso8601String(),
                  },
                )
                .timeout(_rpcTimeout)
            as List;

    final messages = rows
        .map((row) => Message.fromJson(row as Map<String, dynamic>))
        .toList();

    // `can_write` is repeated on every row, so an empty thread carries no
    // answer to read it off. This used to fall back to `state.value?.canWrite
    // ?? false` — on the very first load of a message-less thread,
    // `state.value` is null too, so a brand-new empty conversation defaulted
    // to permanently read-only, with no way out since the composer that
    // would let the user break the deadlock is the very thing that's
    // disabled. `can_write_conversation` answers directly instead of
    // guessing from message rows.
    final canWrite = rows.isEmpty
        ? await _client
              .rpc(
                'can_write_conversation',
                params: {'p_conversation_id': conversationId},
              )
              .timeout(_rpcTimeout)
              as bool
        : (rows.first as Map<String, dynamic>)['can_write'] as bool? ?? false;

    return ConversationSnapshot(messages: messages, canWrite: canWrite);
  }

  void _subscribe(String conversationId) {
    _channel =
        _client
            .channel(
              'conversation:$conversationId',
              // Must match the `true` passed to realtime.send() in the
              // broadcast trigger — a private channel never receives a public
              // broadcast, and vice versa.
              opts: const RealtimeChannelConfig(private: true),
            )
            .onBroadcast(event: 'new_message', callback: _onBroadcast)
          ..subscribe((status, error) {
            if (status == RealtimeSubscribeStatus.subscribed) {
              unawaited(_backfill());
            } else if (error != null) {
              _talker.handle(error);
            }
          });
  }

  void _onBroadcast(Map<String, dynamic> payload) {
    final current = state.value;
    if (current == null) return;

    final incoming = Message.fromBroadcast(payload);

    // Payment details are deliberately absent from broadcasts, so this one
    // can't be rendered from the payload — pull the full row instead.
    if (incoming.kind == MessageKind.paymentInfo) {
      unawaited(_backfill());
      return;
    }

    _append([incoming]);
  }

  /// Fetch anything newer than what we hold. Cheap when nothing was missed
  /// (the RPC returns zero rows), so it's safe to call on every rejoin.
  Future<void> _backfill() async {
    if (_backfilling) return;
    _backfilling = true;
    try {
      final since = state.value?.newestAt;
      final fresh = await _load(since: since);
      if (since == null) {
        state = AsyncData(fresh);
      } else {
        _append(fresh.messages, canWrite: fresh.canWrite);
      }
    } catch (e, st) {
      // A failed backfill must not blank a thread the user is reading; the
      // next rejoin, resume or pull-to-refresh tries again.
      _talker.handle(e, st);
    } finally {
      _backfilling = false;
    }
  }

  /// Merge by id — a message can arrive twice (broadcast *and* backfill) and
  /// the two paths race by design.
  void _append(List<Message> incoming, {bool? canWrite}) {
    final current = state.value;
    if (current == null) return;

    final byId = {for (final message in current.messages) message.id: message};
    for (final message in incoming) {
      byId[message.id] = message;
    }
    final merged = byId.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    state = AsyncData(
      current.copyWith(messages: merged, canWrite: canWrite),
    );
  }

  /// Pull-to-refresh: reload the whole thread, not just the tail, so a
  /// deletion or an edited read window is picked up too.
  Future<void> refresh() async {
    state = AsyncData(await _load());
  }

  Future<void> send(String body) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;
    await _client
        .rpc(
          'send_message',
          params: {'p_conversation_id': conversationId, 'p_body': trimmed},
        )
        .timeout(_rpcTimeout);
    // The sender's own broadcast round-trips like everyone else's; backfill so
    // the bubble appears even if the socket is down.
    await _backfill();
  }

  Future<void> createPoll(String question, List<String> options) async {
    await _client
        .rpc(
          'create_message_poll',
          params: {
            'p_conversation_id': conversationId,
            'p_question': question.trim(),
            'p_options': options,
          },
        )
        .timeout(_rpcTimeout);
    await _backfill();
  }

  Future<void> vote(String messageId, int optionIndex) async {
    await _client
        .rpc(
          'vote_message_poll',
          params: {'p_message_id': messageId, 'p_option_index': optionIndex},
        )
        .timeout(_rpcTimeout);
    // Vote tallies don't broadcast — reload to show the new count.
    await refresh();
  }

  Future<void> sharePaymentInfo() async {
    await _client
        .rpc(
          'share_conversation_payment_info',
          params: {'p_conversation_id': conversationId},
        )
        .timeout(_rpcTimeout);
    await _backfill();
  }

  Future<void> markRead() => _client
      .rpc('mark_conversation_read', params: {'p_conversation_id': conversationId})
      .timeout(_rpcTimeout);

  void _teardown() {
    _lifecycle?.dispose();
    _lifecycle = null;
    final channel = _channel;
    _channel = null;
    if (channel != null) unawaited(_client.removeChannel(channel));
  }
}
