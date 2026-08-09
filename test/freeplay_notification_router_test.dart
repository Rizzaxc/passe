import 'package:flutter_test/flutter_test.dart';
import 'package:passe/notifications/notification_router.dart';
import 'package:passe/router.dart';

void main() {
  test(
    'Freeplay request and chat notifications deep-link to their request chat',
    () {
      final location = resolveNotificationLocation({
        'kind': 'freeplay_chat_message',
        'activity_id': 'activity-1',
        'request_id': 'request-1',
      });

      expect(
        location,
        FreeplayChatRoute(
          activityId: 'activity-1',
          requestId: 'request-1',
        ).location,
      );
    },
  );

  test('cancelled Freeplay activity opens its retained detail', () {
    expect(
      resolveNotificationLocation({
        'kind': 'freeplay_activity_cancelled',
        'activity_id': 'activity-1',
      }),
      const FreeplayDetailRoute(id: 'activity-1').location,
    );
  });
}
