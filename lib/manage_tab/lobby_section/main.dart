import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/model/lobby.dart';
import '../../router.dart';
import 'lobby_controller.dart';
import 'lobby_form_sheet.dart';

class LobbySubtab extends ConsumerWidget {
  const LobbySubtab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lobbiesAsync = ref.watch(userLobbiesControllerProvider);

    return lobbiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('errorGeneric'.tr())),
      data: (lobbies) => _buildContent(context, ref, lobbies),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, List<Lobby> lobbies) {
    if (lobbies.isEmpty) {
      return _EmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lobbies.length + 1,
      itemBuilder: (context, index) {
        if (index == lobbies.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: FButton(
              variant: .outline,
              prefix: const Icon(FIcons.plus),
              onPress: () async {
                final lobby = await showLobbyFormSheet(
                  context: context,
                  ref: ref,
                  lobbyId: null,
                );
                if (lobby?.id != null && context.mounted) {
                  LobbyDetailRoute(id: lobby!.id!, $extra: lobby.name).go(context);
                }
              },
              child: Text('lobby.create'.tr()),
            ),
          );
        }

        final lobby = lobbies[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _LobbyCard(lobby: lobby),
        );
      },
    );
  }
}

class _EmptyState extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FIcons.users,
              size: 64,
              color: context.theme.colors.mutedForeground,
            ),
            const SizedBox(height: 16),
            Text(
              'lobby.emptyTitle'.tr(),
              style: context.theme.typography.xl.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'lobby.emptyMessage'.tr(),
              style: context.theme.typography.base.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FButton(
              prefix: const Icon(FIcons.plus),
              onPress: () async {
                final lobby = await showLobbyFormSheet(
                  context: context,
                  ref: ref,
                  lobbyId: null,
                );
                if (lobby?.id != null && context.mounted) {
                  LobbyDetailRoute(id: lobby!.id!, $extra: lobby.name).go(context);
                }
              },
              child: Text('lobby.create'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

class _LobbyCard extends ConsumerWidget {
  final Lobby lobby;

  const _LobbyCard({required this.lobby});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FCard(
      child: FTappable(
        onPress: () => showLobbyFormSheet(
          context: context,
          ref: ref,
          lobbyId: lobby.id,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              lobby.sport.getIcon(size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lobby.name,
                      style: context.theme.typography.base.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lobby.sport.getLocalizedName(context),
                      style: context.theme.typography.sm.copyWith(
                        color: context.theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                FIcons.chevronRight,
                color: context.theme.colors.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }

}
