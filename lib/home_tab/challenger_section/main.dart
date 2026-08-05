import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../core/format.dart';
import '../../core/model/lobby_feed_item.dart';
import '../../router.dart';
import '../../ui/main.dart';
import '../filter.dart';
import '../lobby_feed_card.dart';
import '../main.dart';
import 'feed_controller.dart';
import 'send_challenge_controller.dart';

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
                error: (_, _) => ListView(
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
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return LobbyFeedCard(
                            item: item,
                            action: _ChallengeButton(item: item),
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

/// The per-card "Thách đấu" CTA. Opens a confirmation sheet for the terms the
/// home lobby published, then sends the challenge from the user's effective
/// context lobby (the "challenging as" pick).
///
/// It deliberately does not collect a time or venue: the home team set those in
/// its offer and `send_challenge` snapshots them. All the challenger adds is an
/// optional note.
class _ChallengeButton extends ConsumerStatefulWidget {
  final LobbyFeedItem item;

  const _ChallengeButton({required this.item});

  @override
  ConsumerState<_ChallengeButton> createState() => _ChallengeButtonState();
}

class _ChallengeButtonState extends ConsumerState<_ChallengeButton> {
  bool _sent = false;

  Future<void> _open() async {
    final ctx = await ref.read(contextLobbyProvider.future);
    if (ctx == null || !mounted) return;

    final sent = await showPSheet<bool>(
      context: context,
      builder: (_) => _ConfirmChallengeSheet(
        item: widget.item,
        contextLobbyId: ctx.id,
        contextLobbyName: ctx.name,
      ),
    );
    if (sent == true && mounted) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    return FButton(
      size: .sm,
      variant: .secondary,
      onPress: _sent ? null : _open,
      child: Text(_sent
          ? 'homeTab.challenger.sent'.tr()
          : 'homeTab.challenger.challenge'.tr()),
    );
  }
}

/// "You're accepting these terms" — the challenger's half of the handshake.
class _ConfirmChallengeSheet extends ConsumerStatefulWidget {
  final LobbyFeedItem item;
  final String contextLobbyId;
  final String contextLobbyName;

  const _ConfirmChallengeSheet({
    required this.item,
    required this.contextLobbyId,
    required this.contextLobbyName,
  });

  @override
  ConsumerState<_ConfirmChallengeSheet> createState() =>
      _ConfirmChallengeSheetState();
}

class _ConfirmChallengeSheetState
    extends ConsumerState<_ConfirmChallengeSheet> {
  final _noteController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _busy = true);
    try {
      final note = _noteController.text.trim();
      await ref
          .read(sendChallengeControllerProvider(widget.contextLobbyId).notifier)
          .send(
            targetLobbyId: widget.item.id,
            note: note.isEmpty ? null : note,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.flag),
        title: Text('homeTab.challenger.sent'.tr()),
        alignment: .bottomCenter,
      );
    } catch (e, st) {
      Talker().handle(e, st, 'challenge failed');
      if (!mounted) return;
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleX),
        variant: .destructive,
        title: Text(challengeErrorMessage(e)),
        alignment: .bottomCenter,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final item = widget.item;

    Widget term(IconData icon, String label, String value) => Row(
          children: [
            Icon(icon, size: 16, color: colors.mutedForeground),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: context.theme.typography.body.sm
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: context.theme.typography.body.sm.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.secondaryForeground,
                ),
              ),
            ),
          ],
        );

    return SingleChildScrollView(
      primary: false,
      child: Column(
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PSheetTitle(
            label: 'homeTab.challenger.confirmTitle'.tr(),
            trailing: FButton.icon(
              variant: .ghost,
              onPress: () => Navigator.of(context).pop(),
              child: const Icon(FLucideIcons.x),
            ),
          ),

          Text(
            'homeTab.challenger.confirmBody'.tr(
              args: [widget.contextLobbyName, item.name],
            ),
            style: context.theme.typography.body.xs
                .copyWith(color: colors.mutedForeground, height: 1.45),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 10,
              children: [
                if (item.offerTime != null)
                  term(FLucideIcons.calendar, 'homeTab.challenger.kickoff'.tr(),
                      formatMatchDateTime(item.offerTime!)),
                if (item.offerLocationName != null)
                  term(FLucideIcons.mapPin, 'homeTab.challenger.venue'.tr(),
                      item.offerLocationName!),
                if (item.offerCost != null)
                  term(FLucideIcons.wallet, 'homeTab.challenger.cost'.tr(),
                      '${formatVnd(item.offerCost!)}đ'),
              ],
            ),
          ),

          Text(
            'homeTab.challenger.refNote'.tr(),
            style: context.theme.typography.body.xs
                .copyWith(color: colors.mutedForeground, height: 1.45),
          ),

          FTextField(
            label: Text('homeTab.challenger.note'.tr()),
            hint: 'homeTab.challenger.noteHint'.tr(),
            maxLines: 3,
            control: FTextFieldControl.managed(controller: _noteController),
          ),

          FButton(
            onPress: _busy ? null : _send,
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text('homeTab.challenger.confirmCta'.tr()),
          ),
          const SizedBox(height: 4),
        ],
      ),
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
      error: (_, _) => const SizedBox.shrink(),
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
                  onPress: () =>
                      ref.read(homeSubtabRequestProvider.notifier).state = 0,
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
