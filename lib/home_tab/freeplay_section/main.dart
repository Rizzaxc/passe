import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../freeplay/card.dart';
import '../../freeplay/repository.dart';
import '../../ui/main.dart';
import '../filter.dart';

class FreeplaySubtab extends ConsumerWidget {
  const FreeplaySubtab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(freeplayFeedProvider);
    return Column(
      children: [
        const PSectionHeader(title: 'Xé vé', suffix: FilterWidget()),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(freeplayFeedProvider);
              await ref.read(freeplayFeedProvider.future);
            },
            child: feed.when(
              loading: () => const Center(child: FCircularProgress()),
              error: (_, _) => const _Empty(),
              data: (items) => items.isEmpty
                  ? const _Empty()
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) =>
                          FreeplayCard(activity: items[index]),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [
      PEmptySectionPlaceholder(
        hero: Icon(
          FLucideIcons.ticketX,
          size: 64,
          color: context.theme.colors.mutedForeground,
        ),
        title: 'Chưa có vé phù hợp',
        subtitle: 'Thử đổi khung giờ hoặc khu vực để xem thêm buổi chơi.',
      ),
    ],
  );
}
