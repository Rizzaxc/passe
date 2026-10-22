import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../auth/guest_prompt.dart';
import '../../core/model/lobby_feed_item.dart';
import '../../logger/talker.dart';
import '../../manage_tab/lobby_section/feed/lobby_form_sheet.dart';
import '../../ui/main.dart';
import '../filter.dart';
import '../lobby_feed_card.dart';
import '../lobby_join_button.dart';
import 'feed_controller.dart';

/// Guards [TeammateSubtab]'s auto-open-filter effect so it only ever fires
/// once per app process — `discover_tab/main.dart` only builds the active
/// subtab, so this widget is torn down and remounted every time the user leaves and returns to
/// this subtab, and `widget.openFilter` stays `true` for the whole life of
/// the `DiscoverTab` instance it came from, so without this latch switching
/// tabs away and back would reopen the sheet every time.
bool _autoFilterConsumed = false;

class TeammateSubtab extends HookConsumerWidget {
  /// Auto-opens the shared filter sheet once, right after this subtab lays
  /// out — set when arriving via the onboarding Get Started sheet's "Tìm
  /// đồng đội" tile, so a new user sets real search criteria instead of
  /// landing on whatever the default (profile-seeded) filter returns.
  final bool openFilter;

  const TeammateSubtab({super.key, this.openFilter = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(teammateFeedProvider);

    useEffect(() {
      if (openFilter && !_autoFilterConsumed) {
        _autoFilterConsumed = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            showPSheet(context: context, builder: (_) => const FilterSheet());
          }
        });
      }
      return null;
    }, const []);

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(teammateFeedProvider);
              await ref.read(teammateFeedProvider.future);
            },
            child: feed.when(
              loading: () => const Center(child: FCircularProgress()),
              // Distinct from "no results": a failed load used to look exactly
              // like an empty city, with nothing to try.
              error: (e, st) {
                talker.handle(e, st, 'teammate feed failed');
                return _error(context, ref);
              },
              data: (items) => items.isEmpty
                  ? _empty(context, ref)
                  : _LobbyList(items: items),
            ),
          ),
        ),
      ],
    );
  }

  Widget _empty(BuildContext context, WidgetRef ref) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [
      PEmptySectionPlaceholder(
        hero: Icon(
          FLucideIcons.searchX,
          size: 64,
          color: context.theme.colors.mutedForeground,
        ),
        title: 'homeTab.teammate.emptyTitle'.tr(),
        subtitle: 'homeTab.teammate.emptyMessage'.tr(),
        actions: [
          FButton(
            size: .sm,
            variant: .outline,
            prefix: const Icon(FLucideIcons.slidersHorizontal),
            onPress: () => showFilterSheet(context),
            child: Text('homeTab.teammate.adjustFilter'.tr()),
          ),
          FButton(
            size: .sm,
            prefix: const Icon(FLucideIcons.plus),
            onPress: () async {
              if (!ensureSignedIn(context, ref)) return;
              await createLobbyAndOpen(context, ref);
            },
            child: Text('homeTab.teammate.createLobby'.tr()),
          ),
        ],
      ),
    ],
  );

  Widget _error(BuildContext context, WidgetRef ref) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [
      PEmptySectionPlaceholder(
        hero: Icon(
          FLucideIcons.wifiOff,
          size: 64,
          color: context.theme.colors.mutedForeground,
        ),
        title: 'homeTab.loadError.title'.tr(),
        subtitle: 'homeTab.loadError.message'.tr(),
        actions: [
          FButton(
            size: .sm,
            variant: .outline,
            prefix: const Icon(FLucideIcons.rotateCw),
            onPress: () => ref.invalidate(teammateFeedProvider),
            child: Text('homeTab.loadError.retry'.tr()),
          ),
        ],
      ),
    ],
  );
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
          joinFromPreview: true,
          action: LobbyJoinButton(
            lobbyId: item.id,
            alreadyRequested: item.alreadyRequested,
          ),
        );
      },
    );
  }
}
