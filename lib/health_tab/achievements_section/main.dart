import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../ui/main.dart';
import 'achievements_controller.dart';
import 'badge_card.dart';
import 'celebration_sheet.dart';
import 'model/achievement_progress.dart';
import 'model/level_summary.dart';

class AchievementsSubtab extends ConsumerStatefulWidget {
  const AchievementsSubtab({super.key});

  @override
  ConsumerState<AchievementsSubtab> createState() => _AchievementsSubtabState();
}

class _AchievementsSubtabState extends ConsumerState<AchievementsSubtab> {
  @override
  void initState() {
    super.initState();
    // Entering the tab clears the unseen dot and surfaces any pending
    // celebration (set by the most recent sync).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(unseenAchievementsProvider.notifier).clear();
      final celebration = ref.read(achievementCelebrationControllerProvider);
      if (celebration != null && !celebration.isEmpty) {
        ref.read(achievementCelebrationControllerProvider.notifier).clear();
        showPSheet(
          context: context,
          maxHeightRatio: 0.9,
          builder: (_) => CelebrationSheet(celebration: celebration),
        );
      }
    });
  }

  /// progress ↓, then tier (difficulty × consistency) ↑ (easier first), then xp ↓.
  int _compare(AchievementProgress a, AchievementProgress b) {
    final p = b.progress.compareTo(a.progress);
    if (p != 0) return p;
    final t = a.tier.compareTo(b.tier);
    if (t != 0) return t;
    return b.xpReward.compareTo(a.xpReward);
  }

  @override
  Widget build(BuildContext context) {
    final badges = ref.watch(achievementProgressListProvider);
    final level = ref.watch(levelSummaryProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(achievementProgressListProvider);
        ref.invalidate(levelSummaryProvider);
        await ref.read(achievementProgressListProvider.future);
      },
      child: badges.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text('health.error'.tr())),
            ),
          ],
        ),
        data: (list) {
          if (list.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                PEmptySectionPlaceholder(
                    subtitle: 'health.achievements.empty'.tr()),
              ],
            );
          }

          final inProgress = list
              .where((b) => b.state == AchievementState.inProgress)
              .toList()
            ..sort(_compare);
          final earned = list.where((b) => b.isEarned).toList()..sort(_compare);
          final notStarted = list
              .where((b) => b.state == AchievementState.notStarted)
              .toList()
            ..sort(_compare);

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            children: [
              _LevelHeader(summary: level.value),
              const SizedBox(height: 16),
              ..._section('health.achievements.inProgress'.tr(), inProgress),
              ..._section('health.achievements.earned'.tr(), earned),
              ..._section('health.achievements.locked'.tr(), notStarted),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _section(String title, List<AchievementProgress> items) {
    if (items.isEmpty) return const [];
    return [
      PSectionHeader(title: title, suffix: _CountChip(count: items.length)),
      const SizedBox(height: 10),
      for (final b in items) ...[BadgeCard(badge: b), const SizedBox(height: 10)],
      const SizedBox(height: 8),
    ];
  }
}

class _CountChip extends StatelessWidget {
  final int count;
  const _CountChip({required this.count});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$count',
        style: context.theme.typography.body.xs
            .copyWith(color: colors.mutedForeground, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ─── Level header ─────────────────────────────────────────────────────────────

class _LevelHeader extends StatelessWidget {
  final LevelSummary? summary;
  const _LevelHeader({required this.summary});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final s = summary;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.border),
        borderRadius: context.theme.style.borderRadius.md,
        boxShadow: context.theme.style.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Row(
            spacing: 14,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: pbBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(FLucideIcons.trophy, color: pbBlue, size: 26),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      'health.achievements.levelLabel'.tr(),
                      style: context.theme.typography.body.xs.copyWith(
                        color: colors.mutedForeground,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Text(
                      'health.achievements.level'
                          .tr(namedArgs: {'level': '${s?.level ?? 1}'}),
                      style: TextStyle(
                        fontFamily: context.theme.typography.body.xl2.fontFamily,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: colors.foreground,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'health.achievements.xpTotal'
                    .tr(namedArgs: {'xp': '${s?.xpTotal ?? 0}'}),
                style: context.theme.typography.body.sm.copyWith(
                  color: colors.mutedForeground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: s?.progress ?? 0,
              minHeight: 8,
              backgroundColor: colors.secondary,
              valueColor: const AlwaysStoppedAnimation<Color>(pbBlue),
            ),
          ),
          Text(
            (s?.isMaxed ?? false)
                ? 'health.achievements.maxed'.tr()
                : 'health.achievements.toNext'.tr(namedArgs: {
                    'current': '${s?.xpIntoLevel ?? 0}',
                    'total': '${s?.xpForLevel ?? 0}',
                  }),
            style: context.theme.typography.body.xs
                .copyWith(color: colors.mutedForeground),
          ),
        ],
      ),
    );
  }
}
