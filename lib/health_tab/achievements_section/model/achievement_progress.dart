import 'package:freezed_annotation/freezed_annotation.dart';

part 'achievement_progress.freezed.dart';
part 'achievement_progress.g.dart';

/// Per-badge state from the `achievement_progress` RPC.
enum AchievementState {
  notStarted,
  inProgress,
  earnedPeriod, // repeatable, completed this period (resets next)
  done, // one-time, unlocked forever
}

/// Supabase returns `numeric` columns as `String` — parse defensively.
double _toDouble(Object? v) => switch (v) {
      null => 0,
      final num n => n.toDouble(),
      _ => double.tryParse(v.toString()) ?? 0,
    };

int _toInt(Object? v) => switch (v) {
      null => 0,
      final num n => n.toInt(),
      _ => int.tryParse(v.toString()) ?? 0,
    };

AchievementState _toState(Object? v) => switch (v) {
      'earned_period' => AchievementState.earnedPeriod,
      'done' => AchievementState.done,
      'in_progress' => AchievementState.inProgress,
      _ => AchievementState.notStarted,
    };

@freezed
abstract class AchievementProgress with _$AchievementProgress {
  const AchievementProgress._();

  const factory AchievementProgress({
    @JsonKey(name: 'achievement_id') required String achievementId,
    required String code,
    required String name,
    String? description,
    @JsonKey(fromJson: _toInt) required int difficulty,
    @JsonKey(fromJson: _toInt) required int consistency,
    @JsonKey(name: 'xp_reward', fromJson: _toInt) required int xpReward,
    required bool repeatable,
    @JsonKey(name: 'current_value', fromJson: _toDouble) required double currentValue,
    @JsonKey(fromJson: _toDouble) required double threshold,
    @JsonKey(fromJson: _toDouble) required double progress,
    @JsonKey(fromJson: _toState) required AchievementState state,
    @JsonKey(name: 'period_key') required String periodKey,
  }) = _AchievementProgress;

  factory AchievementProgress.fromJson(Map<String, dynamic> json) =>
      _$AchievementProgressFromJson(json);

  /// Combined tier magnitude (difficulty × consistency) — the secondary sort key
  /// and the reward-grid corner.
  int get tier => difficulty * consistency;

  bool get isEarned =>
      state == AchievementState.earnedPeriod || state == AchievementState.done;
}
