import 'package:flutter_test/flutter_test.dart';
import 'package:passe/core/feature_flags.dart';
import 'package:passe/home_tab/main.dart';
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
        const HomeTeammateRoute().location,
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

  test('Discover route indices match the enabled tab count', () {
    expect(HomeTab.locationIndex, HomeTab.tabCount - 1);
    expect(HomeTab.professionalIndex, lessThan(HomeTab.tabCount));
    expect(HomeTab.tabCount, ClientFeatureFlags.challengerFlow ? 5 : 4);
  });
}
