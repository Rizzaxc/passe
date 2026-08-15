import 'package:flutter_test/flutter_test.dart';
import 'package:passe/core/feature_flags.dart';
import 'package:passe/discover_tab/main.dart';
import 'package:passe/notifications/notification_kind.dart';
import 'package:passe/notifications/notification_router.dart';
import 'package:passe/router.dart';

void main() {
  group('lobby join request notifications', () {
    test('wire values resolve to their client kinds', () {
      expect(
        NotificationKind.fromValue('lobby_join_request'),
        NotificationKind.lobbyJoinRequest,
      );
      expect(
        NotificationKind.fromValue('lobby_join_request_approved'),
        NotificationKind.lobbyJoinRequestApproved,
      );
      expect(
        NotificationKind.fromValue('lobby_join_request_denied'),
        NotificationKind.lobbyJoinRequestDenied,
      );
    });

    test('incoming request opens the captain lobby', () {
      expect(
        resolveNotificationLocation({
          'kind': 'lobby_join_request',
          'lobby_id': 'lobby-1',
        }),
        const LobbyDetailRoute(id: 'lobby-1').location,
      );
    });

    test('approved request opens the newly joined lobby', () {
      expect(
        resolveNotificationLocation({
          'kind': 'lobby_join_request_approved',
          'lobby_id': 'lobby-1',
        }),
        const LobbyDetailRoute(id: 'lobby-1').location,
      );
    });

    test('denied request returns to teammate discovery', () {
      expect(
        resolveNotificationLocation({
          'kind': 'lobby_join_request_denied',
          'lobby_id': 'lobby-1',
        }),
        const DiscoverTeammateRoute().location,
      );
    });
  });

  test('challenge notification routing follows the client feature gate', () {
    final location = resolveNotificationLocation({
      'kind': 'challenge_received',
      'lobby_id': 'lobby-1',
    });

    expect(
      location,
      ClientFeatureFlags.challengerFlow
          ? const LobbyDetailRoute(id: 'lobby-1').location
          : isNull,
    );
  });

  group('Manage notification routes', () {
    test('schedule notifications keep the named Schedule route', () {
      expect(
        resolveNotificationLocation({'kind': 'pro_session_reminder'}),
        const ManageScheduleRoute().location,
      );
      expect(
        resolveNotificationLocation({'kind': 'professional_booking_confirmed'}),
        const ManageScheduleRoute().location,
      );
    });

    test('removed lobby member falls back to the Lobby hub', () {
      expect(
        resolveNotificationLocation({'kind': 'member_kicked'}),
        const ManageLobbyRoute().location,
      );
    });

    test('course notification without an id falls back to the Course hub', () {
      expect(
        resolveNotificationLocation({'kind': 'course_member_removed'}),
        const ManageCourseRoute().location,
      );
    });

    test('referee request preserves the highlighted request route', () {
      expect(
        resolveNotificationLocation({
          'kind': 'professional_booking_requested',
          'booking_id': 'booking-1',
        }),
        const ManageRequestsRoute(highlightBookingId: 'booking-1').location,
      );
    });
  });

  test('Discover route indices match the enabled tab count', () {
    expect(DiscoverTab.locationIndex, DiscoverTab.tabCount - 1);
    expect(DiscoverTab.professionalIndex, lessThan(DiscoverTab.tabCount));
    expect(DiscoverTab.tabCount, ClientFeatureFlags.challengerFlow ? 5 : 4);
  });

  group('push-only routes must be pushed, not go()ed', () {
    // UserRoute and LobbyInvitePreviewRoute are declared outside MainRoute's
    // shell tree — go()ing them tears down the whole bottom-tab shell instead
    // of just replacing the current page. Regression coverage for the crash
    // this caused on both the friend-request and lobby-invite notification
    // paths (see root CLAUDE.md ▸ Navigation).
    test('friend request opens the requester profile', () {
      expect(
        resolveNotificationLocation({
          'kind': 'friend_request',
          'user_id': 'user-1',
        }),
        const UserRoute(id: 'user-1').location,
      );
    });

    test('friend accepted opens the new friend profile', () {
      expect(
        resolveNotificationLocation({
          'kind': 'friend_accepted',
          'user_id': 'user-1',
        }),
        const UserRoute(id: 'user-1').location,
      );
    });

    test('pending lobby invite opens the push-only preview page', () {
      expect(
        resolveNotificationLocation({
          'kind': 'lobby_invite',
          'record_id': 'record-1',
        }),
        const LobbyInvitePreviewRoute(recordId: 'record-1').location,
      );
    });

    test(
      'lobby invite without a record id falls back to the shell-nested Lobby hub',
      () {
        expect(
          resolveNotificationLocation({'kind': 'lobby_invite'}),
          const ManageLobbyRoute().location,
        );
      },
    );

    test('classifies push-only vs. shell-nested locations', () {
      expect(
        isPushOnlyNotificationLocation(const UserRoute(id: 'user-1').location),
        isTrue,
      );
      expect(
        isPushOnlyNotificationLocation(
          const LobbyInvitePreviewRoute(recordId: 'record-1').location,
        ),
        isTrue,
      );
      expect(
        isPushOnlyNotificationLocation(const ManageLobbyRoute().location),
        isFalse,
      );
      expect(
        isPushOnlyNotificationLocation(
          const LobbyDetailRoute(id: 'lobby-1').location,
        ),
        isFalse,
      );
      expect(
        isPushOnlyNotificationLocation(const ManageScheduleRoute().location),
        isFalse,
      );
    });
  });
}
