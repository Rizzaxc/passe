import 'package:go_router/go_router.dart';

import '../core/feature_flags.dart';
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
  if (!ClientFeatureFlags.challengerFlow && kind.isChallengerFlow) return null;

  final lobbyId = data['lobby_id'] as String?;
  final recordId = data['record_id'] as String?;
  // Friendship pushes carry the *other* party's id — that's who you want to
  // land on, whether they just asked or just accepted.
  final userId = data['user_id'] as String?;
  final bookingId = data['booking_id'] as String?;
  // Activity/challenge ids so a tap can land on the specific Planner card
  // instead of just the lobby. Key names aren't uniform across emitters —
  // `fn_emit_activity_scheduled` uses `activity_id`, `fn_emit_activity_confirmed`
  // uses `target_id` for the same concept (schema/activity_scheduled_notify.sql,
  // schema/push_notifications.sql) — so both are read here.
  final activityId = (data['activity_id'] ?? data['target_id']) as String?;
  final challengeId = data['challenge_id'] as String?;
  final courseId = data['course_id'] as String?;
  final requestId = data['request_id'] as String?;

  return switch (kind) {
    // A newly-scheduled activity lives in the Planner tab — scroll to it.
    NotificationKind.activityScheduled =>
      lobbyId == null
          ? null
          : LobbyDetailRoute(
              id: lobbyId,
              tab: 1,
              highlightActivityId: activityId,
            ).location,
    // The confirmed activity lives in the Planner tab — scroll to it.
    NotificationKind.activityConfirmed =>
      lobbyId == null
          ? null
          : LobbyDetailRoute(
              id: lobbyId,
              tab: 1,
              highlightActivityId: activityId,
            ).location,
    // The booking surfaces on the Manage → schedule calendar.
    NotificationKind.proSessionReminder => const ManageScheduleRoute().location,
    // Challenge accepted → the activity now exists in the initiator lobby's
    // (recipient's own) Planner tab — scroll to it by challenge id, since
    // this event doesn't carry the newly-materialised activity's own id.
    NotificationKind.challengerConfirmed =>
      lobbyId == null
          ? null
          : LobbyDetailRoute(
              id: lobbyId,
              tab: 1,
              highlightChallengeId: challengeId,
            ).location,
    // Incoming challenge / declined — no activity exists yet (only
    // materialises on accept), so just open the lobby (Feed).
    NotificationKind.challengeReceived =>
      lobbyId == null ? null : LobbyDetailRoute(id: lobbyId).location,
    NotificationKind.challengeDeclined =>
      lobbyId == null ? null : LobbyDetailRoute(id: lobbyId).location,
    // Both sides confirmed — the real "it's locked in" moment; scroll to the
    // now-official activity in Planner. Per-recipient (the server sends one
    // enqueue call per lobby with that lobby's own id).
    NotificationKind.challengeScheduled =>
      lobbyId == null
          ? null
          : LobbyDetailRoute(
              id: lobbyId,
              tab: 1,
              highlightChallengeId: challengeId,
            ).location,
    // The sweep that lapses a challenge deletes both sides' activity rows —
    // nothing to highlight in Planner; the explanatory feed item is what a
    // tap should land near, so just open the lobby (Feed).
    NotificationKind.challengeLapsed =>
      lobbyId == null ? null : LobbyDetailRoute(id: lobbyId).location,
    // A played/recorded result is History's domain, not Planner's (Planner
    // is future/ongoing-only).
    NotificationKind.matchResultRecorded =>
      lobbyId == null ? null : LobbyDetailRoute(id: lobbyId, tab: 2).location,
    // Lobby invite — the preview/accept page for this specific invite. Used
    // for OS push taps / cold starts, which (unlike the in-app notification
    // list) can't cheaply pre-check accept/decline status before routing.
    NotificationKind.lobbyInvite =>
      recordId == null
          ? const ManageLobbyRoute().location
          : LobbyInvitePreviewRoute(recordId: recordId).location,
    // The captain handles incoming requests from the lobby's info sheet.
    NotificationKind.lobbyJoinRequest =>
      lobbyId == null ? null : LobbyDetailRoute(id: lobbyId).location,
    // Once approved, the requester is a member and can open the lobby.
    NotificationKind.lobbyJoinRequestApproved =>
      lobbyId == null ? null : LobbyDetailRoute(id: lobbyId).location,
    // A denied requester cannot open the lobby's member-only detail page.
    NotificationKind.lobbyJoinRequestDenied =>
      const HomeTeammateRoute().location,
    // Kicked — the lobby is no longer theirs to open; land on their own lobby list.
    NotificationKind.memberKicked => const ManageLobbyRoute().location,
    // A new request came in for the linked professional — their
    // pending-requests subtab, scrolled/highlighted to this one booking.
    NotificationKind.professionalBookingRequested => ManageRequestsRoute(
      highlightBookingId: bookingId,
    ).location,
    // The professional responded — the client's own booking lives in their schedule/coaching view.
    NotificationKind.professionalBookingConfirmed =>
      const ManageScheduleRoute().location,
    NotificationKind.professionalBookingRejected =>
      const ManageScheduleRoute().location,
    // Every course push carries its own `course_id`, so each opens the course
    // it's about. Without one (an old or malformed payload) fall back to the
    // hub rather than a dead end. ManageCourseRoute resolves the differing
    // player (index 2) and coach (index 0) layouts at the destination.
    NotificationKind.courseMessage ||
    NotificationKind.courseEnrollmentOffer ||
    NotificationKind.courseEnrollmentAccepted ||
    NotificationKind.courseActivityProposed ||
    NotificationKind.courseActivityApproved ||
    NotificationKind.courseActivityChanged ||
    NotificationKind.courseSessionReport ||
    NotificationKind.courseEnded =>
      courseId == null
          ? const ManageCourseRoute().location
          : CourseDetailRoute(id: courseId).location,
    // Removed from the course — it's no longer theirs to open.
    NotificationKind.courseMemberRemoved => const ManageCourseRoute().location,
    // Both friendship kinds open the other person's page: the request can be
    // answered from its CTA, and an acceptance is best celebrated by landing
    // on the new friend.
    NotificationKind.friendRequest =>
      userId == null ? null : UserRoute(id: userId).location,
    NotificationKind.friendAccepted =>
      userId == null ? null : UserRoute(id: userId).location,
    // A payment request is always for an already-ended session — that
    // activity can never appear in the Planner tab (future/ongoing-only,
    // see matchResultRecorded above), so this lands in History, same tab
    // that hosts a played match, scrolled to and highlighting that
    // activity's own card (which History reuses ActivityCard for — see
    // lib/manage_tab/lobby_section/history/view.dart).
    NotificationKind.paymentRequested =>
      lobbyId == null
          ? null
          : LobbyDetailRoute(
              id: lobbyId,
              tab: 2,
              highlightActivityId: activityId,
            ).location,
    NotificationKind.debtCollected =>
      lobbyId == null
          ? null
          : LobbyDetailRoute(
              id: lobbyId,
              tab: 2,
              highlightActivityId: activityId,
            ).location,
    NotificationKind.freeplayRequestReceived ||
    NotificationKind.freeplayRequestAccepted ||
    NotificationKind.freeplayRequestDeclined ||
    NotificationKind.freeplayRequestCancelled ||
    NotificationKind.freeplayChatMessage =>
      activityId == null || requestId == null
          ? const ManageLobbyRoute().location
          : FreeplayChatRoute(
              activityId: activityId,
              requestId: requestId,
            ).location,
    NotificationKind.freeplayActivityCancelled =>
      activityId == null
          ? const ManageLobbyRoute().location
          : FreeplayDetailRoute(id: activityId).location,
  };
}

/// Push-tap entry point: resolve and navigate. Driven by [GoRouter] directly
/// (not a `BuildContext`) so it works from a notification tap that launched
/// the app from a terminated state, before any widget context exists.
void routeNotificationTap(GoRouter router, Map<String, dynamic>? data) {
  final location = resolveNotificationLocation(data);
  if (location != null) router.go(location);
}
