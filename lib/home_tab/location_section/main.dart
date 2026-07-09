import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/model/enum.dart';
import '../../core/model/location.dart';
import '../../ui/main.dart';
import '../filter.dart';
import 'feed_controller.dart';

/// Which view the venue subtab is showing. Held locally (not persisted) — a
/// glance-and-go preference, unlike the shared filter.
enum _VenueView { list, map }

/// User agent sent to the OpenStreetMap tile server (their usage policy asks
/// for an identifying UA). Uses the app bundle id.
const _tileUserAgent = 'passe.vn.passe';

/// Ho Chi Minh City centre — the map's fallback focus when no venue in the
/// current result set has coordinates yet.
const _hcmcCentre = LatLng(10.776, 106.700);

class LocationSubtab extends ConsumerStatefulWidget {
  const LocationSubtab({super.key});

  @override
  ConsumerState<LocationSubtab> createState() => _LocationSubtabState();
}

class _LocationSubtabState extends ConsumerState<LocationSubtab> {
  _VenueView _view = _VenueView.list;

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(locationFeedProvider);

    return Column(
      children: [
        PSectionHeader(
          title: 'home.location'.tr(),
          suffix: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              PPillToggle<_VenueView>(
                value: _view,
                onChanged: (v) => setState(() => _view = v),
                options: const [
                  PPillOption(value: _VenueView.list, icon: FLucideIcons.list),
                  PPillOption(value: _VenueView.map, icon: FLucideIcons.map),
                ],
              ),
              const FilterWidget(),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: feed.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => _ErrorOrRefreshList(
              onRefresh: _refresh,
              child: PEmptySectionPlaceholder(
                hero: Icon(
                  FLucideIcons.searchX,
                  size: 64,
                  color: context.theme.colors.mutedForeground,
                ),
                title: 'homeTab.empty.title'.tr(),
                subtitle: 'homeTab.empty.message'.tr(),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return _ErrorOrRefreshList(
                  onRefresh: _refresh,
                  child: PEmptySectionPlaceholder(
                    hero: Icon(
                      FLucideIcons.mapPin,
                      size: 64,
                      color: context.theme.colors.mutedForeground,
                    ),
                    title: 'homeTab.location.empty.title'.tr(),
                    subtitle: 'homeTab.location.empty.message'.tr(),
                  ),
                );
              }
              return switch (_view) {
                _VenueView.list => _VenueList(
                  items: items,
                  onRefresh: _refresh,
                ),
                _VenueView.map => _VenueMap(items: items),
              };
            },
          ),
        ),
      ],
    );
  }

  Future<void> _refresh() async {
    ref.invalidate(locationFeedProvider);
    await ref.read(locationFeedProvider.future);
  }
}

/// Scrollable wrapper so the empty/error placeholders still support
/// scroll-to-refresh (the feed contract for every home subtab).
class _ErrorOrRefreshList extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const _ErrorOrRefreshList({required this.onRefresh, required this.child});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [child],
      ),
    );
  }
}

// ── List view ────────────────────────────────────────────────────────────

class _VenueList extends StatelessWidget {
  final List<Location> items;
  final Future<void> Function() onRefresh;

  const _VenueList({required this.items, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _VenueCard(location: items[index]),
      ),
    );
  }
}

class _VenueCard extends StatelessWidget {
  final Location location;

  const _VenueCard({required this.location});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final address = location.displayAddress;
    final sports = location.sports;
    final amenities = location.amenityKeys;

