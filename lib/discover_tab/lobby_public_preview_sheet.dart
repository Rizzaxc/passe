import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../core/model/enum.dart';
import '../core/model/lobby_public_preview.dart';
import '../ui/main.dart';
import 'lobby_public_preview_controller.dart';

/// Same OSM user-agent convention as the Location subtab's map
/// (`lib/discover_tab/location_section/main.dart`) — required by OSM's tile
/// usage policy.
const _tileUserAgent = 'passe.vn.passe';

/// A public, read-only preview of a lobby — reachable by guests and
/// non-members straight from a Discover card tap. Deliberately NOT the
/// member-oriented `LobbyDetailPage`/`LobbyDetailRoute` "hub".
Future<void> showLobbyPublicPreviewSheet(BuildContext context, String lobbyId) {
  return showPSheet(
    context: context,
    maxHeightRatio: 1.0,
    builder: (_) => LobbyPublicPreviewSheet(lobbyId: lobbyId),
  );
}

class LobbyPublicPreviewSheet extends ConsumerWidget {
  final String lobbyId;

  const LobbyPublicPreviewSheet({super.key, required this.lobbyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewAsync = ref.watch(lobbyPublicPreviewProvider(lobbyId));

    return previewAsync.when(
      loading: () => const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => _PreviewMessage(
        icon: FLucideIcons.circleX,
        message: 'errorGeneric'.tr(),
      ),
      data: (preview) => preview == null
          ? _PreviewMessage(
              icon: FLucideIcons.searchX,
              message: 'lobby.preview.notFound'.tr(),
            )
          : _PreviewContent(preview: preview),
    );
  }
}

class _PreviewMessage extends StatelessWidget {
  final IconData icon;
  final String message;

  const _PreviewMessage({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PSheetTitle(
          label: '',
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
                  style: TextStyle(color: context.theme.colors.mutedForeground),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewContent extends StatelessWidget {
  final LobbyPublicPreview preview;

  const _PreviewContent({required this.preview});

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
                                    .map((h) => h.name)
                                    .join(', ')
                              : preview.homegroundName!,
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
                          icon: Icons.schedule_rounded,
                          label:
                              '${ts.dayChunk.getShortName(context)} ${ts.dayOfWeek.getShortName(context)}',
                        ),
                      )
                      .toList(),
                ),
              ],
            ),

          // MMR
          PMatchBoard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  preview.hasProvisionalMmr
                      ? '${preview.mmr} · ${'homeTab.challenger.provisional'.tr()}'
                      : '${preview.mmr}',
                  style: context.theme.typography.body.sm.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

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
