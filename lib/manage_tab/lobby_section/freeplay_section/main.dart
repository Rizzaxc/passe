import 'package:easy_localization/easy_localization.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../freeplay/model.dart';
import '../../../freeplay/repository.dart';
import '../../../router.dart';
import '../../../ui/main.dart';

/// Manage ▸ Kèo lẻ: the player's own freeplay seat requests (pending and
/// accepted, upcoming). Its own rail tab — it used to be a capped strip
/// wedged above the lobby list. History is the header's clock button.
class PlayerFreeplaySubtab extends ConsumerWidget {
  const PlayerFreeplaySubtab({super.key});

  Future<void> _showHistory(BuildContext context) => showPSheet(
    context: context,
    maxHeightRatio: 1,
    builder: (_) => const _History(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(myFreeplayProvider(false));

    Widget scrollable(List<Widget> children) => ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: children,
    );

    return Column(
      children: [
        PSectionHeader(
          title: 'lobbyHub.freeplay.yourRequests'.tr(),
          suffix: FButton.icon(
            variant: .ghost,
            onPress: () => _showHistory(context),
            child: const Icon(FLucideIcons.history),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myFreeplayProvider(false));
              await ref.read(myFreeplayProvider(false).future);
            },
            child: sessions.when(
              loading: () => const Center(child: FCircularProgress()),
              error: (_, _) => scrollable([
                PEmptySectionPlaceholder(
                  subtitle: 'lobbyHub.freeplay.loadFailed'.tr(),
                  actions: [
                    FButton(
                      size: .sm,
                      variant: .outline,
                      prefix: const Icon(FLucideIcons.rotateCw),
                      onPress: () => ref.invalidate(myFreeplayProvider(false)),
                      child: Text('homeTab.loadError.retry'.tr()),
                    ),
                  ],
                ),
              ]),
              data: (items) => items.isEmpty
                  ? scrollable([
                      PEmptySectionPlaceholder(
                        hero: Icon(
                          FLucideIcons.ticket,
                          size: 64,
                          color: context.theme.colors.mutedForeground,
                        ),
                        subtitle: 'lobbyHub.freeplay.empty'.tr(),
                        actions: [
                          FButton(
                            size: .sm,
                            prefix: const Icon(FLucideIcons.search),
                            onPress: () =>
                                const DiscoverFreeplayRoute().go(context),
                            child: Text('lobbyHub.freeplay.find'.tr()),
                          ),
                        ],
                      ),
                    ])
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(top: 4, bottom: 24),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (context, index) =>
                          _SessionTile(activity: items[index]),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SessionTile extends StatelessWidget {
  final FreeplayActivity activity;
  const _SessionTile({required this.activity});
  @override
  Widget build(BuildContext context) => FTile(
    prefix: Icon(
      activity.myRequestStatus == FreeplayRequestStatus.accepted
          ? FLucideIcons.ticketCheck
          : FLucideIcons.clock3,
    ),
    title: Text(
      activity.hostName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    subtitle: Text(
      '${DateFormat('EEE d/M, HH:mm', context.locale.toLanguageTag()).format(activity.startTime)} · ${activity.venueName}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    suffix: const Icon(FLucideIcons.chevronRight),
    onPress: () => FreeplayDetailRoute(id: activity.id).push(context),
  );
}

class _History extends ConsumerWidget {
  const _History();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(myFreeplayProvider(true));
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .76,
      child: Column(
        children: [
          PSheetTitle(
            label: 'lobbyHub.freeplay.history'.tr(),
            trailing: FButton.icon(
              variant: .ghost,
              onPress: () => Navigator.pop(context),
              child: const Icon(FLucideIcons.x),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: history.when(
              loading: () => const Center(child: FCircularProgress()),
              error: (_, _) =>
                  Center(child: Text('lobbyHub.freeplay.loadFailed'.tr())),
              data: (items) => items.isEmpty
                  ? Center(child: Text('lobbyHub.freeplay.noHistory'.tr()))
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (context, index) =>
                          _SessionTile(activity: items[index]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
