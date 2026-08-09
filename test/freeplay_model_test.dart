import 'package:flutter_test/flutter_test.dart';
import 'package:passe/freeplay/model.dart';

void main() {
  test('parses Supabase numeric values and request state', () {
    final activity = FreeplayActivity.fromJson({
      'activity_id': 'activity-1',
      'host_id': 'host-1',
      'host_name': 'Host An',
      'description': 'Đánh đôi',
      'start_time': '2026-08-10T11:00:00Z',
      'end_time': '2026-08-10T13:00:00Z',
      'venue_name': 'Sân A',
      'street_address': '1 Đường A',
      'capacity': 4,
      'accepted_count': 3,
      'pending_count': 2,
      'male_price': '120000.00',
      'female_price': '100000.00',
      'recommended_skills': ['casual'],
      'my_request_id': 'request-1',
      'my_request_status': 'accepted',
      'intake_closed': false,
      'cancelled': false,
    });

    expect(activity.seatsLeft, 1);
    expect(activity.pendingCount, 2);
    expect(activity.malePrice, 120000);
    expect(activity.femalePrice, 100000);
    expect(activity.myRequestStatus, FreeplayRequestStatus.accepted);
  });

  test('maps host_cancelled and nested payment info', () {
    expect(
      FreeplayRequestStatus.fromDb('host_cancelled'),
      FreeplayRequestStatus.hostCancelled,
    );

    final message = FreeplayChatMessage.fromJson({
      'id': 'message-1',
      'kind': 'payment_info',
      'created_at': '2026-08-10T11:00:00Z',
      'payment_info': {
        'bank_id': '970436',
        'bank_display_name': 'Vietcombank',
        'value': '0123456789',
        'account_name': 'NGUYEN VAN A',
      },
    });

    expect(message.bankDisplayName, 'Vietcombank');
    expect(message.accountNumber, '0123456789');
  });
}
