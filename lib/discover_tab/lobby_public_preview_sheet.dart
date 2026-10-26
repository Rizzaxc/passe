import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../core/model/enum.dart';
import '../core/model/lobby_public_preview.dart';
import '../core/model/mmr_tier.dart';
import '../router.dart';
import '../ui/main.dart';
import 'lobby_feed_card.dart' show matchFactorSpecs;
import 'lobby_join_button.dart';
import 'lobby_public_preview_controller.dart';

/// Same OSM user-agent convention as the Location subtab's map
/// (`lib/discover_tab/location_section/main.dart`) — required by OSM's tile
/// usage policy.
const _tileUserAgent = 'passe.vn.passe';

/// A public preview of a lobby — reachable by guests and non-members
/// straight from a Discover card tap. Deliberately NOT the member-oriented
/// `LobbyDetailPage`/`LobbyDetailRoute` "hub".
///
/// [joinAlreadyRequested] non-null pins a "Xin vào" footer (the Teammates
/// feed passes its baseline request state): the sheet is where a player
/// decides, so the decision has to be makeable here, not back on the card.
/// [fitScore] / [matchFactors] carry the card's match readout in.
Future<void> showLobbyPublicPreviewSheet(
  BuildContext context,
  String lobbyId, {
  bool? joinAlreadyRequested,
  double? fitScore,
  List<String> matchFactors = const [],
}) {
  return showPSheet(
    context: context,
    maxHeightRatio: 1.0,
    builder: (_) => LobbyPublicPreviewSheet(
      lobbyId: lobbyId,
      joinAlreadyRequested: joinAlreadyRequested,
      fitScore: fitScore,
      matchFactors: matchFactors,
    ),
  );
}

class LobbyPublicPreviewSheet extends ConsumerWidget {
  final String lobbyId;
  final bool? joinAlreadyRequested;
  final double? fitScore;
  final List<String> matchFactors;

  const LobbyPublicPreviewSheet({
    super.key,
    required this.lobbyId,
    this.joinAlreadyRequested,
    this.fitScore,
    this.matchFactors = const [],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewAsync = ref.watch(lobbyPublicPreviewProvider(lobbyId));

    return previewAsync.when(
      loading: () => const SizedBox(
        height: 240,
        child: Center(child: FCircularProgress()),
      ),
      error: (_, _) => _PreviewMessage(
        icon: FLucideIcons.wifiOff,
        title: 'lobby.preview.loadError'.tr(),
        message: 'homeTab.loadError.message'.tr(),
        onRetry: () => ref.invalidate(lobbyPublicPreviewProvider(lobbyId)),
      ),
      data: (preview) => preview == null
          ? _PreviewMessage(
              icon: FLucideIcons.searchX,
              message: 'lobby.preview.notFound'.tr(),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Flexible(
                  child: _PreviewContent(
                    preview: preview,
                    fitScore: fitScore,
                    matchFactors: matchFactors,
                  ),
                ),
                if (joinAlreadyRequested != null) ...[
                  const SizedBox(height: 12),
                  LobbyJoinButton(
                    lobbyId: lobbyId,
                    alreadyRequested: joinAlreadyRequested!,
                    expand: true,
                  ),
                ],
              ],
            ),
    );
  }
}

class _PreviewMessage extends StatelessWidget {
  final IconData icon;
  final String? title;
  final String message;
  final VoidCallback? onRetry;

