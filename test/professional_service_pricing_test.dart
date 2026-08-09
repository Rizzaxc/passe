import 'package:flutter_test/flutter_test.dart';
import 'package:passe/core/model/enum.dart';
import 'package:passe/core/model/professional_feed_item.dart';
import 'package:passe/professional/booking_controller.dart';

void main() {
  test('hourly service price scales with session duration', () {
    const service = ProfessionalServiceOption(
      id: 'service',
      serviceType: 'Coaching',
      priceAmount: 300000,
      minDurationMinutes: 60,
      maxParticipants: 6,
      sessionCount: 1,
      pricingKind: ProfessionalPricingKind.hourly,
    );

    expect(service.priceFor(const Duration(minutes: 90)), 450000);
  });

  test('per-session service price stays fixed for longer sessions', () {
    const service = ProfessionalServiceOption(
      id: 'service',
      serviceType: 'Coaching',
      priceAmount: 300000,
      minDurationMinutes: 60,
      maxParticipants: 6,
      sessionCount: 1,
      pricingKind: ProfessionalPricingKind.perSession,
    );

    expect(service.priceFor(const Duration(minutes: 90)), 300000);
  });

  test('professional feed preserves the price kind returned by the RPC', () {
    final item = ProfessionalFeedItem.fromJson({
      'id': 'professional',
      'display_name': 'Coach',
      'professional_role': 'coach',
      'sports': [1],
      'average_rating': '0',
      'review_count': 0,
      'is_verified': true,
      'price_from': '250000',
      'price_from_kind': 'per_session',
    });

    expect(item.priceFrom, 250000);
    expect(item.priceFromKind, ProfessionalPricingKind.perSession);
  });

  test('professional feed preserves discovery location signals', () {
    final item = ProfessionalFeedItem.fromJson({
      'id': 'professional',
      'display_name': 'Coach',
      'professional_role': 'coach',
      'sports': [1],
      'average_rating': '4.9',
      'review_count': 12,
      'is_verified': true,
      'preferred_city_cluster': 1,
      'preferred_districts': ['hcm_benthanh', 'hcm_banco'],
      'preferred_location_names': ['Sân Kỳ Hòa'],
    });

    expect(item.preferredCityCluster, 1);
    expect(item.preferredDistricts, ['hcm_benthanh', 'hcm_banco']);
    expect(item.preferredLocationNames, ['Sân Kỳ Hòa']);
  });
}
