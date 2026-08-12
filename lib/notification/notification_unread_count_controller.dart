import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_controller.dart';
import '../core/feature_flags.dart';
import '../notifications/notification_kind.dart';

part 'notification_unread_count_controller.g.dart';

/// Count-only query so every appbar bell shares one cheap provider instead of
/// each pulling the full notification list.
@riverpod
Future<int> notificationUnreadCount(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return 0;

  var query = Supabase.instance.client
      .from('notification_outbox')
      .select('id')
      .eq('recipient_user_id', userId)
      .isFilter('read_at', null);
  if (!ClientFeatureFlags.challengerFlow) {
    query = query.not('kind', 'in', NotificationKind.challengerFlowValues);
  }

  final response = await query
      .count(CountOption.exact)
      .timeout(const Duration(seconds: 5));

  return response.count;
}
