import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_controller.dart';
import 'notification_item.dart';
import 'notification_unread_count_controller.dart';

part 'notification_center_controller.g.dart';

/// The notification centre's list — a read-only history of past
/// `notification_outbox` rows for the current user, most recent first.
/// No pagination for v1 (matches the project's default toward not building
/// for hypothetical future needs); unread rows get a dot in the UI rather
/// than being re-sorted to the top.
@riverpod
class NotificationCenterController extends _$NotificationCenterController {
  final supabase = Supabase.instance.client;

  @override
  Future<List<NotificationItem>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const [];

    final response = await supabase
        .from('notification_outbox')
        .select('id, kind, title, body, data, read_at, created_at')
        .eq('recipient_user_id', userId)
        .order('created_at', ascending: false)
        .limit(50)
        .timeout(const Duration(seconds: 5));

    return (response as List)
        .map((row) => NotificationItem.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> markRead(int id) async {
    await supabase
        .rpc('fn_mark_notification_read', params: {'p_id': id})
        .timeout(const Duration(seconds: 5));
    ref.invalidateSelf();
    ref.invalidate(notificationUnreadCountProvider);
  }

  Future<void> markAllRead() async {
    await supabase
        .rpc('fn_mark_all_notifications_read')
        .timeout(const Duration(seconds: 5));
    ref.invalidateSelf();
    ref.invalidate(notificationUnreadCountProvider);
  }

  Future<void> delete(int id) async {
    await supabase
        .rpc('fn_delete_notification', params: {'p_id': id})
        .timeout(const Duration(seconds: 5));
    ref.invalidateSelf();
    ref.invalidate(notificationUnreadCountProvider);
  }

  Future<void> clearRead() async {
    await supabase
        .rpc('fn_clear_read_notifications')
        .timeout(const Duration(seconds: 5));
    ref.invalidateSelf();
  }
}
