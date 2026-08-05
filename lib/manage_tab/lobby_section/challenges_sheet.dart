import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../core/format.dart';
import '../../ui/sheet.dart';
import 'challenges_controller.dart';

void showChallengesSheet(BuildContext context, String lobbyId) {
  showPSheet(
    context: context,
    builder: (_) => _ChallengesSheet(lobbyId: lobbyId),
  );
}

class _ChallengesSheet extends ConsumerWidget {
  final String lobbyId;
  const _ChallengesSheet({required this.lobbyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(lobbyChallengesControllerProvider(lobbyId));
    final colors = context.theme.colors;

    return SingleChildScrollView(
      primary: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          PSheetTitle(
            label: 'lobby.challenges.title'.tr(),
            trailing: FButton.icon(
              variant: .ghost,
              onPress: () => Navigator.of(context).pop(),
              child: const Icon(FLucideIcons.x),
            ),
          ),
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('errorGeneric'.tr(),
                  style: TextStyle(color: colors.destructive)),
            ),
            data: (list) {
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text('lobby.challenges.empty'.tr(),
                        style: context.theme.typography.body.sm
                            .copyWith(color: colors.mutedForeground)),
                  ),
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  for (final c in list) _ChallengeRow(lobbyId: lobbyId, item: c),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// One agreed term. The value is a venue name or formatted money — unbounded,
/// so it ellipsizes rather than overflowing the sheet on a narrow phone.
class _TermLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TermLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Row(
      children: [
        Icon(icon, size: 13, color: colors.mutedForeground),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.theme.typography.body.xs
                .copyWith(color: colors.secondaryForeground),
          ),
        ),
      ],
    );
  }
}

class _ChallengeRow extends ConsumerStatefulWidget {
  final String lobbyId;
  final LobbyChallenge item;

  const _ChallengeRow({required this.lobbyId, required this.item});

  @override
  ConsumerState<_ChallengeRow> createState() => _ChallengeRowState();
}

class _ChallengeRowState extends ConsumerState<_ChallengeRow> {
  bool _busy = false;

  Future<void> _act(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e, st) {
      Talker().handle(e, st, 'challenge response failed');
      if (!mounted) return;
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleX),
        variant: .destructive,
        title: Text('errorGeneric'.tr()),
        alignment: .bottomCenter,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final c = widget.item;
    final notifier =
        ref.read(lobbyChallengesControllerProvider(widget.lobbyId).notifier);

    // Anything past 'requested' is a match in motion — the accept/decline pair
    // is replaced by its state.
    final accepted = !c.isOpen;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Row(
            children: [
              Icon(c.isIncoming ? FLucideIcons.swords : FLucideIcons.send,
                  size: 15, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  c.otherLobbyName,
                  style: context.theme.typography.body.sm
                      .copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (c.otherLobbyMmr != null)
                Text('${c.otherLobbyMmr} MMR',
                    style: context.theme.typography.body.xs
                        .copyWith(color: colors.mutedForeground)),
            ],
          ),
          // The agreed terms, snapshotted when the challenge was sent — not a
          // live read of the home lobby's current offer.
          if (c.proposedTime != null)
            _TermLine(
              icon: FLucideIcons.calendar,
              text: formatMatchDateTime(c.proposedTime!),
            ),
          if (c.proposedLocationName != null)
            _TermLine(
              icon: FLucideIcons.mapPin,
              text: c.proposedLocationName!,
            ),
          if (c.agreedCost != null)
            _TermLine(
              icon: FLucideIcons.wallet,
              text: '${formatVnd(c.agreedCost!)}đ/đội',
            ),
          if (accepted)
            _TermLine(
              icon: FLucideIcons.userCheck,
              text: c.refereeBooked
                  ? 'Đã có trọng tài — trận sẽ được tính điểm'
                  : 'Chưa có trọng tài — trận sẽ không tính điểm',
            ),
          if (c.note != null && c.note!.isNotEmpty)
            Text(c.note!,
                style: context.theme.typography.body.xs
                    .copyWith(color: colors.mutedForeground)),
          Row(
            children: [
              Expanded(
                child: Text(
                  c.isScheduled
                      ? 'lobby.challenges.scheduled'.tr()
                      : accepted
                          ? 'lobby.challenges.accepted'.tr()
                          : c.isIncoming
                              ? 'lobby.challenges.incoming'.tr()
                              : 'lobby.challenges.outgoing'.tr(),
                  style: context.theme.typography.body.xs.copyWith(
                    color: accepted ? colors.primary : colors.mutedForeground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_busy)
                const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
              else if (!accepted && c.isIncoming) ...[
                FButton(
                  size: .sm,
                  variant: .ghost,
                  onPress: () => _act(() => notifier.respond(c.id, 'decline')),
                  child: Text('lobby.challenges.decline'.tr()),
                ),
                const SizedBox(width: 6),
                FButton(
                  size: .sm,
                  variant: .secondary,
                  onPress: () => _act(() => notifier.respond(c.id, 'accept')),
                  child: Text('lobby.challenges.accept'.tr()),
                ),
              ] else if (!accepted && !c.isIncoming)
                FButton(
                  size: .sm,
                  variant: .ghost,
                  onPress: () => _act(() => notifier.cancel(c.id)),
                  child: Text('lobby.challenges.cancelBtn'.tr()),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
