import 'package:flutter_test/flutter_test.dart';
import 'package:passe/router.dart';

void main() {
  group('Manage lobby card routes', () {
    test('member schedule shortcut only opens Planner', () {
      expect(
        const LobbyDetailRoute(id: 'lobby-1', tab: 1).location,
        '/manage/lobby/lobby-1?tab=1',
      );
    });

    test('manager schedule shortcut carries the planner-sheet intent', () {
      expect(
        const LobbyDetailRoute(
          id: 'lobby-1',
          tab: 1,
          openActivityPlanner: true,
        ).location,
        '/manage/lobby/lobby-1?tab=1&open-activity-planner=true',
      );
    });
  });
}
