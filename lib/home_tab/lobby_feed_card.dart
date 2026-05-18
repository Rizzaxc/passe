import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../core/model/lobby.dart';
import '../core/model/lobby_feed_item.dart';
import '../ui/theme.dart';

class LobbyFeedCard extends StatelessWidget {
  final LobbyFeedItem item;
  final Widget action;

  const LobbyFeedCard({super.key, required this.item, required this.action});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return FCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          // Name + compat score
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: context.theme.typography.sm.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.primary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (item.profileCompatScore > 0) ...[
                const SizedBox(width: 8),
                _CompatBadge(score: item.profileCompatScore),
              ],
            ],
          ),

          // Member count + homeground
          Row(
            spacing: 4,
            children: [
              Icon(FIcons.users, size: 12, color: colors.mutedForeground),
              Text(
                '${item.memberCount ?? 0}',
                style: context.theme.typography.sm
                    .copyWith(color: colors.mutedForeground),
              ),
              if (item.homegroundName != null) ...[
                const SizedBox(width: 2),
                Icon(FIcons.mapPin, size: 12, color: colors.mutedForeground),
                Expanded(
                  child: Text(
                    item.homegroundName!,
                    style: context.theme.typography.sm
                        .copyWith(color: colors.mutedForeground),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),

          // Timeslot chips
          if (item.playtime.isNotEmpty)
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: item.playtime.take(3).map((ts) {
                return _TimeslotChip(
                  label:
                      '${ts.dayChunk.getShortName(context)} ${ts.dayOfWeek.getShortName(context)}',
                );
              }).toList(),
            ),

          FDivider(),

          // Visibility + action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _VisibilityChip(visibility: item.visibility),
              action,
            ],
          ),
        ],
      ),
    );
  }
}

class _CompatBadge extends StatelessWidget {
  final double score;

  const _CompatBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score >= 3.5
        ? const Color(0xFF22C55E)
        : score >= 2
            ? const Color(0xFFF59E0B)
            : context.theme.colors.mutedForeground;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 2,
      children: [
        Icon(Icons.star_rounded, size: 12, color: color),
        Text(
          score.toStringAsFixed(1),
          style: context.theme.typography.xs.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          label,
          style: context.theme.typography.xs.copyWith(
            color: context.theme.colors.secondaryForeground,
          ),
        ),
      ),
    );
  }
}

class _VisibilityChip extends StatelessWidget {
  final LobbyVisibility visibility;

  const _VisibilityChip({required this.visibility});

  @override
  Widget build(BuildContext context) {
    final isPublic = visibility == LobbyVisibility.public;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isPublic
            ? pbBlue.withValues(alpha: 0.12)
            : context.theme.colors.secondary,
        borderRadius: context.theme.style.borderRadius.sm,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          visibility.getLocalizedName(context),
          style: context.theme.typography.xs.copyWith(
            color: isPublic ? pbBlue : context.theme.colors.mutedForeground,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
