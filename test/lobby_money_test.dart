import 'package:flutter_test/flutter_test.dart';
import 'package:passe/manage_tab/lobby_section/activity/feed.dart';
import 'package:passe/manage_tab/lobby_section/activity/money_controller.dart';

void main() {
  test('keeps repeated activity dates as separate signed entries', () {
    final balance = LobbyMoneyBalance.fromJson({
      'counterparty_id': 'member-2',
      'username': 'Bình',
      'generated_avatar': null,
      'signed_total': '-60000.00',
      'entries': [
        {
          'obligation_id': 'bill-1',
          'activity_date': '2026-08-12T10:00:00Z',
          'signed_amount': -100000,
        },
        {
          'obligation_id': 'bill-2',
          'activity_date': '2026-08-12T10:00:00Z',
          'signed_amount': 40000,
        },
      ],
    });

    expect(balance.signedTotal, -60000);
    expect(balance.entries, hasLength(2));
    expect(balance.entries.map((entry) => entry.id), ['bill-1', 'bill-2']);
    expect(balance.entries.map((entry) => entry.signedAmount), [
      -100000,
      40000,
    ]);
  });

  test('payment request status is authoritative with a legacy fallback', () {
    PaymentPayee parse(Map<String, dynamic> values) => PaymentPayee.fromJson({
      'user_id': 'member-1',
      'username': 'An',
      'generated_avatar': null,
      'amount_owed': 10000,
      ...values,
    });

    expect(
      parse({'status': 'outstanding'}).status,
      PaymentPayeeStatus.outstanding,
    );
    expect(
      parse({'status': 'paid_direct'}).status,
      PaymentPayeeStatus.paidDirect,
    );
    expect(
      parse({'status': 'cleared_together'}).status,
      PaymentPayeeStatus.clearedTogether,
    );
    expect(parse({'paid': true}).status, PaymentPayeeStatus.paidDirect);
  });
}
