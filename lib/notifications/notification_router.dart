import 'package:go_router/go_router.dart';

import '../router.dart';
import 'notification_kind.dart';

/// Maps a push/outbox `data` payload to a destination location, or null if
/// it doesn't resolve (missing data, or an unhandled kind). Pure — no
/// navigation — so both the push-tap handler and the in-app notification
/// center list can share this single routing table.
///
/// The `data` map is the FCM message's data block — the server's routing
/// contract `{kind, target_id, lobby_id?}` (see fn_enqueue_notification in
/// schema/push_notifications.sql).
String? resolveNotificationLocation(Map<String, dynamic>? data) {
  if (data == null) return null;
  final kind = NotificationKind.fromValue(data['kind'] as String?);
  if (kind == null) return null;

  final lobbyId = data['lobby_id'] as String?;
  // Friendship pushes carry the *other* party's id — that's who you want to
  // land on, whether they just asked or just accepted.
  final userId = data['user_id'] as String?;
  final bookingId = data['booking_id'] as String?;

  return switch (kind) {
    // A newly-scheduled activity lives inside its lobby's section, same as the
    // later quorum-crossing confirmation.
    NotificationKind.activityScheduled =>
      lobbyId == null ? null : LobbyDetailRoute(id: lobbyId).location,
    // The confirmed activity lives inside its lobby's section.
    NotificationKind.activityConfirmed =>
      lobbyId == null ? null : LobbyDetailRoute(id: lobbyId).location,
    // The booking surfaces on the Manage → schedule calendar.
    NotificationKind.proSessionReminder => const ManageScheduleRoute().location,
    // Challenge accepted → open the initiator lobby (recipient's own).
    NotificationKind.challengerConfirmed =>
      lobbyId == null ? null : LobbyDetailRoute(id: lobbyId).location,
    // Incoming challenge / declined → open the relevant lobby to act/see.
    NotificationKind.challengeReceived =>
      lobbyId == null ? null : LobbyDetailRoute(id: lobbyId).location,
    NotificationKind.challengeDeclined =>
      lobbyId == null ? null : LobbyDetailRoute(id: lobbyId).location,
    // Both sides confirmed / a deadline lapsed / a result landed — all three
    // are per-recipient (the server sends one enqueue call per lobby with
    // that lobby's own id), so this always opens the recipient's own lobby.
    NotificationKind.challengeScheduled =>
      lobbyId == null ? null : LobbyDetailRoute(id: lobbyId).location,
    NotificationKind.challengeLapsed =>
      lobbyId == null ? null : LobbyDetailRoute(id: lobbyId).location,
    NotificationKind.matchResultRecorded =>
      lobbyId == null ? null : LobbyDetailRoute(id: lobbyId).location,
    // Lobby invite — go to the manage/lobby tab so they see their pending invites.
    NotificationKind.lobbyInvite => const ManageLobbyRoute().location,
    // A new request came in for the linked professional — their
    // pending-requests subtab, scrolled/highlighted to this one booking.
    NotificationKind.professionalBookingRequested =>
      ManageRequestsRoute(highlightBookingId: bookingId).location,
    // The professional responded — the client's own booking lives in their schedule/coaching view.
    NotificationKind.professionalBookingConfirmed =>
      const ManageScheduleRoute().location,
    NotificationKind.professionalBookingRejected =>
      const ManageScheduleRoute().location,
    // Both friendship kinds open the other person's page: the request can be
    // answered from its CTA, and an acceptance is best celebrated by landing
    // on the new friend.
    NotificationKind.friendRequest =>
      userId == null ? null : UserRoute(id: userId).location,
    NotificationKind.friendAccepted =>
      userId == null ? null : UserRoute(id: userId).location,
    // Both payment-request kinds land wherever the feed item lives — the
    // recipient's own lobby (the server sends one enqueue call per lobby,
    // same convention as the challenge kinds above).
    NotificationKind.paymentRequested =>
      lobbyId == null ? null : LobbyDetailRoute(id: lobbyId).location,
    NotificationKind.debtCollected =>
      lobbyId == null ? null : LobbyDetailRoute(id: lobbyId).location,
  };
}

/// Push-tap entry point: resolve and navigate. Driven by [GoRouter] directly
/// (not a `BuildContext`) so it works from a notification tap that launched
/// the app from a terminated state, before any widget context exists.
void routeNotificationTap(GoRouter router, Map<String, dynamic>? data) {
  final location = resolveNotificationLocation(data);
  if (location != null) router.go(location);
}
