import 'package:easy_localization/easy_localization.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/format.dart';
import '../core/model/enum.dart';
import '../core/model/lobby_feed_item.dart';
import '../core/model/timeslot.dart';
import '../ui/main.dart';
import 'filter.dart';
import 'lobby_public_preview_sheet.dart';

/// Score floor of `calculate_profile_compat_score` — the neutral baseline a
/// lobby with *no* shared signal (no network/industry/skill/age/gender match)
/// sits at exactly. `calculate_profile_compat` never returns anything below
/// it, and it never returns *this* value with a non-empty `match_factors`
/// either — the two always move together. So there's no such thing as a
/// scored-but-empty card in real data: the floor itself IS the "we have
/// nothing in common yet" case, and the card treats it like having no
/// FitScore at all rather than rendering a number with nothing backing it.
const double _fitScoreFloor = 2.5;

class LobbyFeedCard extends ConsumerWidget {
  final LobbyFeedItem item;
  final Widget action;
  final bool showCompat;

  /// Pin a "Xin vào" footer to the preview sheet this card opens — the
  /// Teammates feed. Challenger's CTA is a challenge, not a join request.
  final bool joinFromPreview;

  const LobbyFeedCard({
    super.key,
    required this.item,
    required this.action,
    this.showCompat = true,
    this.joinFromPreview = false,
  });

  static const _maxTimeslots = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final score = item.profileCompatScore;

    // Slots that line up with what the player is filtering for go first and
    // read as matched, so schedule fit is visible on the card itself rather
    // than only as an unexplained "Lịch chơi khớp" tag.
    final wanted = ref.watch(filterStateProvider.select((f) => f.schedule));
    final matched = {for (final t in item.playtime) if (wanted.contains(t)) t};
    final slots = [
      ...item.playtime.where(matched.contains),
      ...item.playtime.where((t) => !matched.contains(t)),
    ];
    final hiddenSlots = slots.length - _maxTimeslots;
    final isGoodFit = score > _fitScoreFloor;
    final hasFit = showCompat && isGoodFit;
    final frameColor = hasFit ? pbMint : pbAmber;
    final radius = BorderRadius.circular(16);

    // MMR with no FitScore signal to pair it with — common on Challenger,
    // where an opponent is matched by skill first and may share nothing else
    // with you. Rather than give it the full-width match board to itself, it
    // rides as a compact badge under the member count instead.
    final soloMmr = item.lobbyMmr != null && !hasFit;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showLobbyPublicPreviewSheet(
        context,
        item.id,
        joinAlreadyRequested: joinFromPreview ? item.alreadyRequested : null,
        fitScore: hasFit ? score : null,
        matchFactors: hasFit ? item.matchFactors : const [],
      ),
      child: POffsetFrame(
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
                                        .copyWith(color: colors.mutedForeground),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    if (item.memberCount != null || soloMmr) ...[
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        spacing: 6,
                        children: [
                          if (item.memberCount != null)
                            _MemberBadge(count: item.memberCount!),
                          if (soloMmr)
                            _MmrBadge(
                              mmr: item.lobbyMmr!,
                              provisional: item.hasProvisionalMmr,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
                if (item.description != null &&
                    item.description!.trim().isNotEmpty)
                  _LobbyDescription(description: item.description!),
                if (slots.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final ts in slots.take(_maxTimeslots))
                        _TimeslotChip(
                          label: _slotLabel(context, ts),
                          matched: matched.contains(ts),
                        ),
                      if (hiddenSlots > 0) _TimeslotChip(label: '+$hiddenSlots'),
                    ],
                  ),
                if (hasFit)
                  _LobbyMatchBoard(
                    item: item,
                    showCompat: showCompat,
                    isGoodFit: isGoodFit,
                  ),

                if (item.offerTime != null) _OfferStrip(item: item),
                Row(
                  children: [
                    // The whole card opens the preview; this says so.
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              'lobby.preview.open'.tr(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.theme.typography.body.sm.copyWith(
                                color: colors.mutedForeground,
                              ),
                            ),
                          ),
                          Icon(
                            FLucideIcons.chevronRight,
                            size: 16,
                            color: colors.mutedForeground,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    action,
                  ],
                ),
              ],
            ),
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

/// Compact MMR readout for the "no FitScore signal" case — same dark-pill
/// idiom as [_MemberBadge] (stacked directly beneath it) rather than the full
/// [_LobbyMatchBoard], since there's no second stat here to justify a whole
/// board. Icon matches the "⚔ MMR" pill used in the Manage tab's own lobby
/// list (`lib/manage_tab/lobby_section/feed/main.dart`'s `_LobbyMetaPill`).
class _MmrBadge extends StatelessWidget {
  final int mmr;
  final bool provisional;

