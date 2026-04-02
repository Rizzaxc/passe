import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../ui/main.dart';
import '../filter.dart';
import 'feed_controller.dart';

class ProfessionalSubtab extends ConsumerWidget {
  const ProfessionalSubtab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(professionalFeedProvider);

    return Column(
      children: [
        PSectionHeader(
          title: 'home.professional'.tr(),
          suffix: const FilterWidget(),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(professionalFeedProvider);
              await ref.read(professionalFeedProvider.future);
            },
            child: feed.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Center(
                    child: Text(
                      e.toString(),
                      style: context.theme.typography.sm.copyWith(
                        color: context.theme.colors.destructive,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              data: (items) => items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        PEmptySectionPlaceholder(
                          hero: Icon(FIcons.searchX, size: 64, color: context.theme.colors.mutedForeground),
                          title: 'homeTab.empty.title'.tr(),
                          subtitle: 'homeTab.empty.message'.tr(),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: items.length,
                      itemBuilder: (context, index) => ListTile(
                        title: Text(items[index].toString()),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
