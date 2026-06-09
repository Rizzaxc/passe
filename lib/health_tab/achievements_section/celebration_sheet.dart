import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../ui/main.dart';
import 'model/achievement_celebration.dart';

/// The post-sync celebration: level-up foregrounded, then the newly-unlocked
/// badges. Shown via [showPSheet] when the user opens the achievements subtab.
class CelebrationSheet extends StatelessWidget {
  final AchievementCelebration celebration;
  const CelebrationSheet({super.key, required this.celebration});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          PSheetTitle(
            label: celebration.leveledUp
                ? 'health.achievements.celebrate.levelTitle'.tr()
                : 'health.achievements.celebrate.title'.tr(),
          ),

          if (celebration.leveledUp)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: pbGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Column(
                spacing: 4,
                children: [
                  Icon(FIcons.trophy, size: 36, color: pbGreen),
                  Text(
                    'health.achievements.level'
                        .tr(namedArgs: {'level': '${celebration.level}'}),
                    style: context.theme.typography.xl2
                        .copyWith(fontWeight: FontWeight.bold, color: pbGreen),
                  ),
                ],
              ),
            ),

          if (celebration.unlocked.isNotEmpty) ...[
            PSheetSectionLabel(
              label: 'health.achievements.celebrate.unlocked'.tr(),
              trailing: Text(
                '+${celebration.xpGained} XP',
                style: context.theme.typography.sm
                    .copyWith(fontWeight: FontWeight.w700, color: pbGreen),
              ),
            ),
            for (final b in celebration.unlocked)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: Row(
                  spacing: 12,
                  children: [
                    Icon(FIcons.badgeCheck, size: 20, color: pbGreen),
                    Expanded(
                      child: Text(b.name, style: context.theme.typography.md),
                    ),
                    Text(
                      '+${b.xp}',
                      style: context.theme.typography.sm.copyWith(
                        color: colors.mutedForeground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],

          const SizedBox(height: 4),
          FButton(
            onPress: () => Navigator.of(context).pop(),
            child: Text('health.achievements.celebrate.dismiss'.tr()),
          ),
        ],
      ),
    );
  }
}
