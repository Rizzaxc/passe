import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../freeplay/card.dart';
import '../../freeplay/repository.dart';
import '../../ui/main.dart';
import 'create_sheet.dart';
import 'manage_sheet.dart';
import 'requests_sheet.dart';

class HostFreeplaySection extends ConsumerWidget {
  const HostFreeplaySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = ref.watch(hostFreeplayProvider(false));
    return Column(
      children: [
        PSectionHeader(
          title: 'freeplay.hostManage.openListings'.tr(),
          suffix: FButton.icon(
            variant: .ghost,
            onPress: () => showCreateFreeplaySheet(context, ref),
            child: const Icon(FLucideIcons.plus),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(hostFreeplayProvider(false));
              await ref.read(hostFreeplayProvider(false).future);
            },
            child: activities.when(
              loading: () => const Center(child: FCircularProgress()),
              error: (_, _) => Center(
                child: Text('freeplay.hostManage.scheduleLoadFailed'.tr()),
              ),
              data: (items) {
                final sorted = [...items]
                  ..sort((a, b) => a.startTime.compareTo(b.startTime));
                if (sorted.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      PEmptySectionPlaceholder(
                        title: 'freeplay.hostManage.emptyTitle'.tr(),
                        subtitle: 'freeplay.hostManage.emptySubtitle'.tr(),
                      ),
                    ],
                  );
                }
                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: sorted.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => GestureDetector(
                    onLongPress: () =>
                        showManageFreeplaySheet(context, sorted[index]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FreeplayCard(activity: sorted[index], compact: true),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              FButton.icon(
                                size: .sm,
                                variant: .ghost,
                                onPress: () => showManageFreeplaySheet(
                                  context,
                                  sorted[index],
                                ),
                                child: const Icon(FLucideIcons.settings2),
                              ),
                              const SizedBox(width: 4),
                              FButton(
                                size: .sm,
                                variant: .outline,
                                onPress: () => showHostFreeplayRequests(
                                  context,
                                  sorted[index].id,
                                ),
                                child: Text(
                                  'freeplay.hostManage.pendingRequests'.tr(
                                    namedArgs: {
                                      'count': '${sorted[index].pendingCount}',
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
