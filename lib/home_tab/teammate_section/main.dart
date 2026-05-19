import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/model/lobby.dart';
import '../../core/model/lobby_feed_item.dart';
import '../../core/model/timeslot.dart';
import '../../core/model/enum.dart';
import '../../ui/main.dart';
import '../filter.dart';
import '../lobby_feed_card.dart';
import 'feed_controller.dart';

// ─── Mock lobby data (for visual preview while API is wired up) ───────────────
final _kMockLobbies = [
  LobbyFeedItem(
    id: 'mock-1',
    name: 'CLB Cầu Lông Bách Khoa',
    homegroundName: 'NTĐ Bách Khoa, Hai Bà Trưng',
    playtime: [
      Timeslot(DayOfWeek.monday, DayChunk.night),
      Timeslot(DayOfWeek.wednesday, DayChunk.night),
      Timeslot(DayOfWeek.friday, DayChunk.night),
    ],
    visibility: LobbyVisibility.public,
    timeslotCompatScore: 3,
    profileCompatScore: 4.6,
    memberCount: 6,
  ),
  LobbyFeedItem(
    id: 'mock-2',
    name: 'Smash Squad Cầu Giấy',
    homegroundName: 'Vincom Bà Triệu, Hai Bà Trưng',
    playtime: [
      Timeslot(DayOfWeek.tuesday, DayChunk.noon),
      Timeslot(DayOfWeek.thursday, DayChunk.noon),
    ],
    visibility: LobbyVisibility.discoverable,
    timeslotCompatScore: 2,
    profileCompatScore: 3.8,
    memberCount: 4,
  ),
  LobbyFeedItem(
    id: 'mock-3',
    name: 'Hội cầu lông ARTRO',
    homegroundName: 'Sân Mỹ Đình, Nam Từ Liêm',
    playtime: [
      Timeslot(DayOfWeek.saturday, DayChunk.early),
      Timeslot(DayOfWeek.sunday, DayChunk.early),
    ],
    visibility: LobbyVisibility.discoverable,
    timeslotCompatScore: 1,
    profileCompatScore: 2.4,
    memberCount: 8,
  ),
  LobbyFeedItem(
    id: 'mock-4',
    name: 'Lobby số #BD-2087',
    homegroundName: 'Sân Khúc Thừa Dụ, Cầu Giấy',
    playtime: [
      Timeslot(DayOfWeek.thursday, DayChunk.night),
    ],
    visibility: LobbyVisibility.discoverable,
    timeslotCompatScore: 1,
    profileCompatScore: 1.2,
    memberCount: 3,
  ),
];

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
              loading: () => _LobbyList(items: _kMockLobbies, isMock: true),
              error: (_, __) => _LobbyList(items: _kMockLobbies, isMock: true),
              data: (items) => _LobbyList(
                items: items.isEmpty ? _kMockLobbies : items,
                isMock: items.isEmpty,
              ),
            ),
          ),
        ),
      ],
    );
  }
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

// ─── List widget shared for real + mock data ──────────────────────────────────

class _LobbyList extends ConsumerWidget {
  final List<LobbyFeedItem> items;
  final bool isMock;

  const _LobbyList({required this.items, required this.isMock});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return LobbyFeedCard(
          item: item,
          action: isMock
              ? FButton(
                  size: .sm,
                  variant: .primary,
                  onPress: null,
                  child: Text('homeTab.teammate.join'.tr()),
                )
              : _JoinButton(lobbyId: item.id),
        );
      },
    );
  }
}
