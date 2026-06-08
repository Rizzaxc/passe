import 'enum.dart';
import 'lobby.dart';
import 'timeslot.dart';

class LobbyFeedItem {
  final String id;
  final String name;
  final String? homegroundName;
  final List<Timeslot> playtime;
  final LobbyDetails? details;
  final LobbyVisibility visibility;
  final int timeslotCompatScore;
  final double profileCompatScore;
  final int? memberCount;

  /// Challenger feed only: this lobby's cached MMR.
  final int? lobbyMmr;

  /// Challenger feed only: how the matchup leans for the context (away) lobby.
  final ChallengeFavorability? favorability;

  const LobbyFeedItem({
    required this.id,
    required this.name,
    this.homegroundName,
    required this.playtime,
    this.details,
    required this.visibility,
    required this.timeslotCompatScore,
    required this.profileCompatScore,
    this.memberCount,
    this.lobbyMmr,
    this.favorability,
  });

  factory LobbyFeedItem.fromJson(Map<String, dynamic> json) {
    final rawPlaytime = json['playtime'];
    final playtime = <Timeslot>[];
    if (rawPlaytime is List) {
      for (final e in rawPlaytime) {
        if (e is Map<String, dynamic>) playtime.add(Timeslot.fromJson(e));
      }
    }
    return LobbyFeedItem(
      id: json['id'] as String,
      name: json['name'] as String,
      homegroundName: json['homeground_name'] as String?,
      playtime: playtime,
      details: json['details'] is Map<String, dynamic>
          ? LobbyDetails.fromJson(json['details'] as Map<String, dynamic>)
          : null,
      visibility: LobbyVisibility.values.firstWhere(
        (v) => v.name == (json['visibility'] as String?),
        orElse: () => LobbyVisibility.discoverable,
      ),
      timeslotCompatScore: (json['timeslot_compat_score'] as num?)?.toInt() ?? 0,
      profileCompatScore:
          double.tryParse(json['profile_compat_score']?.toString() ?? '') ?? 0,
      memberCount: (json['member_count'] as num?)?.toInt(),
      lobbyMmr: (json['lobby_mmr'] as num?)?.toInt(),
      favorability:
          ChallengeFavorability.fromValue(json['favorability'] as String?),
    );
  }
}
