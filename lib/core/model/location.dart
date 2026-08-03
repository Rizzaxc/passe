import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:latlong2/latlong.dart';

import 'enum.dart';

part 'location.freezed.dart';
part 'location.g.dart';

String? _streetNumberFromJson(dynamic val) => val?.toString();

List<String> _tagsFromJson(dynamic val) =>
    val == null ? const [] : (val as List).map((e) => e.toString()).toList();

/// OSM `sport:[...]` values recognized as one of Passe's 5 supported sports.
/// Real venue data (scraped from a 3rd-party API) tags many other sports
/// (volleyball, swimming, table_tennis, etc.) that Passe doesn't support;
/// those are deliberately not mapped here.
const _osmSportToAppSport = {
  'soccer': Sport.soccer,
  'basketball': Sport.basketball,
  'badminton': Sport.badminton,
  'tennis': Sport.tennis,
  'pickleball': Sport.pickleball,
};

/// Recognized `leisure:[...]` facility values, mapped to a
/// `homeTab.location.amenity.<value>` translation key. Everything else in
/// the raw tag set (opening_hours, building:levels, website, wikidata, …) is
/// noise scraped along for-free from OSM and is dropped rather than shown.
const _recognizedLeisure = {
  'pitch',
  'sports_centre',
  'stadium',
  'swimming_pool',
};

/// Parses `Location.tags` into `key -> values`. Two formats coexist in prod:
/// scraped rows store `"key:[v1, v2]"` strings; the `mocked_` seed stores
/// bare values like `"soccer"` (handled separately by callers, not here).
/// Malformed entries (no `:`) are dropped.
Map<String, List<String>> _parseTags(List<String> raw) {
  final result = <String, List<String>>{};
  for (final entry in raw) {
    final colon = entry.indexOf(':');
    if (colon == -1) continue;
    var value = entry.substring(colon + 1).trim();
    if (value.startsWith('[') && value.endsWith(']')) {
      value = value.substring(1, value.length - 1);
    }
    final values = value
        .split(',')
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .toList();
    if (values.isNotEmpty) result[entry.substring(0, colon).trim()] = values;
  }
  return result;
}

@freezed
abstract class Location with _$Location {
  const Location._();

  const factory Location({
    required String id,
    required String name,
    @JsonKey(name: 'full_address') String? fullAddress,
    @JsonKey(name: 'street_number', fromJson: _streetNumberFromJson)
    String? streetNumber,
    @JsonKey(name: 'street_name') String? streetName,
    String? district,
    String? city,
    double? lat,
    double? lon,
    @JsonKey(fromJson: _tagsFromJson) @Default(<String>[]) List<String> tags,
    @JsonKey(name: 'city_cluster') int? cityCluster,
  }) = _Location;

  factory Location.fromJson(Map<String, dynamic> json) =>
      _$LocationFromJson(json);

  /// The venue's map coordinate, or `null` when the row has no geocoding yet
  /// (community/roadmap data is often incomplete). Guard map pins on this.
  LatLng? get coord => (lat != null && lon != null) ? LatLng(lat!, lon!) : null;

  /// Human-readable address assembled from the structured parts, falling back
  /// to the pre-joined [fullAddress] when present.
  String get displayAddress =>
      fullAddress ??
      [
        if (streetNumber != null) streetNumber,
        if (streetName != null) streetName,
        if (district != null) district,
        if (city != null) city,
      ].whereType<String>().join(', ');

  /// Cached result of [_parseTags], keyed by instance identity — computed
  /// once per instance instead of on every getter access (each venue card
  /// reads `sports`/`amenityKeys` multiple times per build, and the raw
  /// string parsing showed up as repeated main-thread work in the location
  /// feed). An `Expando` is used because `Location`'s generated constructor
  /// is `const`, which rules out a `late final` field.
  static final _tagCache = Expando<Map<String, List<String>>>();

  Map<String, List<String>> get _parsedTags =>
      _tagCache[this] ??= _parseTags(tags);

  /// Whether the raw tags declare a sport at all, regardless of whether any
  /// declared sport is one Passe supports. Used to distinguish "explicitly
  /// tagged for a different sport" (hide) from "no sport info" (keep — could
  /// still be a general facility).
  bool get hasDeclaredSport =>
      _parsedTags.containsKey('sport') ||
      tags.any((t) => !t.contains(':') && _osmSportToAppSport.containsKey(t));

  /// The Passe [Sport]s this venue's tags claim to support. Empty if
  /// untagged, or only tagged with sports outside Passe's 5 (e.g. swimming,
  /// volleyball).
  Set<Sport> get sports {
    final values = <String>{
      ...?_parsedTags['sport'],
      for (final t in tags)
        if (!t.contains(':') && _osmSportToAppSport.containsKey(t)) t,
    };
    return values.map((v) => _osmSportToAppSport[v]).whereType<Sport>().toSet();
  }

  /// Whether this venue is relevant to [sport] — matches if it declares
  /// [sport] among its tagged sports, or declares no sport at all (kept
  /// rather than hidden, since we can't confirm irrelevance).
  bool matchesSport(Sport sport) => !hasDeclaredSport || sports.contains(sport);

  /// Recognized facility labels from the `leisure:[...]` tag, as
  /// `homeTab.location.amenity.<value>` translation-key suffixes — e.g.
  /// `["pitch", "sports_centre"]`. Unrecognized/administrative tags are
  /// dropped rather than shown as raw OSM junk.
  List<String> get amenityKeys => [
    for (final l in _parsedTags['leisure'] ?? const <String>[])
      if (_recognizedLeisure.contains(l)) l,
  ];
}
