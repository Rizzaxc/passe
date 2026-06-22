import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/model/location.dart';
import '../../ui/main.dart';
import '../filter.dart';
import 'feed_controller.dart';

class LocationSubtab extends ConsumerWidget {
  const LocationSubtab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(locationFeedProvider);

    return Column(
      children: [
        PSectionHeader(
          title: 'home.location'.tr(),
          suffix: const FilterWidget(),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(locationFeedProvider);
              await ref.read(locationFeedProvider.future);
            },
            child: feed.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  PEmptySectionPlaceholder(
                    hero: Icon(
                      FLucideIcons.searchX,
                      size: 64,
                      color: context.theme.colors.mutedForeground,
                    ),
                    title: 'homeTab.empty.title'.tr(),
                    subtitle: 'homeTab.empty.message'.tr(),
                  ),
                ],
              ),
              data: (items) => items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        PEmptySectionPlaceholder(
                          hero: Icon(
                            FLucideIcons.mapPin,
                            size: 64,
                            color: context.theme.colors.mutedForeground,
                          ),
                          title: 'homeTab.location.empty.title'.tr(),
                          subtitle: 'homeTab.location.empty.message'.tr(),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) =>
                          _LocationCard(location: items[index]),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LocationCard extends StatelessWidget {
  final Location location;

  const _LocationCard({required this.location});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final address = location.fullAddress ??
        [
          if (location.streetNumber != null) location.streetNumber,
          if (location.streetName != null) location.streetName,
          if (location.district != null) location.district,
          if (location.city != null) location.city,
        ].whereType<String>().join(', ');

    return FCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 6,
        children: [
          Text(
            location.name,
            style: context.theme.typography.body.sm.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.primary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (address.isNotEmpty)
            Row(
              spacing: 4,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(FLucideIcons.mapPin, size: 12, color: colors.mutedForeground),
                ),
                Expanded(
                  child: Text(
                    address,
                    style: context.theme.typography.body.sm
                        .copyWith(color: colors.mutedForeground),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          FDivider(),
          Align(
            alignment: Alignment.centerRight,
            child: FButton(
              size: .sm,
              variant: .secondary,
              onPress: null, // TODO: open in maps when lat/lon available
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 4,
                children: [
                  const Icon(Icons.map_outlined, size: 14),
                  Text('homeTab.location.viewMap'.tr()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
