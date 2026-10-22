import 'package:flutter_test/flutter_test.dart';
import 'package:passe/manage_tab/lobby_section/activity/getting_started_card.dart';
import 'package:passe/manage_tab/lobby_section/schedule_activity_controller.dart';

void main() {
  group('defaultConfirmationThreshold', () {
    test('never asks for more people than the lobby has', () {
      expect(defaultConfirmationThreshold(1), 1);
      expect(defaultConfirmationThreshold(2), 2);
      expect(defaultConfirmationThreshold(3), 3);
    });

    test('caps at 4 for bigger lobbies', () {
      expect(defaultConfirmationThreshold(4), 4);
      expect(defaultConfirmationThreshold(25), 4);
    });

    test('never drops below 1', () {
      expect(defaultConfirmationThreshold(0), 1);
    });
  });

  group('thresholdEnabledByDefault', () {
    test('off for small lobbies, so a first session cannot auto-cancel', () {
      for (final n in [0, 1, 2, 3]) {
        expect(thresholdEnabledByDefault(n), isFalse, reason: '$n members');
      }
    });

    test('on from 4 members', () {
      expect(thresholdEnabledByDefault(4), isTrue);
      expect(thresholdEnabledByDefault(12), isTrue);
    });
  });

  group('GettingStartedProgress', () {
    test('a fresh lobby has nothing done', () {
      final p = GettingStartedProgress.from(memberCount: 1, upcomingCount: 0);
      expect(p.doneCount, 0);
      expect(p.isComplete, isFalse);
    });

    test('ticks from real data', () {
      final p = GettingStartedProgress.from(memberCount: 3, upcomingCount: 0);
      expect(p.hasMembers, isTrue);
      expect(p.hasActivity, isFalse);
      expect(p.doneCount, 1);
      expect(
        GettingStartedProgress.from(
          memberCount: 2,
          upcomingCount: 1,
        ).isComplete,
        isTrue,
      );
    });

    test('a lobby whose sessions are all past has scheduled already', () {
      final p = GettingStartedProgress.from(
        memberCount: 2,
        upcomingCount: 0,
        hasScheduledBefore: true,
      );
      expect(p.hasActivity, isTrue);
      expect(p.isComplete, isTrue);
    });
  });
}