    return FCard(
      child: FTappable(
        onPress: () => _showVenueSheet(context, location),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 6,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Expanded(
                  child: Text(
                    location.name,
                    style: context.theme.typography.body.sm.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.primary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  FLucideIcons.chevronRight,
                  size: 16,
                  color: colors.mutedForeground,
                ),
              ],
            ),
            if (address.isNotEmpty)
              Row(
                spacing: 4,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(
                      FLucideIcons.mapPin,
                      size: 12,
                      color: colors.mutedForeground,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      address,
                      style: context.theme.typography.body.sm.copyWith(
                        color: colors.mutedForeground,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            if (sports.isNotEmpty || amenities.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final s in sports) _SportChip(sport: s),
                  for (final a in amenities)
                    _TagChip(label: 'homeTab.location.amenity.$a'.tr()),
                ],
              ),
            const FDivider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: 8,
              children: [
                FButton(
                  size: .sm,
                  variant: .secondary,
                  onPress: location.coord == null
                      ? null
                      : () => _openDirections(context, location),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 4,
                    children: [
                      const Icon(FLucideIcons.navigation, size: 14),
                      Text('homeTab.location.directions'.tr()),
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

/// Matches the professional subtab's `_SportChip` pill styling for a
/// consistent visual language across the home tab.
class _SportChip extends StatelessWidget {
  final Sport sport;

  const _SportChip({required this.sport});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 5,
        children: [
          sport.getIcon(size: 12),
          Text(
            sport.getLocalizedName(context),
            style: context.theme.typography.body.xs.copyWith(
              color: colors.secondaryForeground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;

  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: context.theme.style.borderRadius.sm,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          label,
          style: context.theme.typography.body.xs.copyWith(
            color: colors.secondaryForeground,
          ),
        ),
      ),
    );
  }
}

// ── Map view ─────────────────────────────────────────────────────────────

class _VenueMap extends StatelessWidget {
  final List<Location> items;

  const _VenueMap({required this.items});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final located = items.where((l) => l.coord != null).toList();

    final camera = located.isEmpty
        ? const MapOptions(initialCenter: _hcmcCentre, initialZoom: 11)
        : located.length == 1
        ? MapOptions(initialCenter: located.first.coord!, initialZoom: 15)
        : MapOptions(
            initialCameraFit: CameraFit.coordinates(
              coordinates: [for (final l in located) l.coord!],
              padding: const EdgeInsets.all(48),
              maxZoom: 15,
            ),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ClipRRect(
        borderRadius: context.theme.style.borderRadius.md,
        child: Stack(
          children: [
            FlutterMap(
              options: camera,
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: _tileUserAgent,
                  maxZoom: 19,
                ),
                MarkerLayer(
                  markers: [
                    for (final venue in located)
                      Marker(
                        point: venue.coord!,
                        width: 40,
                        height: 40,
                        alignment: Alignment.topCenter,
                        child: GestureDetector(
                          onTap: () => _showVenueSheet(context, venue),
                          child: Icon(
                            FLucideIcons.mapPin,
                            size: 34,
                            color: colors.primary,
                            shadows: const [
                              Shadow(blurRadius: 4, color: Colors.black38),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                // OSM tile usage policy requires visible attribution.
                const _OsmAttribution(),
              ],
            ),
            if (located.length < items.length)
              Positioned(
                left: 8,
                top: 8,
                child: _MapNotice(text: 'homeTab.location.someUnmapped'.tr()),
              ),
          ],
        ),
      ),
    );
  }
}

class _OsmAttribution extends StatelessWidget {
  const _OsmAttribution();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: EdgeInsets.all(4),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Color(0xCCFFFFFF),
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Text(
              '© OpenStreetMap',
              style: TextStyle(fontSize: 9, color: Color(0xFF333333)),
            ),
          ),
        ),
      ),
    );
  }
}

class _MapNotice extends StatelessWidget {
  final String text;

  const _MapNotice({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background.withValues(alpha: 0.92),
        borderRadius: context.theme.style.borderRadius.sm,
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          text,
          style: context.theme.typography.body.xs.copyWith(
            color: colors.mutedForeground,
          ),
        ),
      ),
    );
  }
}

// ── Venue detail sheet ─────────────────────────────────────────────────────

void _showVenueSheet(BuildContext context, Location location) {
  showPSheet(
    context: context,
    maxHeightRatio: 1.0,
    builder: (_) => _VenueDetailSheet(location: location),
  );
}

class _VenueDetailSheet extends StatelessWidget {
  final Location location;

