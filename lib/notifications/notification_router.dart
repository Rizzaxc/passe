import 'package:go_router/go_router.dart';

import '../router.dart';
import 'notification_kind.dart';

/// Maps a push `data` payload to a destination and navigates there.
///
/// The `data` map is the FCM message's data block — the server's routing
/// contract `{kind, target_id, lobby_id?}` (see fn_enqueue_notification in
/// schema/push_notifications.sql). Driven by [GoRouter] directly (not a
/// `BuildContext`) so it works from a notification tap that launched the app
/// from a terminated state, before any widget context exists.
void routeNotificationTap(GoRouter router, Map<String, dynamic>? data) {
  if (data == null) return;
  final kind = NotificationKind.fromValue(data['kind'] as String?);
  if (kind == null) return;

  final lobbyId = data['lobby_id'] as String?;

  final location = switch (kind) {
    // The confirmed activity lives inside its lobby's section.
    NotificationKind.activityConfirmed =>
      lobbyId == null ? null : LobbyDetailRoute(id: lobbyId).location,
    // The booking surfaces on the Manage → schedule calendar.
    NotificationKind.proSessionReminder => const ManageScheduleRoute().location,
    // Reserved/dormant; route to the lobby when the handshake ships.
    NotificationKind.challengerConfirmed =>
      lobbyId == null ? null : LobbyDetailRoute(id: lobbyId).location,
  };

  if (location != null) router.go(location);
}
