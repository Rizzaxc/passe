import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../ui/main.dart';
import '../model/vitality_score.dart';

/// Hero card for the general gamified fitness score: balances training-load
/// trend and consistency, normalized against the user's own trailing
/// history (see `schema/vitality_score.sql`). Visual sibling of
/// `achievements_section/main.dart`'s `_LevelHeader`, using green instead of
/// blue so the two hero cards read as distinct at a glance.
class VitalityScoreCard extends StatelessWidget {
  final VitalityScore? score;
  const VitalityScoreCard({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final s = score;

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
                  color: pbGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(FLucideIcons.zap, color: pbGreen, size: 26),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      'health.vitality.title'.tr(),
                      style: context.theme.typography.body.xs.copyWith(
                        color: colors.mutedForeground,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Text(
                      s?.hasEnoughData ?? false ? '${s!.score!.round()}' : '—',
                      style: TextStyle(
                        fontFamily:
                            context.theme.typography.body.xl2.fontFamily,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: colors.foreground,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              if ((s?.streakBonus ?? 0) > 0)
                Text(
                  'health.vitality.streakBonus'.tr(
                    namedArgs: {'n': '${s!.streakBonus.round()}'},
                  ),
                  style: context.theme.typography.body.sm.copyWith(
                    color: pbGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (s?.hasEnoughData ?? false) ? s!.score! / 100 : 0,
              minHeight: 8,
              backgroundColor: colors.secondary,
              valueColor: const AlwaysStoppedAnimation<Color>(pbGreen),
            ),
          ),
          if (!(s?.hasEnoughData ?? false))
            Text(
              'health.vitality.notEnoughData'.tr(),
              style: context.theme.typography.body.xs.copyWith(
                color: colors.mutedForeground,
              ),
            )
          else
            Row(
              spacing: 8,
              children: [
                _ComponentPill(
                  label: 'health.vitality.component.consistency'.tr(),
                  value: s!.consistencyComponent,
                ),
                _ComponentPill(
                  label: 'health.vitality.component.load'.tr(),
                  value: s.loadComponent,
                ),
                _ComponentPill(
                  label: 'health.vitality.component.recovery'.tr(),
                  value: s.recoveryComponent,
                ),
                _ComponentPill(
                  label: 'health.vitality.component.volume'.tr(),
                  value: s.volumeComponent,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ComponentPill extends StatelessWidget {
  final String label;
  final double? value;
  const _ComponentPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: colors.secondary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          spacing: 2,
          children: [
            Text(
              value != null ? '${value!.round()}' : '—',
              style: context.theme.typography.body.sm.copyWith(
                fontWeight: FontWeight.w700,
                color: value != null
                    ? colors.foreground
                    : colors.mutedForeground,
              ),
            ),
            Text(
              label,
              style: context.theme.typography.body.xs.copyWith(
                color: colors.mutedForeground,
                fontSize: 9,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
