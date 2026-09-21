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
  // Added with the venue re-scrape, which now pulls leisure=track.
  'track',
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
    // Structured replacements for the raw `tags` parsing below, populated by
    // tool/venue (schema/location_sport_tags.sql). Every getter prefers these
    // and falls back to `tags`, so a row the importer hasn't reached, a
    // `user_submitted` row (create_location writes no tags at all), and any
    // stale cached JSON all keep behaving exactly as before.
    @JsonKey(name: 'sport_ids') @Default(<int>[]) List<int> sportIds,
    @JsonKey(name: 'amenity_kinds')
    @Default(<String>[])
    List<String> amenityKinds,
    @JsonKey(name: 'has_declared_sport') @Default(false) bool declaredSport,
    /// The pre-normalization `district` value (an old "Quận X" label). Display
    /// and grouping only — `district` is the canonical ward id.
    @JsonKey(name: 'district_legacy') String? districtLegacy,
  }) = _Location;

  factory Location.fromJson(Map<String, dynamic> json) =>
      _$LocationFromJson(json);

  /// The venue's map coordinate, or `null` when the row has no geocoding yet
  /// (community/roadmap data is often incomplete). Guard map pins on this.
  LatLng? get coord => (lat != null && lon != null) ? LatLng(lat!, lon!) : null;

  /// `name` is a required DB column but ~20% of scraped rows store it as an
  /// empty string (no null in the data, just blank text) — every one of
  /// those rows still has an address, so the card falls back to a localized
  /// placeholder rather than rendering a blank title.
  bool get hasName => name.trim().isNotEmpty;

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
      declaredSport ||
      _parsedTags.containsKey('sport') ||
      tags.any((t) => !t.contains(':') && _osmSportToAppSport.containsKey(t));

  /// The Passe [Sport]s this venue's tags claim to support. Empty if
  /// untagged, or only tagged with sports outside Passe's 5 (e.g. swimming,
  /// volleyball).
  Set<Sport> get sports {
    if (sportIds.isNotEmpty) {
      return sportIds
          .map((i) => i >= 0 && i < Sport.values.length ? Sport.values[i] : null)
          .whereType<Sport>()
          .toSet();
    }
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

  /// A descriptive stand-in for a venue the map never named, built from what
  /// the row does have: its facility kind and its street or ward.
  ///
  /// 406 of 2,050 rows (20%) store `name = ''` — real, correctly geocoded
  /// places OSM simply never labelled. Rendering all of them as one identical
  /// "Địa điểm chưa đặt tên" next to an identical generic pin is what makes
  /// the venue list look broken, so this distinguishes them by what they
  /// actually are: "Sân cầu lông — Đ. Nguyễn Hữu Cảnh".
  ///
  /// **Client-side only, and deliberately never written back.** Callers must
  /// keep rendering this in the same secondary treatment as the old
  /// placeholder — it is a description, not a claimed name, and presenting a
  /// generated string as the venue's real name is worse than admitting we
  /// don't know it. A member who *does* know the name can supply one through
  /// `set_lobby_location_alias`, which stays scoped to their lobby.
  String describe({
    required String Function(String key) tr,
    String? lobbyAlias,
  }) {
    final alias = lobbyAlias?.trim();
    if (alias != null && alias.isNotEmpty) return alias;
    if (hasName) return name;

    final kind = sports.length == 1
        ? tr('sport.${sports.first.name}')
        : amenityKeys.isNotEmpty
        ? tr('homeTab.location.amenity.${amenityKeys.first}')
        : null;
    final where = (streetName?.trim().isNotEmpty ?? false)
        ? streetName!.trim()
        : (district?.trim().isNotEmpty ?? false)
        // `district` may hold a canonical ward id (`hcm_ankhanh`) rather than
        // a human label after the ward backfill; those are not showable, so
        // fall back rather than print an id at the user.
        ? (district!.contains('_') ? null : district!.trim())
        : null;

    if (kind == null && where == null) return tr('homeTab.location.unnamed');
    if (kind == null) return where!;
    if (where == null) return kind;
    return '$kind — $where';
  }

  /// Recognized facility labels from the `leisure:[...]` tag, as
  /// `homeTab.location.amenity.<value>` translation-key suffixes — e.g.
  /// `["pitch", "sports_centre"]`. Unrecognized/administrative tags are
  /// dropped rather than shown as raw OSM junk.
  List<String> get amenityKeys => amenityKinds.isNotEmpty
      ? amenityKinds
      : [
          for (final l in _parsedTags['leisure'] ?? const <String>[])
            if (_recognizedLeisure.contains(l)) l,
        ];
}
