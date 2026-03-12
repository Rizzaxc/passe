import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../filter.dart';
import '../widget/empty_search.dart';
import 'feed_controller.dart';

class ChallengerSubtab extends ConsumerWidget {
  const ChallengerSubtab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(challengerFeedProvider);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'home.challenger'.tr(),
                style: context.theme.typography.xl2.copyWith(fontWeight: .bold),
              ),
            ),
            const FilterWidget(),
          ],
        ),
        Expanded(
          child: feed.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                e.toString(),
                style: context.theme.typography.sm.copyWith(
                  color: context.theme.colors.destructive,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            data: (items) => items.isEmpty
                ? const EmptySearch()
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) => ListTile(
                      title: Text(items[index].toString()),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
