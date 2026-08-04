import '../notifications/notification_kind.dart';

/// A row from `notification_outbox` — read-only history, not app state
/// (mirrors `IncomingInvite`'s plain-DTO style rather than freezed).
class NotificationItem {
  final int id;
  final NotificationKind? kind;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime? readAt;
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.data,
    required this.readAt,
    required this.createdAt,
  });

  bool get isUnread => readAt == null;

  factory NotificationItem.fromRow(Map<String, dynamic> row) {
    return NotificationItem(
      id: row['id'] as int,
      kind: NotificationKind.fromValue(row['kind'] as String?),
      title: row['title'] as String,
      body: row['body'] as String,
      data: (row['data'] as Map?)?.cast<String, dynamic>() ?? const {},
      readAt: row['read_at'] == null
          ? null
          : DateTime.parse(row['read_at'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
