import 'package:flutter_test/flutter_test.dart';
import 'package:passe/manage_tab/lobby_section/activity/upcoming_controller.dart';

void main() {
  Map<String, dynamic> embed(String status) => {
    'id': 'c-1',
    'status': status,
    'target_lobby_id': 'home',
    'agreed_cost': null,
    'initiator': {'name': 'Away', 'mmr': 1000},
    'target': {'name': 'Home', 'mmr': 1000},
  };

  group('ChallengeContext', () {
    test('a declined, lapsed or withdrawn fixture is dead', () {
      for (final status in ['declined', 'lapsed', 'cancelled']) {
        final ctx = ChallengeContext.fromEmbed(embed(status), 'away')!;
        expect(ctx.isDead, isTrue, reason: status);
        expect(ctx.isSettled, isFalse, reason: status);
      }
    });

    test('a played or disputed fixture is settled, not dead', () {
      for (final status in ['played', 'disputed']) {
        final ctx = ChallengeContext.fromEmbed(embed(status), 'away')!;
        expect(ctx.isSettled, isTrue, reason: status);
        expect(ctx.isDead, isFalse, reason: status);
      }
    });

    test('a live fixture is neither', () {
      for (final status in [
        'requested',
        'pending_home',
        'scheduled',
        'no_show_claimed',
        'awaiting_reports',
      ]) {
        final ctx = ChallengeContext.fromEmbed(embed(status), 'away')!;
        expect(ctx.isDead || ctx.isSettled, isFalse, reason: status);
      }
    });
  });
}
