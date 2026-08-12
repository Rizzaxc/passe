import 'package:flutter_test/flutter_test.dart';
import 'package:passe/core/format.dart';

void main() {
  group('Vietnamese VND formatting', () {
    test('groups digits and reads a whole amount', () {
      expect(formatVnd(350000), '350.000');
      expect(formatVndWords(350000), 'Ba trăm năm mươi nghìn đồng');
    });

    test('rounds fractional DB numerics and reads their absolute value', () {
      expect(formatVndWords(-50000.4), 'Năm mươi nghìn đồng');
      expect(formatVndWords(0), 'Không đồng');
    });
  });
}
