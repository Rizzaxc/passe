import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../core/model/enum.dart';
import '../core/model/lobby_feed_item.dart';
import '../ui/theme.dart';

/// Score floor of `calculate_profile_compat_score` — the neutral baseline.
/// Anything above it is "at least an ok fit"; at or below it is a poor fit.
const double _fitScoreFloor = 2.5;

/// Vibrant green for the FitScore badge/sliver when the fit is at least "ok".
/// (Brighter than the muted brand olive `pbGreen`, for a stronger signal.)
const Color _fitGreen = Color(0xFF16A34A);

class LobbyFeedCard extends StatelessWidget {
  final LobbyFeedItem item;
  final Widget action;
  final bool showCompat;

  const LobbyFeedCard({
    super.key,
    required this.item,
    required this.action,
    this.showCompat = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final score = item.profileCompatScore;
    final isGoodFit = score > _fitScoreFloor;
    final sliverColor = showCompat && score > 0
        ? (isGoodFit ? _fitGreen : colors.muted)
        : colors.muted;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.border),
        borderRadius: context.theme.style.borderRadius.md,
        boxShadow: context.theme.style.shadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                // Name + member count
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: context.theme.typography.body.sm.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.memberCount != null) ...[
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        spacing: 4,
                        children: [
                          Icon(
                            FLucideIcons.users,
                            size: 14,
                            color: colors.primary,
                          ),
                          Text(
                            '${item.memberCount}',
                            style: context.theme.typography.body.lg.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.primary,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),

                // Homeground + timeslots. Visibility used to show here too
                // (an icon: public/discoverable/private) — dropped from the
                // discovery cards since it's not decision-relevant at
                // browse time; it's still shown when creating a lobby and
                // on the lobby detail page.
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 6,
                  children: [
                    if (item.homegroundName != null)
                      Row(
                        spacing: 3,
                        children: [
                          Icon(
                            FLucideIcons.mapPin,
                            size: 11,
                            color: colors.mutedForeground,
                          ),
                          Expanded(
                            child: Text(
                              item.homegroundName!,
                              style: context.theme.typography.body.xs.copyWith(
                                color: colors.mutedForeground,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    if (item.playtime.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: item.playtime.take(3).map((ts) {
                          return _TimeslotChip(
                            label:
                                '${ts.dayChunk.getShortName(context)} ${ts.dayOfWeek.getShortName(context)}',
                          );
                        }).toList(),
                      ),
                  ],
                ),

                // Combined Stake & FitScore footer
                if ((item.lobbyMmr != null) || (showCompat && score > 0)) ...[
                  FDivider(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 6,
                    children: [
                      Row(
                        children: [
                          if (showCompat && score > 0)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 6,
                              children: [
                                Text(
                                  'FitScore',
                                  style: TextStyle(
                                    fontFamily: context
                                        .theme
                                        .typography
                                        .body
                                        .xs
                                        .fontFamily,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: colors.mutedForeground,
                                    letterSpacing: 0.7,
                                  ),
                                ),
                                _ScoreBadge(score: score, isGoodFit: isGoodFit),
                              ],
                            ),
                          const Spacer(),
                          if (item.lobbyMmr != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 6,
                              children: [
                                Text(
                                  'homeTab.challenger.mmr'.tr(),
                                  style: TextStyle(
                                    fontFamily: context
                                        .theme
                                        .typography
                                        .body
                                        .xs
                                        .fontFamily,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: colors.mutedForeground,
                                    letterSpacing: 0.7,
                                  ),
                                ),
                                Text(
                                  '${item.lobbyMmr}',
                                  style: context.theme.typography.body.xs
                                      .copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: colors.foreground,
                                      ),
                                ),
                                if (item.favorability != null)
                                  _FavorabilityBadge(
                                    favorability: item.favorability!,
                                  ),
                              ],
                            ),
                        ],
                      ),
                      if (showCompat && score > 0) _FitScoreVibes(item: item),
                    ],
                  ),
                ],

                FDivider(),

                // CTA
                Align(alignment: Alignment.centerRight, child: action),
              ],
            ),
          ),
          // Bottom tier sliver
          SizedBox(height: 4, child: ColoredBox(color: sliverColor)),
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final double score;
  final bool isGoodFit;

  const _ScoreBadge({required this.score, required this.isGoodFit});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final scoreBg = isGoodFit ? _fitGreen : colors.secondary;
    final scoreFg = isGoodFit ? Colors.white : colors.mutedForeground;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: scoreBg,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            score.toStringAsFixed(1),
            style: TextStyle(
              fontFamily: context.theme.typography.body.xs.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: scoreFg,
              height: 1,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            '/ 5',
            style: TextStyle(
              fontFamily: context.theme.typography.body.xs.fontFamily,
              fontSize: 8,
              fontWeight: FontWeight.w500,
              color: scoreFg.withValues(alpha: 0.85),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _FavorabilityBadge extends StatelessWidget {
  final ChallengeFavorability favorability;

  const _FavorabilityBadge({required this.favorability});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final (Color bg, Color fg) = switch (favorability) {
      ChallengeFavorability.favored => (const Color(0xFF16a34a), Colors.white),
      ChallengeFavorability.even => (const Color(0xFFd97706), Colors.white),
      ChallengeFavorability.underdog => (
        colors.secondary,
        colors.mutedForeground,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        favorability.getLocalizedName(context),
        style: TextStyle(
          fontFamily: context.theme.typography.body.xs.fontFamily,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: fg,
          height: 1,
        ),
      ),
    );
  }
}

class _FitScoreVibes extends StatelessWidget {
  final LobbyFeedItem item;

  const _FitScoreVibes({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    if (item.matchFactors.isEmpty) return const SizedBox.shrink();

    // Each real factor code → (label, icon, foreground). The chip background is
    // the foreground at 8% opacity. Unknown codes are skipped.
    (String, IconData, Color)? specFor(String code) => switch (code) {
      'skill' => (
        'Trình độ phù hợp',
        FLucideIcons.trophy,
        const Color(0xFFD97706),
      ),
      'network' => (
        'Chung mạng lưới',
        FLucideIcons.users,
        const Color(0xFF059669),
      ),
      'industry' => (
        'Cùng ngành nghề',
        FLucideIcons.briefcase,
        const Color(0xFF0D9488),
      ),
      'age' => ('Cùng nhóm tuổi', FLucideIcons.cake, const Color(0xFF7C3AED)),
      'gender' => (
        'Thân thiện với nữ',
        FLucideIcons.venus,
        const Color(0xFFDB2777),
      ),
      'playtime' => ('Lịch chơi khớp', FLucideIcons.calendar, pbBlue),
      'location' => ('Vị trí thuận tiện', FLucideIcons.mapPin, colors.primary),
      _ => null,
    };

    final chips = <Widget>[];
    for (final code in item.matchFactors) {
      final spec = specFor(code);
      if (spec == null) continue;
      final (label, icon, fg) = spec;
      chips.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: fg.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 3,
            children: [
              Icon(icon, size: 9, color: fg),
              Text(
                label,
                style: TextStyle(
                  fontFamily: context.theme.typography.body.xs.fontFamily,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 6, runSpacing: 4, children: chips);
  }
}

class _TimeslotChip extends StatelessWidget {
  final String label;

  const _TimeslotChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: pbBlue.withValues(alpha: 0.08),
        borderRadius: context.theme.style.borderRadius.sm,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 3,
          children: [
            const Icon(Icons.schedule_rounded, size: 10, color: pbBlue),
            Text(
              label,
              style: context.theme.typography.body.xs.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: pbBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
