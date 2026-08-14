import 'package:flutter_test/flutter_test.dart';
import 'package:passe/course/model.dart';
import 'package:passe/freeplay/model.dart';

void main() {
  const locationFields = {
    'location_id': '0f7ad853-a941-4b9a-9cac-c3d55de6ba54',
    'venue_name': 'Sân Nguyễn Huệ',
    'street_address': '12 Nguyễn Huệ, Phường Sài Gòn, Hồ Chí Minh',
    'location_street_number': '12',
    'location_street_name': 'Nguyễn Huệ',
    'location_district': 'Phường Sài Gòn',
    'location_city': 'Hồ Chí Minh',
    'location_lat': 10.7731,
    'location_lon': 106.7032,
  };

  test('Course session preserves complete location details', () {
    final session = CourseSession.fromJson({
      'activity_id': 'course-activity',
      'start_time': '2026-08-20T10:00:00Z',
      'end_time': '2026-08-20T11:00:00Z',
      'proposal_status': 'approved',
      ...locationFields,
    });

    expect(session.locationId, locationFields['location_id']);
    expect(session.venueName, locationFields['venue_name']);
    expect(session.streetAddress, locationFields['street_address']);
    expect(session.locationStreetNumber, '12');
    expect(session.locationDistrict, 'Phường Sài Gòn');
    expect(session.locationLat, 10.7731);
    expect(session.locationLon, 106.7032);
  });

  test('Freeplay activity preserves complete location details', () {
    final activity = FreeplayActivity.fromJson({
      'activity_id': 'freeplay-activity',
      'host_id': 'host',
      'host_name': 'Host',
      'description': '',
      'start_time': '2026-08-20T10:00:00Z',
      'end_time': '2026-08-20T11:00:00Z',
      'capacity': 4,
      'accepted_count': 0,
      'male_price': '100000',
      'female_price': '100000',
      'recommended_skills': ['casual'],
      ...locationFields,
    });

    expect(activity.locationId, locationFields['location_id']);
    expect(activity.venueName, locationFields['venue_name']);
    expect(activity.streetAddress, locationFields['street_address']);
    expect(activity.locationStreetName, 'Nguyễn Huệ');
    expect(activity.locationCity, 'Hồ Chí Minh');
    expect(activity.locationLat, 10.7731);
    expect(activity.locationLon, 106.7032);
  });
}
