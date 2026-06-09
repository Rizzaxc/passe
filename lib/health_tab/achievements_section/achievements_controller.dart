import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/auth_controller.dart';
import '../../core/user_preferences.dart';
import 'model/achievement_celebration.dart';
import 'model/achievement_progress.dart';
import 'model/level_summary.dart';

part 'achievements_controller.g.dart';

/// Per-badge progress for the signed-in user (read-only; the evaluator runs on
/// sync, not here). Pull-to-refresh invalidates this.
@riverpod
Future<List<AchievementProgress>> achievementProgressList(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final rows = await Supabase.instance.client
      .rpc('achievement_progress', params: {'p_user_id': userId})
      .timeout(const Duration(seconds: 5));

  return (rows as List)
      .map((r) => AchievementProgress.fromJson(r as Map<String, dynamic>))
      .toList();
}

/// The user's global fitness level + XP floors for the header bar.
@riverpod
Future<LevelSummary> levelSummary(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  const empty = LevelSummary(level: 1, xpTotal: 0, currentFloor: 0, nextFloor: 50);
  if (userId == null) return empty;

  final rows = await Supabase.instance.client
      .rpc('user_level_summary', params: {'p_user_id': userId})
      .timeout(const Duration(seconds: 5));

  final list = rows as List;
  if (list.isEmpty) return empty;
  return LevelSummary.fromJson(list.first as Map<String, dynamic>);
}

/// Holds the most recent unlock/level-up payload from a sync, consumed and
/// cleared by the achievements subtab to show the celebration sheet.
@riverpod
class AchievementCelebrationController extends _$AchievementCelebrationController {
  @override
  AchievementCelebration? build() => null;

  void show(AchievementCelebration celebration) => state = celebration;
  void clear() => state = null;
}

/// Whether there are unlocked-but-unseen achievements (drives the trophy-tab
/// dot). Persisted so it survives an app close before the user looks.
@riverpod
class UnseenAchievements extends _$UnseenAchievements {
  static const _prefKey = 'achievements_unseen';

  @override
  Future<bool> build() async =>
      await UserPreferences.instance.getBool(_prefKey) ?? false;

  Future<void> mark() async {
    await UserPreferences.instance.setBool(_prefKey, true);
    state = const AsyncData(true);
  }

  Future<void> clear() async {
    await UserPreferences.instance.setBool(_prefKey, false);
    state = const AsyncData(false);
  }
}
