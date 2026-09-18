import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../ui/main.dart';
import '../model/activity_health_row.dart';

/// Translation key for a recap/detected-workout row's source category —
/// shared by the recap card, recap sheet, and detected-workout card so they
/// stay in sync. Prefer [row.sourceName] (the actual lobby/coach/host name)
/// when available; this generic label is the fallback (and the only option
/// for a 'self' standalone activity, which has nothing to name).
String sourceLabelKey(String source) => switch (source) {
  'lobby' => 'health.source.lobby',
  'freeplay' => 'health.source.freeplay',
  'professional' => 'health.source.professional',
  _ => 'health.source.self',
};

/// Date format for a card/sheet *title* — deliberately not a bare calendar
/// date (that reads like a schedule reference, not a title). Relative day
/// (Today/Yesterday) plus the session's start time when recent, since a
/// title should say *when this specific session was*; falls back to
/// month + day + time beyond yesterday.
///
/// [dt] comes from Supabase as UTC (`DateTime.parse` on a `timestamptz`
/// string always yields `isUtc: true`) — `.toLocal()` first, or every
/// formatted value and the Today/Yesterday check itself are off by the
/// device's UTC offset (a session that started at 8:45 PM in Vietnam would
/// show as 1:45 PM, and could land on the wrong calendar day entirely).
String cardTitleDateLabel(BuildContext context, DateTime dt) {
  final local = dt.toLocal();
  final locale = context.locale.toString();
  final time = DateFormat.jm(locale).format(local);
  final now = DateTime.now();
  bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  if (sameDay(local, now)) return '${'health.recap.today'.tr()}, $time';
  if (sameDay(local, now.subtract(const Duration(days: 1)))) {
    return '${'health.recap.yesterday'.tr()}, $time';
  }
  return '${DateFormat.MMMd(locale).format(local)}, $time';
}

/// Source name (lobby/coach/host) and location, each on its own line —
/// joining them into one line with a separator meant both would have to
/// share a single `maxLines: 1` ellipsis, so a long lobby name could crowd
/// out the location entirely (or vice versa). Separate lines let each
/// truncate independently instead.
class SourceLocationLines extends StatelessWidget {
  final String source;
  final String? sourceName;
  final String? locationLabel;
  final TextStyle? style;
  const SourceLocationLines({
    required this.source,
    this.sourceName,
    this.locationLabel,
    this.style,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 1,
      children: [
        Text(
          sourceName ?? sourceLabelKey(source).tr(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
        if (locationLabel != null)
          Text(
            locationLabel!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
      ],
    );
  }
}

/// Circular icon badge anchoring a card/sheet header visually in place of a
/// wall of text — a fixed activity icon rather than per-sport art (the icon
/// set here has no sport-specific glyphs worth maintaining a mapping for).
class ActivityIconBadge extends StatelessWidget {
  final FColors colors;
  final double size;
  const ActivityIconBadge({required this.colors, this.size = 36, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(
        FLucideIcons.activity,
        size: size * 0.5,
        color: colors.primary,
      ),
    );
  }
}

/// The activity's source avatar — the lobby's photo, the coach's user
/// avatar, or the freeplay host's photo — in place of the generic activity
/// icon, so the card/sheet reads as "this session, with these people"
/// rather than a blank icon. Falls back to [ActivityIconBadge] for a
/// standalone (self) activity, and for any source that's missing the data
/// it needs to resolve a real avatar (e.g. an unlinked coach profile) —
/// never fabricates one.
class SourceAvatar extends StatelessWidget {
  final ActivityHealthRow row;
  final double size;
  const SourceAvatar({required this.row, this.size = 36, super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    switch (row.source) {
      case 'lobby' when row.lobbyId != null:
        return LobbyAvatar(
          lobbyId: row.lobbyId,
          name: row.sourceName ?? '',
          hasAvatar: row.lobbyHasAvatar ?? false,
          size: size,
          borderRadius: BorderRadius.circular(size / 2),
          backgroundColor: colors.primary.withValues(alpha: 0.12),
          foregroundColor: colors.primary,
        );
      case 'professional' when row.avatarUserId != null:
        return PUserAvatar(
          userId: row.avatarUserId!,
          username: row.avatarUsername ?? '',
          generatedAvatar: row.avatarGenerated,
          radius: size / 2,
        );
      case 'freeplay' when row.freeplayAvatarUrl != null:
        return CircleAvatar(
          radius: size / 2,
          backgroundColor: colors.primary.withValues(alpha: 0.12),
          backgroundImage: CachedNetworkImageProvider(
            row.freeplayAvatarUrl!,
          ),
        );
      default:
        return ActivityIconBadge(colors: colors, size: size);
    }
  }
}

/// Icon-led stat: an icon carries the "what" so the value doesn't need a
/// separate label line underneath it — used by both the recap card's compact
/// row and the recap sheet's fuller stat set.
class StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String? unit;
  const StatChip({
    required this.icon,
    required this.value,
    this.unit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        Icon(icon, size: 16, color: colors.primary),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: value,
                style: context.theme.typography.body.sm.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (unit != null)
                TextSpan(
                  text: ' $unit',
                  style: context.theme.typography.body.xs.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
