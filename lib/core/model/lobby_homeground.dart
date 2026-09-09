/// One of a lobby's homegrounds — a plain RPC/embed-shaped row (no build_runner).
class LobbyHomeground {
  final String id;
  final String name;
  final bool isPrimary;
  final double? lat;
  final double? lon;

  const LobbyHomeground({
    required this.id,
    required this.name,
    required this.isPrimary,
    this.lat,
    this.lon,
  });

  factory LobbyHomeground.fromJson(Map<String, dynamic> json) =>
      LobbyHomeground(
        id: json['id'] as String,
        name: json['name'] as String,
        isPrimary: json['is_primary'] as bool? ?? false,
        lat: (json['lat'] as num?)?.toDouble(),
        lon: (json['lon'] as num?)?.toDouble(),
      );
}
