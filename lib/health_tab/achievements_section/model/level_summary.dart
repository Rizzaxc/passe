import 'package:freezed_annotation/freezed_annotation.dart';

part 'level_summary.freezed.dart';
part 'level_summary.g.dart';

/// The user's global fitness level, from the `user_level_summary` RPC. The XP
/// curve lives only in SQL — the client just renders the floors it returns.
@freezed
abstract class LevelSummary with _$LevelSummary {
  const LevelSummary._();

  const factory LevelSummary({
    required int level,
    @JsonKey(name: 'xp_total') required int xpTotal,
    @JsonKey(name: 'current_floor') required int currentFloor,
    @JsonKey(name: 'next_floor') int? nextFloor,
  }) = _LevelSummary;

  factory LevelSummary.fromJson(Map<String, dynamic> json) =>
      _$LevelSummaryFromJson(json);

  /// Level cap reached (no next floor).
  bool get isMaxed => nextFloor == null;

  /// XP banked into the current level.
  int get xpIntoLevel => xpTotal - currentFloor;

  /// XP span of the current level.
  int get xpForLevel => isMaxed ? 0 : nextFloor! - currentFloor;

  /// 0–1 progress toward the next level.
  double get progress {
    if (isMaxed || xpForLevel <= 0) return 1.0;
    return (xpIntoLevel / xpForLevel).clamp(0.0, 1.0);
  }
}
