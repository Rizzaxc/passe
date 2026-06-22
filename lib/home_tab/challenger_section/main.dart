import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../ui/main.dart';
import '../filter.dart';
import '../lobby_feed_card.dart';
import 'feed_controller.dart';

class ChallengerSubtab extends ConsumerWidget {
  const ChallengerSubtab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(challengerFeedProvider);

    return Column(
      children: [
        PSectionHeader(
          title: 'home.challenger'.tr(),
          suffix: const FilterWidget(),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(challengerFeedProvider);
              await ref.read(challengerFeedProvider.future);
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
                            FLucideIcons.searchX,
                            size: 64,
                            color: context.theme.colors.mutedForeground,
                          ),
                          title: 'homeTab.empty.title'.tr(),
                          subtitle: 'homeTab.empty.message'.tr(),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return LobbyFeedCard(
                          item: item,
                          action: FButton(
                            size: .sm,
                            variant: .secondary,
                            onPress: null, // TODO: challenge flow pending lobby_challenge table
                            child: Text('homeTab.challenger.challenge'.tr()),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
