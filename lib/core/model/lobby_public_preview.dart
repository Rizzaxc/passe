import 'enum.dart';
import 'lobby_feed_item.dart';
import 'lobby_homeground.dart';
import 'network.dart';
import 'timeslot.dart';

/// Aggregated member gender makeup for [LobbyPublicPreview]. `unknown` counts
/// members who never declared a gender — excluded from [declared] so the
/// makeup bar's denominator is "members who said something", not everyone.
class LobbyGenderBreakdown {
  final int male;
  final int female;
  final int unknown;

  const LobbyGenderBreakdown({
    required this.male,
    required this.female,
    required this.unknown,
  });

  int get declared => male + female;

  factory LobbyGenderBreakdown.fromJson(Map<String, dynamic> json) {
    return LobbyGenderBreakdown(
      male: (json['male'] as num?)?.toInt() ?? 0,
      female: (json['female'] as num?)?.toInt() ?? 0,
      unknown: (json['unknown'] as num?)?.toInt() ?? 0,
    );
  }
}

/// One entry in [LobbyPublicPreview.topNetworks] — a network represented
/// among the lobby's members, ranked by how many members share it.
class LobbyNetworkStat {
  final int id;
  final String name;
  final NetworkCategory category;
  final int count;

  const LobbyNetworkStat({
    required this.id,
    required this.name,
    required this.category,
    required this.count,
  });

  factory LobbyNetworkStat.fromJson(Map<String, dynamic> json) {
    return LobbyNetworkStat(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      category: NetworkCategory.fromString(json['category'] as String?),
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// One entry in [LobbyPublicPreview.topIndustries].
class LobbyIndustryStat {
  final Industry industry;
  final int count;

  const LobbyIndustryStat({required this.industry, required this.count});

  factory LobbyIndustryStat.fromJson(Map<String, dynamic> json) {
    final id = (json['industry_id'] as num).toInt();
    return LobbyIndustryStat(
      industry: Industry.values[id],
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// The response shape of the `get_lobby_public_preview` RPC — everything the
/// Discover card's public preview sheet shows for a lobby, reachable by
/// guests and non-members alike. Hand-written (not freezed), matching
/// [LobbyFeedItem]'s convention for one-off RPC-response composites.
class LobbyPublicPreview {
  final String id;
  final String name;
  final Sport sport;
  final String? description;
  final int memberCount;
  final List<Timeslot> playtime;
  final String? homegroundName;
  final double? homegroundLat;
  final double? homegroundLon;
  final List<LobbyHomeground> homegrounds;
  final int mmr;
  final int ratedMatchCount;
  final LobbyGenderBreakdown gender;
  final Map<AgeGroup, int> ageGroupCounts;
  final int ageGroupUnknownCount;
  final List<LobbyNetworkStat> topNetworks;
  final List<LobbyIndustryStat> topIndustries;

  const LobbyPublicPreview({
    required this.id,
    required this.name,
    required this.sport,
    this.description,
    required this.memberCount,
    required this.playtime,
    this.homegroundName,
    this.homegroundLat,
    this.homegroundLon,
    this.homegrounds = const [],
    required this.mmr,
    required this.ratedMatchCount,
    required this.gender,
    required this.ageGroupCounts,
    required this.ageGroupUnknownCount,
    required this.topNetworks,
    required this.topIndustries,
  });

  /// Below this many rated matches, [mmr] is still essentially the
  /// self-declared seed average — same threshold as [LobbyFeedItem].
  bool get hasProvisionalMmr =>
      ratedMatchCount < LobbyFeedItem.provisionalMatchThreshold;

  bool get hasCoord => homegroundLat != null && homegroundLon != null;

  factory LobbyPublicPreview.fromJson(Map<String, dynamic> json) {
    final rawPlaytime = json['playtime'];
    final playtime = <Timeslot>[];
    if (rawPlaytime is List) {
      for (final e in rawPlaytime) {
        if (e is Map<String, dynamic>) playtime.add(Timeslot.fromJson(e));
      }
    }

    final ageGroupCounts = <AgeGroup, int>{};
    var ageGroupUnknownCount = 0;
    final rawAge = json['age_group_breakdown'];
    if (rawAge is Map) {
      for (final entry in rawAge.entries) {
        final count = (entry.value as num?)?.toInt() ?? 0;
        final ageGroup = AgeGroup.values
            .where((a) => a.name == entry.key)
            .firstOrNull;
        if (ageGroup != null) {
          ageGroupCounts[ageGroup] = count;
        } else {
          ageGroupUnknownCount += count;
        }
      }
    }

    return LobbyPublicPreview(
      id: json['id'] as String,
      name: json['name'] as String,
      sport: Sport.values[(json['sport_id'] as num).toInt()],
      description: json['description'] as String?,
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
      playtime: playtime,
      homegroundName: json['homeground_name'] as String?,
      homegroundLat: (json['homeground_lat'] as num?)?.toDouble(),
      homegroundLon: (json['homeground_lon'] as num?)?.toDouble(),
      homegrounds: json['homegrounds'] is List
          ? (json['homegrounds'] as List)
                .whereType<Map<String, dynamic>>()
                .map(LobbyHomeground.fromJson)
                .toList()
          : const [],
      mmr: (json['mmr'] as num?)?.toInt() ?? 1000,
      ratedMatchCount: (json['rated_match_count'] as num?)?.toInt() ?? 0,
      gender: json['gender_breakdown'] is Map<String, dynamic>
          ? LobbyGenderBreakdown.fromJson(
              json['gender_breakdown'] as Map<String, dynamic>,
            )
          : const LobbyGenderBreakdown(male: 0, female: 0, unknown: 0),
      ageGroupCounts: ageGroupCounts,
      ageGroupUnknownCount: ageGroupUnknownCount,
      topNetworks: json['top_networks'] is List
          ? (json['top_networks'] as List)
                .whereType<Map<String, dynamic>>()
                .map(LobbyNetworkStat.fromJson)
                .toList()
          : const [],
      topIndustries: json['top_industries'] is List
          ? (json['top_industries'] as List)
                .whereType<Map<String, dynamic>>()
                .map(LobbyIndustryStat.fromJson)
                .toList()
          : const [],
    );
  }
}
