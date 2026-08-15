import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../core/format.dart';
import '../core/model/enum.dart';
import '../core/model/lobby_feed_item.dart';
import '../ui/main.dart';

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
    final isGoodFit = score >= _fitScoreFloor;
    final frameColor = showCompat && score > 0 && isGoodFit ? pbMint : pbAmber;
    final radius = BorderRadius.circular(16);

    return POffsetFrame(
      offsetColor: frameColor,
      borderRadius: radius,
      child: Container(
        decoration: BoxDecoration(
          color: colors.card,
          border: Border.all(color: pbInk.withValues(alpha: 0.16)),
          borderRadius: radius,
          boxShadow: context.theme.style.shadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LobbyAvatar(
                    lobbyId: item.id,
                    name: item.name,
                    hasAvatar: item.details?.hasAvatar ?? false,
                    size: 54,
                    borderRadius: BorderRadius.circular(15),
                    backgroundColor: pbAmber,
                    foregroundColor: pbInk,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 5,
                      children: [
                        Text(
                          item.name,
                          style: context.theme.typography.body.lg.copyWith(
                            color: pbInk,
                            fontWeight: FontWeight.w800,
                            height: 1.12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.homegroundName != null)
                          Row(
                            children: [
                              Icon(
                                FLucideIcons.mapPin,
                                size: 12,
                                color: colors.mutedForeground,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item.homegroundName!,
                                  style: context.theme.typography.body.xs
                                      .copyWith(
                                        color: colors.mutedForeground,
                                        fontSize: 11,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  if (item.memberCount != null) ...[
                    const SizedBox(width: 8),
                    _MemberBadge(count: item.memberCount!),
                  ],
                ],
              ),
              if (item.playtime.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: item.playtime.take(3).map((ts) {
                    return _TimeslotChip(
                      label:
                          '${ts.dayChunk.getShortName(context)} ${ts.dayOfWeek.getShortName(context)}',
                    );
                  }).toList(),
                ),
              if (item.lobbyMmr != null || (showCompat && score > 0))
                _LobbyMatchBoard(
                  item: item,
                  showCompat: showCompat,
                  isGoodFit: isGoodFit,
                ),
              if (item.offerTime != null) _OfferStrip(item: item),
              Align(alignment: Alignment.centerRight, child: action),
            ],
          ),
        ),
      ),
    );
  }
}

/// The published offer: kickoff, venue, cost per team. Every value here is
/// dynamic-length (a venue name and a formatted amount have no bound), so each
/// row lets its value ellipsize rather than letting the card overflow on a
/// narrow phone.
class _OfferStrip extends StatelessWidget {
  final LobbyFeedItem item;

  const _OfferStrip({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: pbAmber.withValues(alpha: 0.18),
        border: Border.all(color: pbAmber.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: pbInk,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              FLucideIcons.calendarDays,
              size: 17,
              color: pbAmber,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(
                  formatMatchDateTime(item.offerTime!),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.theme.typography.body.sm.copyWith(
                    color: pbInk,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                if (item.offerLocationName != null)
                  _OfferDetail(
                    icon: FLucideIcons.mapPin,
                    value: item.offerLocationName!,
                  ),
                if (item.offerCost != null)
                  _OfferDetail(
                    icon: FLucideIcons.wallet,
                    value: 'homeTab.challenger.costPerTeam'.tr(
                      args: [formatVnd(item.offerCost!)],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferDetail extends StatelessWidget {
  final IconData icon;
  final String value;

  const _OfferDetail({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 11, color: pbInk.withValues(alpha: 0.58)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.theme.typography.body.xs.copyWith(
              color: pbInk.withValues(alpha: 0.72),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _MemberBadge extends StatelessWidget {
  final int count;

  const _MemberBadge({required this.count});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: pbInk,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        const Icon(FLucideIcons.users, size: 12, color: Colors.white),
        Text(
          '$count',
          style: context.theme.typography.body.xs.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ],
    ),
  );
}

class _LobbyMatchBoard extends StatelessWidget {
  final LobbyFeedItem item;
  final bool showCompat;
  final bool isGoodFit;

  const _LobbyMatchBoard({
    required this.item,
    required this.showCompat,
    required this.isGoodFit,
  });

  @override
  Widget build(BuildContext context) {
    final score = item.profileCompatScore;
    final hasFit = showCompat && score > 0;

    return PMatchBoard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (hasFit)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(
                        'FITSCORE',
                        style: context.theme.typography.body.xs.copyWith(
                          color: Colors.white.withValues(alpha: 0.62),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: score.toStringAsFixed(1),
                              style: TextStyle(
                                color: isGoodFit ? pbAmber : Colors.white,
                                fontSize: 29,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                            ),
                            TextSpan(
                              text: ' / 5',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.56),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              if (item.lobbyMmr != null)
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    spacing: 3,
                    children: [
                      Text(
                        'homeTab.challenger.mmr'.tr().toUpperCase(),
                        style: context.theme.typography.body.xs.copyWith(
                          color: Colors.white.withValues(alpha: 0.62),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        item.hasProvisionalMmr
                            ? '${item.lobbyMmr} · ${'homeTab.challenger.provisional'.tr()}'
                            : '${item.lobbyMmr}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: context.theme.typography.body.sm.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (item.favorability != null)
                        _FavorabilityBadge(favorability: item.favorability!),
                    ],
                  ),
                ),
            ],
          ),
          if (hasFit) _FitScoreVibes(item: item),
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
    final (Color bg, Color fg) = switch (favorability) {
      ChallengeFavorability.favored => (pbMint, pbInk),
      ChallengeFavorability.even => (pbAmber, pbInk),
      ChallengeFavorability.underdog => (
        Colors.white.withValues(alpha: 0.14),
        Colors.white.withValues(alpha: 0.78),
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
    if (item.matchFactors.isEmpty) return const SizedBox.shrink();

    // Keep the factor language monochrome inside the match board. The prior
    // rainbow of micro-chips read as analytics tags instead of one cohesive
    // sports graphic.
    (String, IconData)? specFor(String code) => switch (code) {
      'skill' => ('Trình độ phù hợp', FLucideIcons.trophy),
      'network' => ('Chung mạng lưới', FLucideIcons.users),
      'industry' => ('Cùng ngành nghề', FLucideIcons.briefcase),
      'age' => ('Cùng nhóm tuổi', FLucideIcons.cake),
      'gender' => ('Thân thiện với nữ', FLucideIcons.venus),
      'playtime' => ('Lịch chơi khớp', FLucideIcons.calendar),
      'location' => ('Vị trí thuận tiện', FLucideIcons.mapPin),
      _ => null,
    };

    final chips = <Widget>[];
    for (final code in item.matchFactors) {
      final spec = specFor(code);
      if (spec == null) continue;
      final (label, icon) = spec;
      chips.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [
              Icon(icon, size: 10, color: pbAmber),
              Text(
                label,
                style: TextStyle(
                  fontFamily: context.theme.typography.body.xs.fontFamily,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
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
        color: pbInk.withValues(alpha: 0.055),
        border: Border.all(color: pbInk.withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            const Icon(Icons.schedule_rounded, size: 11, color: pbBlueDeep),
            Text(
              label,
              style: context.theme.typography.body.xs.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: pbInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