  const _VenueDetailSheet({required this.location});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final address = location.displayAddress;
    final sports = location.sports;
    final amenities = location.amenityKeys;
    final coord = location.coord;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          PSheetTitle(
            label: location.name,
            trailing: FButton.icon(
              variant: .ghost,
              onPress: () => Navigator.of(context).pop(),
              child: const Icon(FLucideIcons.x),
            ),
          ),
          if (coord != null)
            ClipRRect(
              borderRadius: context.theme.style.borderRadius.md,
              child: SizedBox(
                height: 180,
                child: Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: coord,
                        initialZoom: 16,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: _tileUserAgent,
                          maxZoom: 19,
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: coord,
                              width: 40,
                              height: 40,
                              alignment: Alignment.topCenter,
                              child: Icon(
                                FLucideIcons.mapPin,
                                size: 34,
                                color: colors.primary,
                              ),
                            ),
                          ],
                        ),
                        const _OsmAttribution(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          if (address.isNotEmpty) ...[
            PSheetSectionLabel(label: 'homeTab.location.address'.tr()),
            Row(
              spacing: 6,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    FLucideIcons.mapPin,
                    size: 14,
                    color: colors.mutedForeground,
                  ),
                ),
                Expanded(
                  child: Text(address, style: context.theme.typography.body.sm),
                ),
              ],
            ),
          ],
          if (sports.isNotEmpty || amenities.isNotEmpty) ...[
            PSheetSectionLabel(label: 'homeTab.location.amenities'.tr()),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in sports) _SportChip(sport: s),
                for (final a in amenities)
                  _TagChip(label: 'homeTab.location.amenity.$a'.tr()),
              ],
            ),
          ],
          FButton(
            onPress: coord == null
                ? null
                : () => _openDirections(context, location),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [
                const Icon(FLucideIcons.navigation, size: 16),
                Text('homeTab.location.directions'.tr()),
              ],
            ),
          ),
          // Sets expectations while we don't own venue data / booking yet.
          Row(
            spacing: 6,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(
                  FLucideIcons.info,
                  size: 13,
                  color: colors.mutedForeground,
                ),
              ),
              Expanded(
                child: Text(
                  'homeTab.location.roadmapNote'.tr(),
                  style: context.theme.typography.body.xs.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Directions handoff ─────────────────────────────────────────────────────

/// Hands off to whatever maps app the device has via a platform-appropriate
/// URI — Apple Maps on iOS, a `geo:` intent (native app chooser) on Android —
/// falling back to a Google Maps web URL. No API key or billing; the OS routes
/// the intent. No-op with a toast if the venue has no coordinates.
Future<void> _openDirections(BuildContext context, Location location) async {
  final coord = location.coord;
  if (coord == null) return;

  final lat = coord.latitude;
  final lon = coord.longitude;
  final label = Uri.encodeComponent(location.name);

  final nativeUri = defaultTargetPlatform == TargetPlatform.iOS
      // Apple Maps: `daddr` + current location gives turn-by-turn directions.
      ? Uri.parse('https://maps.apple.com/?daddr=$lat,$lon&q=$label')
      // Android: `geo:` opens the maps-app chooser dropping a labelled pin.
      : Uri.parse('geo:$lat,$lon?q=$lat,$lon($label)');
  final webUri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=$lat,$lon',
  );

  var launched = false;
  try {
    if (await canLaunchUrl(nativeUri)) {
      launched = await launchUrl(
        nativeUri,
        mode: LaunchMode.externalApplication,
      );
    }
    if (!launched) {
      launched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  } catch (_) {
    launched = false;
  }

  if (!launched && context.mounted) {
    showFToast(
      context: context,
      icon: const Icon(FLucideIcons.circleX),
      variant: .destructive,
      title: Text('homeTab.location.directionsFailed'.tr()),
      alignment: .bottomCenter,
    );
  }
}
