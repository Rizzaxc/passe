import 'dart:convert';
import 'dart:io';

import 'package:diacritic/diacritic.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passe/core/model/enum.dart';

/// Emits `tool/venue/data/districts.json` — the ward list the Python venue
/// importer matches OSM boundary names against.
///
/// This is a test rather than a `dart run` script because `enum.dart` imports
/// `package:flutter`, so a bare Dart VM entrypoint cannot resolve `dart:ui`.
/// `flutter test` can.
///
/// **Generating it beats copying it.** A hand-maintained JSON is exactly the
/// failure already on record in this repo: `schema/mocked_seed.sql` still
/// seeds `hcm_q1`-style ids that stopped resolving at the 2025 ward reform,
/// because a copy drifted from the source. The assertions below make the
/// coupling loud — an enum edit that breaks the importer's contract fails the
/// normal `flutter test` run instead of silently desyncing a batch job nobody
/// runs for months.
void main() {
  test('district fixture matches enum.dart and stays the expected shape', () {
    final byCity = VietnamLocationData.instance.getAllDistricts();
    final hcmc = byCity[City.hochiminh]!;
    final hanoi = byCity[City.hanoi]!;

    // Counts are load-bearing: the importer trims ~200 out-of-footprint OSM
    // wards purely by failing to match them against this list, so a silent
    // shrink here would silently widen the app's geographic scope.
    expect(hcmc.length, 102, reason: 'HCMC ward count changed');
    expect(hanoi.length, 126, reason: 'Hanoi ward count changed');

    final all = [...hcmc, ...hanoi];
    expect(
      all.map((d) => d.id).toSet().length,
      all.length,
      reason: 'district ids must be unique across both cities',
    );

    // The importer matches on this normalization; if two wards in one city
    // collapse to the same key, it cannot tell them apart and would assign
    // venues arbitrarily between them.
    for (final city in [hcmc, hanoi]) {
      final keys = city.map((d) => _normalize(d.name)).toList();
      expect(
        keys.toSet().length,
        keys.length,
        reason: 'normalized ward names collide within a city',
      );
    }

    final rows = [
      for (final d in all)
        {
          'id': d.id,
          'name': d.name,
          'name_key': _normalize(d.name),
          'city': d.city.shorthand,
          'city_cluster': d.city.dbIndex,
          'type': d.type.name,
          'prefix': d.type.prefix,
          'legacy': d.legacyDistrict,
        },
    ];

    final out = File('tool/venue/data/districts.json');
    out.parent.createSync(recursive: true);
    out.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(rows)}\n',
    );
  });
}

/// Must stay byte-identical in behaviour to `_normalize` in
/// `tool/venue/wards.py` — the two halves of the same join key.
String _normalize(String raw) {
  var s = raw.trim();
  // `đ`/`Đ` is a distinct letter, not a diacritic — `removeDiacritics` leaves
  // it alone, so Python's NFD strip and this must both special-case it.
  s = s.replaceAll('đ', 'd').replaceAll('Đ', 'D');
  s = removeDiacritics(s).toLowerCase();
  return s.replaceAll(RegExp(r'[^a-z0-9]+'), '');
}
