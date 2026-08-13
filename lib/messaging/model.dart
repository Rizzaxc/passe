/// Models for the shared messaging layer (`schema/messaging.sql`).
///
/// One conversation/message shape backs every threaded chat in the app —
/// freeplay seat requests and coaching courses both render through
/// `conversation_view.dart`. Plain classes with `fromJson`, matching the
/// neighbouring freeplay models rather than freezed, since these are read-only
/// projections of an RPC row.
library;

enum MessageKind {
  text,
  system,
  paymentInfo,
  poll;

  factory MessageKind.fromDb(String value) => switch (value) {
    'payment_info' => paymentInfo,
    'system' => system,
    'poll' => poll,
    _ => text,
  };
}

class Message {
  final String id;
  final String? senderId;
  final String? senderUsername;
  final String? senderAvatar;
  final MessageKind kind;

  /// For [MessageKind.text] the message itself; for [MessageKind.system] a
  /// stable event code (e.g. `request_accepted`) translated client-side, never
  /// pre-rendered prose — same convention the freeplay chat used.
  final String? body;
  final DateTime createdAt;

  // Poll (kind == poll)
  final String? pollQuestion;
  final List<String> pollOptions;

  /// option index → vote count. Empty until someone votes.
  final Map<int, int> pollVotes;
  final int? myVote;

  // Payment info (kind == paymentInfo). Never arrives over Realtime — the
  // broadcast carries a signal only, so these are populated by the RPC.
  final String? bankCode;
  final String? bankDisplayName;
  final String? accountNumber;
  final String? accountName;

  /// Structured parameters for a system event (e.g. the student a membership
  /// event refers to). Null for most kinds.
  final Map<String, dynamic>? payload;

  const Message({
    required this.id,
    required this.kind,
    required this.createdAt,
    this.senderId,
    this.senderUsername,
    this.senderAvatar,
    this.body,
    this.pollQuestion,
    this.pollOptions = const [],
    this.pollVotes = const {},
    this.myVote,
    this.bankCode,
    this.bankDisplayName,
    this.accountNumber,
    this.accountName,
    this.payload,
  });

  bool get hasPaymentDetails => accountNumber != null;

  int get totalVotes => pollVotes.values.fold(0, (sum, count) => sum + count);

  factory Message.fromJson(Map<String, dynamic> json) {
    final payment = json['payment_info'] as Map<String, dynamic>?;
    final payload = json['payload'] as Map<String, dynamic>?;
    final rawVotes = json['poll_votes'] as Map<String, dynamic>?;

    return Message(
      id: json['id'].toString(),
      senderId: json['sender_id']?.toString(),
      senderUsername: json['sender_username'] as String?,
      senderAvatar: json['sender_avatar'] as String?,
      kind: MessageKind.fromDb(json['kind'].toString()),
      body: json['body'] as String?,
      createdAt: DateTime.parse(json['created_at'].toString()).toLocal(),
      pollQuestion: payload?['question'] as String?,
      pollOptions:
          (payload?['options'] as List?)?.map((o) => o.toString()).toList() ??
          const [],
      pollVotes:
          rawVotes?.map(
            (key, value) => MapEntry(
              int.tryParse(key) ?? 0,
              int.tryParse(value.toString()) ?? 0,
            ),
          ) ??
          const {},
      myVote: (json['my_vote'] as num?)?.toInt(),
      bankCode: payment?['bank_id'] as String?,
      bankDisplayName: payment?['bank_display_name'] as String?,
      accountNumber: payment?['value'] as String?,
      accountName: payment?['account_name'] as String?,
      payload: payload,
    );
  }

  /// A message arriving over the Realtime broadcast.
  ///
  /// The broadcast payload is deliberately thinner than the RPC row:
  /// `payment_info` messages carry no bank details (they'd otherwise be copied
  /// into `realtime.messages`, which Supabase retains for 3 days), and poll
  /// vote tallies aren't included since a brand-new poll has none. Both are
  /// filled in by the next `conversation_data` read.
  factory Message.fromBroadcast(Map<String, dynamic> payload) =>
      Message.fromJson({
        'id': payload['id'],
        'sender_id': payload['sender_id'],
        'sender_username': payload['sender_username'],
        'sender_avatar': payload['sender_avatar'],
        'kind': payload['kind'],
        'body': payload['body'],
        'payload': payload['payload'],
        'created_at': payload['created_at'],
      });
}

/// The conversation as a whole: its messages plus whether the viewer may post.
class ConversationSnapshot {
  final List<Message> messages;
  final bool canWrite;

  const ConversationSnapshot({required this.messages, required this.canWrite});

  ConversationSnapshot copyWith({List<Message>? messages, bool? canWrite}) =>
      ConversationSnapshot(
        messages: messages ?? this.messages,
        canWrite: canWrite ?? this.canWrite,
      );

  DateTime? get newestAt =>
      messages.isEmpty ? null : messages.last.createdAt.toUtc();
}
