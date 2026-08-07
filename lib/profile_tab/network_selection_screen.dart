import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../core/model/enum.dart';
import '../core/model/network.dart';
import '../ui/search_field.dart';
import 'profile_controller.dart';

class NetworkSelectionScreen extends HookConsumerWidget {
  const NetworkSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final searchState = ref.watch(networkSearchControllerProvider);
    final selectedNetworks = ref.watch(networkControllerProvider);
    final networkController = ref.read(networkControllerProvider.notifier);

    return FScaffold(
      header: FHeader.nested(
        title: Text('profile.networkLabel'.tr()),
        prefixes: [
          FHeaderAction.back(onPress: () => Navigator.of(context).pop()),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          spacing: 4,
          children: [
            Column(
              spacing: 4,
              children: [
                PSearchField(
                  controller: searchController,
                  hint: 'profile.networkSearchHint'.tr(),
                  onChange: (value) => ref
                      .read(networkSearchControllerProvider.notifier)
                      .search(value),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Hack: ignore the first value in city (none)
                      for (final city in [City.hochiminh, City.hanoi])
                        GestureDetector(
                          onTap: () => ref
                              .read(networkSearchControllerProvider.notifier)
                              .toggleCity(city),
                          child: FBadge(
                            variant: searchState.cityFilters.contains(city)
                                ? .primary
                                : .outline,
                            child: Text(city.getLocalizedName(context)),
                          ),
                        ),
                      for (final category in NetworkCategory.values)
                        GestureDetector(
                          onTap: () => ref
                              .read(networkSearchControllerProvider.notifier)
                              .toggleCategory(category),
                          child: FBadge(
                            variant:
                                searchState.categoryFilters.contains(category)
                                ? .primary
                                : .outline,
                            child: Text(category.getLocalizedName(context)),
                          ),
                        ),
                    ],
                  ),
                ),
                if (searchState.isLoading)
                  const Center(child: FCircularProgress())
                else if (searchState.results.isNotEmpty)
                  FTileGroup.builder(
                    count: searchState.results.length,
                    maxHeight: 320,
                    tileBuilder: (context, index) {
                      final network = searchState.results[index];
                      final isSelected = selectedNetworks.any(
                        (n) => n.id == network.id,
                      );
                      return FTile(
                        title: Text(network.name),
                        suffix: isSelected
                            ? const Icon(FLucideIcons.check)
                            : null,
                        subtitle: network.city != null
                            ? Text(network.city!.getLocalizedName(context))
                            : null,
                        onPress: () {
                          final success = ref
                              .read(networkControllerProvider.notifier)
                              .toggle(network);
                          if (!success && context.mounted) {
                            showFToast(
                              context: context,
                              icon: const Icon(FLucideIcons.triangleAlert),
                              title: Text('profile.networkMaxReached'.tr()),
                              alignment: .bottomCenter,
                            );
                          }
                        },
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (selectedNetworks.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'profile.selectedNetworks'.tr(),
                          style: context.theme.typography.body.md.copyWith(
                            fontWeight: .bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  FTileGroup(
                    children: selectedNetworks.map((network) {
                      return FTile(
                        title: Text(network.name, maxLines: 2),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              FRadio(
                                value: !network.isAlumni,
                                label: Text('profile.currentMember'.tr()),
                                onChange: (_) => networkController.setAlumni(
                                  network.id,
                                  false,
                                ),
                              ),
                              FRadio(
                                value: network.isAlumni,
                                label: Text('profile.alumni'.tr()),
                                onChange: (_) => networkController.setAlumni(
                                  network.id,
                                  true,
                                ),
                              ),
                            ],
                          ),
                        ),
                        suffix: FButton.icon(
                          variant: .ghost,
                          onPress: () => networkController.remove(network.id),
                          child: Icon(
                            FLucideIcons.trash,
                            size: 16,
                            color: context.theme.colors.destructive,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              )
            else
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      FLucideIcons.network,
                      size: 64,
                      color: context.theme.colors.mutedForeground,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'profile.networkFeatureExplanation'.tr(),
                      style: context.theme.typography.body.sm.copyWith(
                        color: context.theme.colors.mutedForeground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
