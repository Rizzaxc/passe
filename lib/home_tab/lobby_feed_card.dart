import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../core/model/enum.dart';
import '../core/model/lobby.dart';
import '../core/model/lobby_feed_item.dart';
import '../ui/theme.dart';

enum _Tier { high, mid, low }

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
    final tier = score >= 3.5
        ? _Tier.high
        : score >= 2.0
            ? _Tier.mid
            : _Tier.low;
    final sliverColor = showCompat && score > 0
        ? (tier == _Tier.high
            ? const Color(0xFF16a34a)
            : tier == _Tier.mid
                ? const Color(0xFFd97706)
                : colors.muted)
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '${item.memberCount}',
                            style: context.theme.typography.lg.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.primary,
                              height: 1,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'thành viên',
                            style: TextStyle(
                              fontFamily: context.theme.typography.xs.fontFamily,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: colors.mutedForeground,
                              letterSpacing: 0.4,
                              height: 1,
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
                  spacing: 8,
                  children: [
                    Row(
                      spacing: 8,
                      children: [
                        _VisibilityIcon(visibility: item.visibility),
                        if (item.homegroundName != null)
                          Expanded(
                            child: Row(
                              spacing: 4,
                              children: [
                                Icon(
                                  FIcons.mapPin,
                                  size: 12,
                                  color: colors.mutedForeground,
                                ),
                                Expanded(
                                  child: Text(
                                    item.homegroundName!,
                                    style: context.theme.typography.xs.copyWith(
                                      color: colors.mutedForeground,
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

                // Challenge stakes — challenger feed only (MMR + favorability)
                if (item.lobbyMmr != null) ...[
                  FDivider(),
                  _ChallengeStakeRow(
                    mmr: item.lobbyMmr!,
                    favorability: item.favorability,
                  ),
                ],

                // Compat section
                if (showCompat && score > 0) ...[
                  FDivider(),
                  _FitScoreSection(item: item, score: score, tier: tier),
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

class _FitScoreSection extends StatelessWidget {
  final LobbyFeedItem item;
  final double score;
  final _Tier tier;

  const _FitScoreSection({
    required this.item,
    required this.score,
    required this.tier,
  });

  List<Widget> _buildVibes(BuildContext context) {
    final colors = context.theme.colors;
    final chips = <Widget>[];

    Widget buildChip(String label, IconData icon) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colors.secondary,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            Icon(
              icon,
              size: 10,
              color: colors.secondaryForeground,
            ),
            Text(
              label,
              style: TextStyle(
                fontFamily: context.theme.typography.xs.fontFamily,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: colors.secondaryForeground,
              ),
            ),
          ],
        ),
      );
    }

    if (item.lobbyMmr == null) {
      // Teammate Recommendation
      if (score >= 3.5) {
        chips.add(buildChip('Trình độ phù hợp', FIcons.trophy));
      }
      if (score >= 2.0) {
        chips.add(buildChip('Chung mạng lưới', FIcons.users));
      }
      if (item.timeslotCompatScore >= 4) {
        chips.add(buildChip('Lịch chơi khớp', FIcons.calendar));
      }
    } else {
      // Challenger Recommendation
      if (score >= 2.0) {
        chips.add(buildChip('Chung mạng lưới', FIcons.users));
      }
      if (score >= 3.0) {
        chips.add(buildChip('Lịch chơi khớp', FIcons.calendar));
      }
      if (item.homegroundName != null && score >= 2.5) {
        chips.add(buildChip('Vị trí thuận tiện', FIcons.mapPin));
      }
    }

    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final scoreBg = tier == _Tier.high
        ? const Color(0xFF16a34a)
        : tier == _Tier.mid
            ? const Color(0xFFd97706)
            : colors.secondary;
    final scoreFg =
        tier == _Tier.low ? colors.mutedForeground : Colors.white;

    final vibes = _buildVibes(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Row(
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
            const Spacer(),
            Container(
              padding: const EdgeInsets.fromLTRB(9, 4, 9, 4),
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
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: scoreFg,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '/ 5',
                    style: TextStyle(
                      fontFamily: context.theme.typography.xs.fontFamily,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: scoreFg.withValues(alpha: 0.85),
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (vibes.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: vibes,
          ),
      ],
    );
  }
}

class _ChallengeStakeRow extends StatelessWidget {
  final int mmr;
  final ChallengeFavorability? favorability;

  const _ChallengeStakeRow({required this.mmr, this.favorability});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final fav = favorability;
    final (Color bg, Color fg) = switch (fav) {
      ChallengeFavorability.favored => (const Color(0xFF16a34a), Colors.white),
      ChallengeFavorability.even => (const Color(0xFFd97706), Colors.white),
      ChallengeFavorability.underdog => (colors.secondary, colors.mutedForeground),
      null => (colors.secondary, colors.mutedForeground),
    };

    return Row(
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
        const SizedBox(width: 6),
        Text(
          '$mmr',
          style: context.theme.typography.sm.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.foreground,
            height: 1,
          ),
        ),
        const Spacer(),
        if (fav != null)
          Container(
            padding: const EdgeInsets.fromLTRB(9, 4, 9, 4),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Text(
              fav.getLocalizedName(context),
              style: TextStyle(
                fontFamily: context.theme.typography.xs.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: fg,
                height: 1,
              ),
            ),
          ),
      ],
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
        color: context.theme.colors.secondary,
        borderRadius: context.theme.style.borderRadius.sm,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 11,
              color: context.theme.colors.mutedForeground,
            ),
            Text(
              label,
              style: context.theme.typography.xs.copyWith(
                fontWeight: FontWeight.w500,
                color: context.theme.colors.secondaryForeground,
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
