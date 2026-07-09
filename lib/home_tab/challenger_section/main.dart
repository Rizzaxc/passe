import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../router.dart';
import '../../ui/main.dart';
import '../filter.dart';
import '../lobby_feed_card.dart';
import 'feed_controller.dart';

class ChallengerSubtab extends ConsumerWidget {
  const ChallengerSubtab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contextOptions = ref.watch(contextLobbyOptionsProvider);
    final hasNoLobby = contextOptions.value?.isEmpty ?? false;
    final feed = ref.watch(challengerFeedProvider);

    return Column(
      children: [
        PSectionHeader(
          title: 'home.challenger'.tr(),
          suffix: const FilterWidget(),
        ),
        if (!hasNoLobby) const _ContextLobbyPicker(),
        if (hasNoLobby)
          const Expanded(child: _NoLobbyState())
        else
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
                              onPress:
                                  null, // TODO: challenge flow pending lobby_challenge table
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

/// "Challenging as" dropdown under the section title — lets the user pick
/// which of their lobbies (for the current sport) they're challenging as.
class _ContextLobbyPicker extends ConsumerWidget {
  const _ContextLobbyPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final optionsAsync = ref.watch(contextLobbyOptionsProvider);

    return optionsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (options) {
        if (options.isEmpty) return const SizedBox.shrink();

        final selectedId = ref.watch(contextLobbySelectionProvider);
        final selected = options.firstWhere(
          (o) => o.id == selectedId,
          orElse: () => options.first,
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: FSelect<String>.rich(
            format: (id) => options
                .firstWhere((o) => o.id == id, orElse: () => selected)
                .name,
            autoHide: true,
            prefixBuilder: (context, style, states) => Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 0, 4),
              child: const Icon(FLucideIcons.shield),
            ),
            control: FSelectControl.lifted(
              value: selected.id,
              onChange: (id) {
                if (id != null) {
                  ref.read(contextLobbySelectionProvider.notifier).select(id);
                }
              },
            ),
            children: [
              FSelectSection<String>.rich(
                label: Text('homeTab.challenger.challengingAs'.tr()),
                children: [
                  for (final o in options)
                    FSelectItem<String>(title: Text(o.name), value: o.id),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Shown instead of the feed when the user has no lobby for the current
/// sport — challenges are lobby-vs-lobby, so there's nothing this tab can
/// do for them until they create or join one.
class _NoLobbyState extends ConsumerWidget {
  const _NoLobbyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(contextLobbyOptionsProvider);
        await ref.read(contextLobbyOptionsProvider.future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 4),
        children: [
          PEmptySectionPlaceholder(
            hero: Icon(
              FLucideIcons.shieldOff,
              size: 64,
              color: context.theme.colors.mutedForeground,
            ),
            title: 'homeTab.challenger.noLobby.title'.tr(),
            subtitle: 'homeTab.challenger.noLobby.message'.tr(),
          ),
          const SizedBox(height: 16),
          Row(
            spacing: 12,
            children: [
              Expanded(
                child: FButton(
                  style: FButtonStyleExtension.accentBlueStyle(
                    context.theme.buttonStyles.primary.base,
                  ),
                  onPress: () => HomeTeammateRoute().go(context),
                  child: Text('homeTab.challenger.noLobby.findLobby'.tr()),
                ),
              ),
              Expanded(
                child: FButton(
                  onPress: () => ManageLobbyRoute().go(context),
                  child: Text('homeTab.challenger.noLobby.createLobby'.tr()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
