import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../health_tab/achievements_section/achievements_controller.dart';
import '../health_tab/achievements_section/model/achievement_celebration.dart';

/// Re-runs the `evaluate_achievements` RPC and, if anything unlocked, stashes
/// the celebration payload + lights the unseen dot — the achievements subtab
/// (`health_tab/achievements_section`) surfaces both on next entry.
///
/// Shared by every write path that can move an achievement criteria forward:
/// `HealthSyncController.syncNow()` for health/vitality badges, and the wall
/// post compose/react controllers for social badges. The evaluator itself
/// scores every criteria row regardless of who called it, so calling this
/// right after the data it reads changes is what keeps a badge's `criteria`
/// authoritative — same rule as the health flow, just more call sites now.
/// Own try/catch: a failure here must never block the write it followed.
Future<AchievementCelebration?> evaluateAchievements(
  Ref ref,
  String userId,
) async {
  try {
    final res = await Supabase.instance.client
        .rpc('evaluate_achievements', params: {'p_user_id': userId})
        .timeout(const Duration(seconds: 5));
    if (res is! Map) return null;

    final celebration = AchievementCelebration.fromRpc(
      Map<String, dynamic>.from(res),
    );
    if (!ref.mounted) return celebration;

    ref.invalidate(achievementProgressListProvider);
    ref.invalidate(levelSummaryProvider);

    if (!celebration.isEmpty) {
      ref
          .read(achievementCelebrationControllerProvider.notifier)
          .show(celebration);
      await ref.read(unseenAchievementsProvider.notifier).mark();
    }
    return celebration;
  } catch (e, st) {
    Talker().handle(e, st, 'Achievement evaluation failed');
    return null;
  }
}
