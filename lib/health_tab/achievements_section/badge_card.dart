import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../ui/theme.dart';
import 'model/achievement_progress.dart';

/// Tier indicator: 🔥×difficulty (intensity) · ●×consistency (frequency).
class TierIcons extends StatelessWidget {
  final int difficulty;
  final int consistency;
  const TierIcons({super.key, required this.difficulty, required this.consistency});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    Widget pip(IconData icon, bool filled) => Icon(
          icon,
          size: 11,
          color: filled ? pbGreen : colors.border,
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 3; i++) pip(FLucideIcons.flame, i <= difficulty),
        const SizedBox(width: 6),
        for (var i = 1; i <= 3; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0.5),
            child: pip(FLucideIcons.circle, i <= consistency),
          ),
      ],
    );
  }
}

class BadgeCard extends StatelessWidget {
  final AchievementProgress badge;
  const BadgeCard({super.key, required this.badge});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final earned = badge.isEarned;
    final barColor = earned ? pbGreen : pbBlue;
    final pct = (badge.progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.border),
        borderRadius: context.theme.style.borderRadius.md,
        boxShadow: context.theme.style.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Row(
            spacing: 10,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (earned ? pbGreen : colors.mutedForeground)
                      .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Icon(
                  earned ? FLucideIcons.badgeCheck : FLucideIcons.lock,
                  size: 20,
                  color: earned ? pbGreen : colors.mutedForeground,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 3,
                  children: [
                    Text(
                      badge.name,
                      style: context.theme.typography.body.sm
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      _subtitle(),
                      style: context.theme.typography.body.xs.copyWith(
                        color: colors.mutedForeground,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    TierIcons(
                        difficulty: badge.difficulty,
                        consistency: badge.consistency),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    earned ? '✓' : '$pct%',
                    style: TextStyle(
                      fontFamily: context.theme.typography.body.sm.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: barColor,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '+${badge.xpReward} XP',
                    style: context.theme.typography.body.xs.copyWith(
                      color: colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (!earned)
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: badge.progress,
                minHeight: 6,
                backgroundColor: colors.secondary,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
        ],
      ),
    );
  }

  String _subtitle() {
    final d = badge.description ?? '';
    return switch (badge.state) {
      AchievementState.earnedPeriod =>
        'health.achievements.earnedPeriod'.tr(),
      AchievementState.done => d,
      _ => d,
    };
  }
}