  const _PreviewMessage({
    required this.icon,
    this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PSheetTitle(
          label: title ?? '',
          trailing: FButton.icon(
            variant: .ghost,
            onPress: () => Navigator.of(context).pop(),
            child: const Icon(FLucideIcons.x),
          ),
        ),
        SizedBox(
          height: 180,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                Icon(
                  icon,
                  size: 40,
                  color: context.theme.colors.mutedForeground,
                ),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.theme.colors.mutedForeground),
                ),
                if (onRetry != null)
                  FButton(
                    size: .sm,
                    variant: .outline,
                    prefix: const Icon(FLucideIcons.rotateCw),
                    onPress: onRetry,
                    child: Text('homeTab.loadError.retry'.tr()),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String _districtLabel(BuildContext context, String? raw) {
  if (raw == null || raw.trim().isEmpty) return '';
  final district = VietnamLocationData.instance.findDistrictByStoredValue(raw);
  return district?.getLocalizedFullName(context) ?? raw;
}

class _PreviewContent extends StatelessWidget {
  final LobbyPublicPreview preview;
  final double? fitScore;
  final List<String> matchFactors;

  const _PreviewContent({
    required this.preview,
    this.fitScore,
    this.matchFactors = const [],
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return SingleChildScrollView(
      primary: false,
      child: Column(
        spacing: 18,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PSheetTitle(
            label: preview.name,
            trailing: FButton.icon(
              variant: .ghost,
              onPress: () => Navigator.of(context).pop(),
              child: const Icon(FLucideIcons.x),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                preview.sport.getIcon(size: 14),
                const SizedBox(width: 6),
                Text(
                  preview.sport.getLocalizedName(context),
                  style: context.theme.typography.body.sm.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
                Text(
                  ' · ',
                  style: TextStyle(
                    color: colors.mutedForeground.withValues(alpha: 0.4),
                  ),
                ),
                Icon(
                  FLucideIcons.users,
                  size: 13,
                  color: colors.mutedForeground,
                ),
                const SizedBox(width: 4),
                Text(
                  '${preview.memberCount}',
                  style: context.theme.typography.body.sm.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),

          if (fitScore != null)
            _FitSummary(score: fitScore!, factors: matchFactors),

          _People(preview: preview),

          // Homeground(s) + map
          if (preview.homegroundName != null) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                PSheetSectionLabel(
                  label: preview.homegrounds.length > 1
                      ? 'createLobby.homeGrounds'.tr()
                      : 'createLobby.homeGround'.tr(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      Icon(
                        FLucideIcons.mapPin,
                        size: 13,
                        color: colors.mutedForeground,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          preview.homegrounds.length > 1
                              ? preview.homegrounds
                                    .map(
                                      (h) => [
                                        h.name,
                                        _districtLabel(context, h.district),
                                      ].where((s) => s.isNotEmpty).join(' · '),
                                    )
                                    .join(', ')
                              : [
                                  preview.homegroundName!,
                                  _districtLabel(
                                    context,
                                    preview.homegroundDistrict,
                                  ),
                                ].where((s) => s.isNotEmpty).join(' · '),
                          style: context.theme.typography.body.sm,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (preview.hasCoord) _HomeGroundMap(preview: preview),
              ],
            ),
          ],

          // Playtime
          if (preview.playtime.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                PSheetSectionLabel(label: 'createLobby.playtime'.tr()),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: preview.playtime
                      .map(
                        (ts) => _PreviewChip(
                          icon: FLucideIcons.clock,
                          label:
                              '${ts.dayChunk.getShortName(context)} ${ts.dayOfWeek.getShortName(context)}',
                        ),
                      )
                      .toList(),
                ),
              ],
            ),

          // MMR — shown for every non-private lobby (the RPC nulls it
          // otherwise), Teammates and Challenger alike.
          if (preview.mmr case final mmr?) _MmrTile(mmr: mmr, preview: preview),

          // Description
          if (preview.description != null &&
              preview.description!.trim().isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                PSheetSectionLabel(label: 'lobby.description'.tr()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    preview.description!,
                    style: context.theme.typography.body.sm.copyWith(
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),

          // Gender makeup
          if (preview.gender.declared > 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                PSheetSectionLabel(
                  label: 'lobby.preview.gender'.tr(
                    namedArgs: {
                      'declared': '${preview.gender.declared}',
                      'total': '${preview.memberCount}',
                    },
                  ),
                ),
                _DemographicBar(
                  segments: [
                    if (preview.gender.male > 0)
                      (preview.gender.male, pbBlue, 'gender.male'.tr()),
                    if (preview.gender.female > 0)
                      (preview.gender.female, pbCoral, 'gender.female'.tr()),
                  ],
                ),
              ],
            ),

          // Age group breakdown
          if (preview.ageGroupCounts.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                PSheetSectionLabel(label: 'lobby.preview.ageGroup'.tr()),
                _DemographicBar(
                  segments: [
                    for (final ag in AgeGroup.values)
                      if ((preview.ageGroupCounts[ag] ?? 0) > 0)
                        (
                          preview.ageGroupCounts[ag]!,
                          switch (ag) {
                            AgeGroup.student => pbBlue,
                            AgeGroup.mature => pbAmber,
                            AgeGroup.middleAge => pbCoral,
                          },
                          ag.getLocalizedName(context),
                        ),
                  ],
                ),
              ],
            ),

          // Top networks
          if (preview.topNetworks.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                PSheetSectionLabel(label: 'lobby.preview.networks'.tr()),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: preview.topNetworks
                      .map(
                        (n) => _PreviewChip(
                          icon: FLucideIcons.users,
                          label: '${n.name} · ${n.count}',
                        ),
                      )
                      .toList(),
                ),
              ],
            ),

          // Top industries
          if (preview.topIndustries.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                PSheetSectionLabel(label: 'lobby.preview.industries'.tr()),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: preview.topIndustries
                      .map(
                        (i) => _PreviewChip(
                          icon: FLucideIcons.briefcase,
                          label:
                              '${i.industry.getLocalizedName(context)} · ${i.count}',
                        ),
                      )
                      .toList(),
                ),
              ],
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _HomeGroundMap extends StatelessWidget {
  final LobbyPublicPreview preview;

  const _HomeGroundMap({required this.preview});

  @override
  Widget build(BuildContext context) {
    // One marker per homeground with coordinates; falls back to the single
    // primary point when the list is empty (older/uncached response shape).
    final points = [
      for (final h in preview.homegrounds)
        if (h.lat != null && h.lon != null) LatLng(h.lat!, h.lon!),
    ];
    if (points.isEmpty) {
      points.add(LatLng(preview.homegroundLat!, preview.homegroundLon!));
    }

    return ClipRRect(
      borderRadius: context.theme.style.borderRadius.md,
      child: SizedBox(
        height: 160,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: points.first,
            initialZoom: 15,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: _tileUserAgent,
              maxZoom: 19,
            ),
            MarkerLayer(
              markers: [
                for (final point in points)
                  Marker(
                    point: point,
                    width: 34,
                    height: 34,
                    alignment: Alignment.topCenter,
                    child: Icon(
                      FLucideIcons.mapPin,
                      size: 30,
                      color: context.theme.colors.primary,
                      shadows: const [
                        Shadow(blurRadius: 4, color: Colors.black38),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A generic stacked-segment bar with a color-dot legend, sized by [segments]'
/// counts. Same structural shape as `ZoneBar`
/// (`lib/health_tab/activity_data_section/zone_bar.dart`), rebuilt locally
/// and generically here since that widget hardcodes 3 fixed health zones
/// with health-specific colors/translation keys.
class _DemographicBar extends StatelessWidget {
  final List<(int count, Color color, String label)> segments;

  const _DemographicBar({required this.segments});

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<int>(0, (sum, s) => sum + s.$1);
    if (total == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(
            children: [
              for (final (count, color, _) in segments)
                if (count > 0)
                  Expanded(
                    flex: count,
                    child: Container(height: 10, color: color),
                  ),
            ],
          ),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            for (final (count, color, label) in segments)
              if (count > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 4,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Text(
                      '$label · ${((count / total) * 100).round()}%',
                      style: context.theme.typography.body.xs.copyWith(
                        color: context.theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
          ],
        ),
      ],
    );
  }
}

/// A light-theme pill chip — same rounded/icon+label shape as the Discover
/// card's `_FitScoreVibes` chips, but tinted for a light sheet background
/// instead of white-on-navy.
class _PreviewChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PreviewChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: pbBlueDeep.withValues(alpha: 0.06),
        border: Border.all(color: pbBlueDeep.withValues(alpha: 0.16)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Icon(icon, size: 11, color: pbBlueDeep),
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
    );
  }
}

/// The card's FitScore, restated where the decision is made.
class _FitSummary extends StatelessWidget {
  final double score;
  final List<String> factors;

  const _FitSummary({required this.score, required this.factors});

  @override
  Widget build(BuildContext context) {
    final specs = matchFactorSpecs(factors);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        PSheetSectionLabel(
          label: 'lobby.preview.fit'.tr(
            namedArgs: {'score': score.toStringAsFixed(1)},
          ),
        ),
        if (specs.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final (label, icon) in specs)
                _PreviewChip(icon: icon, label: label),
            ],
          ),
      ],
    );
  }
}

/// Captain + a strip of member faces, each tapping through to /user/:id.
/// Identities only come back for signed-in viewers; a guest gets one line
/// saying why the faces are missing instead of an unexplained gap.
class _People extends ConsumerWidget {
  final LobbyPublicPreview preview;

  const _People({required this.preview});

  static const _avatarRadius = 18.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final captain = preview.captain;
    final faces = preview.membersPreview;
    final extra = preview.memberCount - faces.length;

    if (captain == null && faces.isEmpty) {
      return Text(
        'lobby.preview.signInForMembers'.tr(),
        style: context.theme.typography.body.sm.copyWith(
          color: colors.mutedForeground,
        ),
      );
    }

    void open(LobbyPreviewPerson p) => UserRoute(id: p.id).push(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        PSheetSectionLabel(label: 'lobby.preview.members'.tr()),
        if (captain != null)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => open(captain),
            child: Row(
              spacing: 10,
              children: [
                PUserAvatar(
                  userId: captain.id,
                  username: captain.username,
                  generatedAvatar: captain.generatedAvatar,
                  radius: _avatarRadius,
                ),
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: captain.username,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text: ' #${captain.tagNumber}',
                          style: TextStyle(color: colors.mutedForeground),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.theme.typography.body.sm,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.secondary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'lobby.preview.captain'.tr(),
                    style: context.theme.typography.body.xs.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (faces.length > 1 || extra > 0)
          Row(
            spacing: 6,
            children: [
              for (final p in faces.where((p) => p.id != captain?.id))
                PUserAvatar(
                  userId: p.id,
                  username: p.username,
                  generatedAvatar: p.generatedAvatar,
                  radius: _avatarRadius,
                  onTap: () => open(p),
                ),
              if (extra > 0)
                CircleAvatar(
                  radius: _avatarRadius,
                  backgroundColor: colors.secondary,
                  child: Text(
                    '+$extra',
                    style: context.theme.typography.body.xs.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.secondaryForeground,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// MMR as a level, not a bare number: the tier word, a 5-step meter, and how
/// much evidence stands behind it. Below the provisional threshold the number
/// is mostly the members' self-declared seeds, so it says "Ước Lượng" and
/// explains itself on tap rather than passing as earned.
class _MmrTile extends StatelessWidget {
  final int mmr;
  final LobbyPublicPreview preview;

  const _MmrTile({required this.mmr, required this.preview});

  @override
  Widget build(BuildContext context) {
    final tier = MmrTier.fromMmr(mmr);
    final evidence = preview.ratedMatchCount == 0
        ? 'lobby.preview.noRatedMatches'.tr()
        : 'lobby.preview.ratedMatches'.tr(
            namedArgs: {'count': '${preview.ratedMatchCount}'},
          );
    final colors = context.theme.colors;
    final footnote = context.theme.typography.body.xs.copyWith(
      color: colors.mutedForeground,
    );

    return PStatTile(
      label: 'homeTab.challenger.mmr'.tr(),
      icon: FLucideIcons.swords,
      value: '$mmr',
      meter: (tier.level, MmrTier.values.length),
      footer: preview.hasProvisionalMmr
          ? FTappable(
              onPress: () => showFToast(
                context: context,
                icon: const Icon(FLucideIcons.info),
                title: Text('homeTab.challenger.provisional'.tr()),
                description: Text('lobby.preview.provisionalHelp'.tr()),
                alignment: .bottomCenter,
              ),
              child: Row(
                spacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 4,
                      children: [
                        Text(
                          'homeTab.challenger.provisional'.tr(),
                          style: footnote.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.foreground,
                            height: 1.0,
                          ),
                        ),
                        Icon(
                          FLucideIcons.info,
                          size: 12,
                          color: colors.mutedForeground,
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Text(
                      evidence,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: footnote,
                    ),
                  ),
                ],
              ),
            )
          : Text(evidence, style: footnote),
    );
  }
}