  const _MmrBadge({required this.mmr, required this.provisional});

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
        const Icon(FLucideIcons.swords, size: 12, color: Colors.white),
        Text(
          provisional ? '$mmr ?' : '$mmr',
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

  // The caller only renders this board when `showCompat && isGoodFit` — a
  // bare MMR with no FitScore rides as a compact badge under the member
  // count instead (see `LobbyFeedCard.soloMmr`), so FitScore is always
  // present here; MMR is the only optional half.
  @override
  Widget build(BuildContext context) {
    final score = item.profileCompatScore;
    final hasMmr = item.lobbyMmr != null;
    final vibes = matchFactorSpecs(item.matchFactors);

    final fitBlock = _StatBlock(
      label: 'FITSCORE',
      value: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: score.toStringAsFixed(1),
              style: TextStyle(
                color: isGoodFit ? pbAmber : Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            TextSpan(
              text: ' / 5',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        maxLines: 1,
      ),
    );

    final mmrBlock = !hasMmr
        ? null
        : _StatBlock(
            alignEnd: true,
            label: 'homeTab.challenger.mmr'.tr().toUpperCase(),
            labelIcon: FLucideIcons.swords,
            value: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '${item.lobbyMmr}'),
                  // "?" marks a provisional (seed-derived, not yet earned) MMR.
                  if (item.hasProvisionalMmr)
                    TextSpan(
                      text: ' ?',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            footer: item.favorability != null
                ? _FavorabilityBadge(favorability: item.favorability!)
                : null,
          );

    final Widget statRow;
    if (mmrBlock != null) {
      // Both stats: a two-column grid with a hairline divider — a real
      // structure instead of one side just trailing off wherever its content
      // happened to end. FitScore gets 2/3 of the width (it usually carries
      // the vibe tags too) and MMR the remaining 1/3.
      statRow = IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 2, child: fitBlock),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(
                width: 1,
                color: Colors.white.withValues(alpha: 0.14),
              ),
            ),
            Expanded(child: mmrBlock),
          ],
        ),
      );
    } else {
      // FitScore-only (the teammate feed, always): let the vibe tags share
      // this same line instead of leaving the rest of the board blank, which
      // is what happened when a lobby matched on only one or two signals.
      statRow = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          fitBlock,
          if (vibes.isNotEmpty) ...[
            const SizedBox(width: 16),
            Expanded(child: _FitScoreVibes(factors: vibes)),
          ],
        ],
      );
    }

    return PMatchBoard(
      showCourtLines: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          statRow,
          // Only needed as its own row when the stat row above was already
          // spoken for by both columns.
          if (mmrBlock != null && vibes.isNotEmpty) _FitScoreVibes(factors: vibes),
        ],
      ),
    );
  }
}

/// One labeled stat inside [_LobbyMatchBoard] — a caption, a big value, and an
/// optional footer (badge/qualifier) — always in that vertical order so the
/// FitScore and MMR columns line up on the same grid instead of drifting to
/// whatever height their own content happens to need.
class _StatBlock extends StatelessWidget {
  final String label;
  final IconData? labelIcon;
  final Widget value;
  final Widget? footer;
  final bool alignEnd;

