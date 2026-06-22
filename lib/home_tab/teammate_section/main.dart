import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../core/model/lobby_feed_item.dart';
import '../../notifications/notification_service.dart';
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
              FLucideIcons.searchX,
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
  final bool alreadyRequested;

  const _JoinButton({required this.lobbyId, required this.alreadyRequested});

  void _onError(BuildContext context, Object e, StackTrace st, String log) {
    Talker().handle(e, st, log);
    showFToast(
      context: context,
      icon: const Icon(FLucideIcons.circleX),
      variant: .destructive,
      title: Text('error'.tr()),
      description: Text('errorGeneric'.tr()),
      alignment: .bottomCenter,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requested = ref.watch(
      joinRequestStateProvider.select((m) => m[lobbyId] ?? alreadyRequested),
    );

    // Once requested, the CTA becomes a "sent" indicator plus an undo button
    // that cancels the pending join request.
    if (requested) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Text(
            'homeTab.teammate.sent'.tr(),
            style: context.theme.typography.body.sm.copyWith(
              color: context.theme.colors.mutedForeground,
              fontWeight: FontWeight.w500,
            ),
          ),
          FButton(
            size: .sm,
            variant: .outline,
            prefix: const Icon(FLucideIcons.undo2),
            onPress: () async {
              try {
                await ref
                    .read(joinRequestStateProvider.notifier)
                    .unrequest(lobbyId);
              } catch (e, st) {
                if (context.mounted) {
                  _onError(context, e, st, 'Lobby join cancel failed');
                }
              }
            },
            child: Text('homeTab.teammate.undo'.tr()),
          ),
        ],
      );
    }

    return FButton(
      size: .sm,
      variant: .primary,
      onPress: () async {
        try {
          await ref.read(joinRequestStateProvider.notifier).request(lobbyId);
          // First meaningful action → soft-ask for push permission (no-op if
          // already decided / guest). See lib/notifications/.
          if (context.mounted) {
            await ref
                .read(notificationServiceProvider)
                .maybePromptAndRegister(context, ref);
          }
        } catch (e, st) {
          if (context.mounted) {
            _onError(context, e, st, 'Lobby join request failed');
          }
        }
      },
      child: Text('homeTab.teammate.join'.tr()),
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
          action: _JoinButton(
            lobbyId: item.id,
            alreadyRequested: item.alreadyRequested,
          ),
        );
      },
    );
  }
}
