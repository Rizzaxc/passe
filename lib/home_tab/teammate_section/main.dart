import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/model/lobby_feed_item.dart';
import '../../ui/main.dart';
import '../filter.dart';
import '../lobby_feed_card.dart';
import 'feed_controller.dart';

class TeammateSubtab extends ConsumerWidget {
  const TeammateSubtab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(teammateFeedProvider);

    return Column(
      children: [
        PSectionHeader(
          title: 'home.teammate'.tr(),
          suffix: const FilterWidget(),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(teammateFeedProvider);
              await ref.read(teammateFeedProvider.future);
            },
            child: feed.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => _empty(context),
              data: (items) =>
                  items.isEmpty ? _empty(context) : _LobbyList(items: items),
            ),
          ),
        ),
      ],
    );
  }

  Widget _empty(BuildContext context) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          PEmptySectionPlaceholder(
            hero: Icon(
              FIcons.searchX,
              size: 64,
              color: context.theme.colors.mutedForeground,
            ),
            title: 'homeTab.empty.title'.tr(),
            subtitle: 'homeTab.empty.message'.tr(),
          ),
        ],
      );
}

class _JoinButton extends ConsumerWidget {
  final String lobbyId;

  const _JoinButton({required this.lobbyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requested = ref.watch(requestedLobbyIdsProvider).contains(lobbyId);

    return FButton(
      size: .sm,
      variant: requested ? .secondary : .primary,
      onPress: requested
          ? null
          : () async {
              try {
                await ref
                    .read(requestedLobbyIdsProvider.notifier)
                    .request(lobbyId);
              } catch (_) {
                if (!context.mounted) return;
                showFToast(
                  context: context,
                  icon: const Icon(FIcons.circleX),
                  variant: .destructive,
                  title: Text('error'.tr()),
                  description: Text('errorGeneric'.tr()),
                  alignment: .bottomCenter,
                );
              }
            },
      child: Text(
        requested
            ? 'homeTab.teammate.sent'.tr()
            : 'homeTab.teammate.join'.tr(),
      ),
    );
  }
}

class _LobbyList extends ConsumerWidget {
  final List<LobbyFeedItem> items;

  const _LobbyList({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return LobbyFeedCard(
          item: item,
          action: _JoinButton(lobbyId: item.id),
        );
      },
    );
  }
}
