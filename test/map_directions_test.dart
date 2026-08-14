import 'package:flutter_test/flutter_test.dart';
import 'package:passe/core/map_directions.dart';

void main() {
  group('map directions URIs', () {
    const lat = 10.776;
    const lon = 106.7;

    test('Apple Maps URL contains a destination and no search query', () {
      final uri = appleMapsDirectionsUri(destination: '$lat,$lon');

      expect(uri.host, 'maps.apple.com');
      expect(uri.queryParameters['daddr'], '10.776,106.7');
      expect(uri.queryParameters['dirflg'], 'd');
      expect(uri.queryParameters.containsKey('q'), isFalse);
    });

    test('Google Maps app URL requests driving directions', () {
      final uri = googleMapsAppDirectionsUri(destination: '$lat,$lon');

      expect(uri.scheme, 'comgooglemaps');
      expect(uri.queryParameters['daddr'], '10.776,106.7');
      expect(uri.queryParameters['directionsmode'], 'driving');
    });

    test('Google Maps web fallback opens directions instead of search', () {
      final uri = googleMapsWebDirectionsUri(destination: '$lat,$lon');

      expect(uri.path, '/maps/dir/');
      expect(uri.queryParameters['api'], '1');
      expect(uri.queryParameters['destination'], '10.776,106.7');
      expect(uri.queryParameters['travelmode'], 'driving');
    });

    test('Android geo URI safely encodes the venue label', () {
      final uri = androidGeoDirectionsUri(
        lat: lat,
        lon: lon,
        destination: '$lat,$lon',
        label: 'Sân A & B',
      );

      expect(uri.scheme, 'geo');
      expect(uri.queryParameters['q'], '10.776,106.7(Sân A & B)');
    });

    test('Android geo URI omits empty label parentheses', () {
      final uri = androidGeoDirectionsUri(
        lat: lat,
        lon: lon,
        destination: '$lat,$lon',
        label: '  ',
      );

      expect(uri.queryParameters['q'], '10.776,106.7');
    });

    test('falls back from missing coordinates to address, then name', () {
      expect(
        mapDirectionsDestination(
          address: '  12 Nguyễn Huệ, Quận 1  ',
          label: 'Sân trung tâm',
        ),
        '12 Nguyễn Huệ, Quận 1',
      );
      expect(
        mapDirectionsDestination(address: ' ', label: ' Sân trung tâm '),
        'Sân trung tâm',
      );
    });

    test('map URLs encode a custom address safely', () {
      const address = '12 Nguyễn Huệ & Lê Lợi, Quận 1';

      expect(
        appleMapsDirectionsUri(destination: address).queryParameters['daddr'],
        address,
      );
      expect(
        googleMapsAppDirectionsUri(
          destination: address,
        ).queryParameters['daddr'],
        address,
      );
      expect(
        googleMapsWebDirectionsUri(
          destination: address,
        ).queryParameters['destination'],
        address,
      );
    });

    test('Android uses an address query without coordinates', () {
      const address = '12 Nguyễn Huệ & Lê Lợi, Quận 1';
      final uri = androidGeoDirectionsUri(destination: address);

      expect(uri.toString(), startsWith('geo:0,0?q='));
      expect(uri.queryParameters['q'], address);
    });
  });
}
