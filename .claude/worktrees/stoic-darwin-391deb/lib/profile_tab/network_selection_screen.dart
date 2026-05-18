import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import '../core/model/enum.dart';
import '../core/model/network.dart';
import '../ui/search_field.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'profile_controller.dart';

class NetworkSelectionScreen extends HookConsumerWidget {
  const NetworkSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final searchState = ref.watch(networkSearchControllerProvider);
    final selectedNetworks = ref.watch(networkControllerProvider);
    final isRemovalMode = useState(false);
    final markedForRemoval = useState(<int>{});

    return FScaffold(
      header: FHeader(
        title: Text('profile.networkLabel'.tr()),
        suffixes: [
          FHeaderAction.back(onPress: () => Navigator.of(context).pop()),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          spacing: 4,
          children: [
            IgnorePointer(
              ignoring: isRemovalMode.value,
              child: AnimatedOpacity(
                opacity: isRemovalMode.value ? 0.3 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Column(
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
                                variant: searchState.categoryFilters.contains(category)
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
                            suffix: isSelected ? const Icon(FIcons.check) : null,
                            subtitle: network.city != null ? Text(network.city!.getLocalizedName(context)) : null,
                            onPress: () {
                              final success = ref
                                  .read(networkControllerProvider.notifier)
                                  .toggle(network);
                              if (!success && context.mounted) {
                                showFToast(
                                  context: context,
                                  icon: const Icon(FIcons.triangleAlert),
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
              ),
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
                          style: context.theme.typography.md.copyWith(
                            fontWeight: .bold
                          ),
                        ),
                      ),
                      FButton.icon(
                        variant: isRemovalMode.value ? .destructive : .ghost,
                        onPress: () {
                          if (isRemovalMode.value) {
                            for (final id in markedForRemoval.value) {
                              final network = selectedNetworks.firstWhere((n) => n.id == id);
                              ref.read(networkControllerProvider.notifier).toggle(network);
                            }
                            markedForRemoval.value = {};
                          }
                          isRemovalMode.value = !isRemovalMode.value;
                        },
                        child: Icon(FIcons.trash, size: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  FTileGroup(
                    children: selectedNetworks
                        .map(
                          (network) {
                            final isMarked = markedForRemoval.value.contains(network.id);
                            return FTile(
                              title: Text(
                                network.name,
                                maxLines: 2,
                                style: isMarked
                                    ? TextStyle(
                                        decoration: TextDecoration.lineThrough,
                                        color: context.theme.colors.mutedForeground,
                                      )
                                    : null,
                              ),
                              suffix: FBadge(
                                variant: network.isAlumni ? .outline : .primary,
                                child: Text(
                                  network.isAlumni
                                      ? 'profile.alumni'.tr()
                                      : 'profile.currentMember'.tr(),
                                ),
                              ),
                              onPress: () {
                                if (isRemovalMode.value) {
                                  final updated = {...markedForRemoval.value};
                                  if (!updated.remove(network.id)) {
                                    updated.add(network.id);
                                  }
                                  markedForRemoval.value = updated;
                                } else {
                                  ref
                                      .read(networkControllerProvider.notifier)
                                      .toggleAlumni(network.id);
                                }
                              },
                            );
                          },
                        )
                        .toList(),
                  ),
                ],
              )
            else
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      FIcons.network,
                      size: 64,
                      color: context.theme.colors.mutedForeground,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'profile.networkFeatureExplanation'.tr(),
                      style: context.theme.typography.sm.copyWith(
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