  const _StatBlock({
    required this.label,
    this.labelIcon,
    required this.value,
    this.footer,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxis = alignEnd
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final labelStyle = context.theme.typography.body.xs.copyWith(
      color: Colors.white.withValues(alpha: 0.6),
      fontSize: 9,
      fontWeight: FontWeight.w800,
      letterSpacing: 1,
    );
    return Column(
      crossAxisAlignment: crossAxis,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 4,
      children: [
        if (labelIcon == null)
          Text(label, textAlign: alignEnd ? TextAlign.end : TextAlign.start, style: labelStyle)
        else
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [
              Icon(labelIcon, size: 10, color: Colors.white.withValues(alpha: 0.6)),
              Text(label, style: labelStyle),
            ],
          ),
        value,
        ?footer,
      ],
    );
  }
}

/// The lobby's optional description: two lines of muted body copy, no
/// panel, no caps label. It used to be a second navy `PMatchBoard`, which
/// shouted as loud as the FitScore board and made a described card read as
/// two stacked banners. It's a tagline, so it sits quietly under the header.
class _LobbyDescription extends StatelessWidget {
  final String description;

  const _LobbyDescription({required this.description});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Text(
      description.trim(),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: context.theme.typography.body.sm.copyWith(
        color: colors.mutedForeground,
        height: 1.4,
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

// Keep the factor language monochrome inside the match board. The prior
// rainbow of micro-chips read as analytics tags instead of one cohesive
// sports graphic.
// Network/industry icons match the ones the profile tab uses for the same
// concepts (`lib/profile_tab/main.dart`'s network/industry tiles) so the same
// idea reads as the same glyph everywhere in the app.
/// Public so the preview sheet can render the same factor language.
(String, IconData)? matchFactorSpec(String code) {
  final icon = switch (code) {
    'skill' => FLucideIcons.trophy,
    'network' => FLucideIcons.network,
    'industry' => FLucideIcons.briefcaseBusiness,
    'age' => FLucideIcons.cake,
    'gender' => FLucideIcons.venus,
    'playtime' => FLucideIcons.calendar,
    'location' => FLucideIcons.mapPin,
    _ => null,
  };
  return icon == null ? null : ('lobby.matchFactor.$code'.tr(), icon);
}

String _slotLabel(BuildContext context, Timeslot ts) =>
    '${ts.dayChunk.getShortName(context)} ${ts.dayOfWeek.getShortName(context)}';

List<(String, IconData)> matchFactorSpecs(List<String> codes) => [
  for (final code in codes) ?matchFactorSpec(code),
];

/// The real matched-factor tags, as plain icon+label pairs with no
/// pill/border chrome — a wall of bordered badges was both harder to read
/// against the board's navy (the fill+border barely lifted off it) and, once
/// a lobby matched on several signals, overpowering next to the score itself.
/// Capped to [_maxShown] with a bare "+N" tail so it can't do that again.
class _FitScoreVibes extends StatelessWidget {
  final List<(String, IconData)> factors;

  static const _maxShown = 4;

  const _FitScoreVibes({required this.factors});

  @override
  Widget build(BuildContext context) {
    if (factors.isEmpty) return const SizedBox.shrink();
    final shown = factors.take(_maxShown);
    final overflow = factors.length - _maxShown;

    return Wrap(
      spacing: 14,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final (label, icon) in shown)
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 5,
            children: [
              Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.85)),
              Text(
                label,
                style: TextStyle(
                  fontFamily: context.theme.typography.body.xs.fontFamily,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        if (overflow > 0)
          Text(
            '+$overflow',
            style: TextStyle(
              fontFamily: context.theme.typography.body.xs.fontFamily,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ),
      ],
    );
  }
}

/// One playtime slot. `matched` = it's one the player filtered for. The
/// "+N" overflow chip passes neither an icon-worthy slot nor a match.
class _TimeslotChip extends StatelessWidget {
  final String label;
  final bool matched;

  const _TimeslotChip({required this.label, this.matched = false});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: matched
            ? pbMint.withValues(alpha: 0.35)
            : pbInk.withValues(alpha: 0.055),
        border: Border.all(
          color: matched ? pbMint : pbInk.withValues(alpha: 0.12),
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            if (!label.startsWith('+'))
              Icon(
                matched ? FLucideIcons.check : FLucideIcons.clock,
                size: 12,
                color: pbBlueDeep,
              ),
            Text(
              label,
              style: context.theme.typography.body.xs.copyWith(
                fontWeight: FontWeight.w700,
                color: pbInk,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
