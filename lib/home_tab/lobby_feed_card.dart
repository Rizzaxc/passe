import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../core/model/enum.dart';
import '../core/model/lobby.dart';
import '../core/model/lobby_feed_item.dart';
import '../ui/theme.dart';

/// Score floor of `calculate_profile_compat_score` — the neutral baseline.
/// Anything above it is "at least an ok fit"; at or below it is a poor fit.
const double _fitScoreFloor = 2.5;

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
        ? (isGoodFit ? pbGreen : colors.muted)
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
                        style: context.theme.typography.sm.copyWith(
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
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        spacing: 4,
                        children: [
                          Text(
                            '${item.memberCount}',
                            style: context.theme.typography.lg.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.primary,
                              height: 1,
                            ),
                          ),
                          Text(
                            'thành viên',
                            style: context.theme.typography.xs.copyWith(
                              color: colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),

                // Visibility + homeground + timeslots
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 6,
                  children: [
                    Row(
                      spacing: 6,
                      children: [
                        _VisibilityIcon(visibility: item.visibility),
                        if (item.homegroundName != null)
                          Expanded(
                            child: Row(
                              spacing: 3,
                              children: [
                                Icon(
                                  FIcons.mapPin,
                                  size: 11,
                                  color: colors.mutedForeground,
                                ),
                                Expanded(
                                  child: Text(
                                    item.homegroundName!,
                                    style: context.theme.typography.xs.copyWith(
                                      color: colors.mutedForeground,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
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
                                    fontFamily: context.theme.typography.xs.fontFamily,
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
                                    fontFamily: context.theme.typography.xs.fontFamily,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: colors.mutedForeground,
                                    letterSpacing: 0.7,
                                  ),
                                ),
                                Text(
                                  '${item.lobbyMmr}',
                                  style: context.theme.typography.xs.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: colors.foreground,
                                  ),
                                ),
                                if (item.favorability != null)
                                  _FavorabilityBadge(favorability: item.favorability!),
                              ],
                            ),
                        ],
                      ),
                      if (showCompat && score > 0)
                        _FitScoreVibes(item: item, score: score),
                    ],
                  ),
                ],

                FDivider(),

                // CTA
                Align(
                  alignment: Alignment.centerRight,
                  child: action,
                ),
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
    final scoreBg = isGoodFit ? pbGreen : colors.secondary;
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
              fontFamily: context.theme.typography.xs.fontFamily,
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
              fontFamily: context.theme.typography.xs.fontFamily,
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
      ChallengeFavorability.underdog => (colors.secondary, colors.mutedForeground),
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
          fontFamily: context.theme.typography.xs.fontFamily,
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
  final double score;

  const _FitScoreVibes({required this.item, required this.score});

  List<Widget> _buildVibes(BuildContext context) {
    final colors = context.theme.colors;
    final chips = <Widget>[];

    // Semantic palettes: skill (amber), network (emerald), playtime (brand
    // blue), location (primary red). Soft translucent bg + solid fg.
    const skillBg = Color(0x14F59E0B); // 0xFFF59E0B @ 8%
    const skillFg = Color(0xFFD97706);
    const networkBg = Color(0x1410B981); // 0xFF10B981 @ 8%
    const networkFg = Color(0xFF059669);
    final playtimeBg = pbBlue.withValues(alpha: 0.08);
    const playtimeFg = pbBlue;
    final locationBg = colors.primary.withValues(alpha: 0.08);
    final locationFg = colors.primary;

    Widget buildChip(String label, IconData icon, Color bg, Color fg) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 3,
          children: [
            Icon(
              icon,
              size: 9,
              color: fg,
            ),
            Text(
              label,
              style: TextStyle(
                fontFamily: context.theme.typography.xs.fontFamily,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      );
    }

    if (item.lobbyMmr == null) {
      if (score >= 3.5) {
        chips.add(buildChip('Trình độ phù hợp', FIcons.trophy, skillBg, skillFg));
      }
      if (score >= 2.0) {
        chips.add(buildChip('Chung mạng lưới', FIcons.users, networkBg, networkFg));
      }
      if (item.timeslotCompatScore >= 4) {
        chips.add(buildChip('Lịch chơi khớp', FIcons.calendar, playtimeBg, playtimeFg));
      }
    } else {
      if (score >= 2.0) {
        chips.add(buildChip('Chung mạng lưới', FIcons.users, networkBg, networkFg));
      }
      if (score >= 3.0) {
        chips.add(buildChip('Lịch chơi khớp', FIcons.calendar, playtimeBg, playtimeFg));
      }
      if (item.homegroundName != null && score >= 2.5) {
        chips.add(buildChip('Vị trí thuận tiện', FIcons.mapPin, locationBg, locationFg));
      }
    }

    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final vibes = _buildVibes(context);
    if (vibes.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: vibes,
    );
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
            const Icon(
              Icons.schedule_rounded,
              size: 10,
              color: pbBlue,
            ),
            Text(
              label,
              style: context.theme.typography.xs.copyWith(
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

class _VisibilityIcon extends StatelessWidget {
  final LobbyVisibility visibility;

  const _VisibilityIcon({required this.visibility});

  @override
  Widget build(BuildContext context) {
    final color = visibility == LobbyVisibility.public
        ? pbBlue
        : context.theme.colors.mutedForeground;
    final icon = switch (visibility) {
      LobbyVisibility.public => Icons.language_rounded,
      LobbyVisibility.discoverable => Icons.search_rounded,
      LobbyVisibility.private => Icons.lock_outline_rounded,
    };
    return Icon(icon, size: 14, color: color);
  }
}
