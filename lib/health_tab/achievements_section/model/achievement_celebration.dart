/// Parsed result of the `evaluate_achievements` RPC — the celebration payload
/// surfaced after a sync that unlocked badges and/or leveled the user up.
class AchievementCelebration {
  final List<UnlockedBadge> unlocked;
  final int level;
  final int previousLevel;
  final int xpTotal;
  final int xpGained;

  const AchievementCelebration({
    required this.unlocked,
    required this.level,
    required this.previousLevel,
    required this.xpTotal,
    required this.xpGained,
  });

  bool get leveledUp => level > previousLevel;

  /// Nothing to celebrate (no new badges, no level-up).
  bool get isEmpty => unlocked.isEmpty && !leveledUp;

  static int _int(Object? v) => switch (v) {
    null => 0,
    final num n => n.toInt(),
    _ => int.tryParse(v.toString()) ?? 0,
  };

  factory AchievementCelebration.fromRpc(Map<String, dynamic> json) {
    final raw = (json['newly_unlocked'] as List?) ?? const [];
    return AchievementCelebration(
      unlocked: raw
          .map((e) => UnlockedBadge.fromJson(e as Map<String, dynamic>))
          .toList(),
      level: _int(json['level']),
      previousLevel: _int(json['previous_level']),
      xpTotal: _int(json['xp_total']),
      xpGained: _int(json['xp_gained']),
    );
  }
}

class UnlockedBadge {
  final String code;
  final String name;
  final int xp;
  final int difficulty;
  final int consistency;
  final bool repeatable;

  const UnlockedBadge({
    required this.code,
    required this.name,
    required this.xp,
    required this.difficulty,
    required this.consistency,
    required this.repeatable,
  });

  factory UnlockedBadge.fromJson(Map<String, dynamic> j) => UnlockedBadge(
    code: j['code'] as String? ?? '',
    name: j['name'] as String? ?? '',
    xp: AchievementCelebration._int(j['xp']),
    difficulty: AchievementCelebration._int(j['difficulty']),
    consistency: AchievementCelebration._int(j['consistency']),
    repeatable: j['repeatable'] as bool? ?? false,
  );
}
