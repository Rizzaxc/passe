import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/format.dart';
import '../../../discover_tab/lobby_public_preview_sheet.dart';
import '../../../logger/talker.dart';
import '../../../ui/main.dart';
import 'challenger_chooser_controller.dart';

/// Home's answer to the friendly handshake.
///
/// Deliberately a CHOOSER, not a yes/no. Nothing about an offer is locked
/// while challengers deliberate, so several lobbies can clear their own RSVP
/// threshold on the same fixture — and home is picking *who to meet*, not
/// merely consenting to whoever asked first. Every row therefore leads with
/// the things that decide that: strength, trustworthiness, and how many of
/// them are actually coming.
Future<void> showChallengerChooserSheet(BuildContext context, String lobbyId) {
  return showPSheet(
    context: context,
    maxHeightRatio: 1.0,
    builder: (_) => _ChallengerChooserSheet(lobbyId: lobbyId),
  );
}

class _ChallengerChooserSheet extends ConsumerWidget {
  final String lobbyId;
  const _ChallengerChooserSheet({required this.lobbyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pendingChallengersControllerProvider(lobbyId));
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return SingleChildScrollView(
      primary: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          PSheetTitle(
            label: 'challenge.chooser.title'.tr(),
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
              child: Text(
                'errorGeneric'.tr(),
                style: TextStyle(color: colors.destructive),
              ),
            ),
            data: (list) {
              if (list.isEmpty) {
                return PEmptySectionPlaceholder(
                  hero: const Icon(FLucideIcons.swords, size: 32),
                  title: 'challenge.chooser.emptyTitle'.tr(),
                  subtitle: 'challenge.chooser.emptySubtitle'.tr(),
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  // Accepting is not a private act: it spends the slot and
                  // ends everyone else's wait. Say so before the button, not
                  // in a toast afterwards.
                  Text(
                    list.length > 1
                        ? 'challenge.chooser.explainerMany'.tr(
                            namedArgs: {'count': '${list.length}'},
                          )
                        : 'challenge.chooser.explainerOne'.tr(),
                    style: typography.body.sm.copyWith(
                      color: colors.mutedForeground,
                    ),
                  ),
                  for (final c in list)
                    _ChallengerRow(lobbyId: lobbyId, challenger: c),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ChallengerRow extends ConsumerWidget {
  final String lobbyId;
  final PendingChallenger challenger;

  const _ChallengerRow({required this.lobbyId, required this.challenger});

  Future<void> _respond(
    BuildContext context,
    WidgetRef ref, {
    required bool accept,
  }) async {
    try {
      await ref
          .read(respondFriendlyChallengeControllerProvider(lobbyId).notifier)
          .respond(challenger.challengeId, accept: accept);
    } catch (e, st) {
      talker.handle(e, st);
      if (!context.mounted) return;
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleX),
        variant: .destructive,
        title: Text(respondFriendlyChallengeErrorMessage(e)),
        alignment: .bottomCenter,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final inFlight = ref.watch(
      respondFriendlyChallengeControllerProvider(lobbyId),
    );
    final busy = inFlight != null;
    final isMine = inFlight == challenger.challengeId;

    return PCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          // Name + MMR. Both are dynamic-length, so the name flexes and the
          // MMR chip keeps its size (375px reference width).
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () =>
                      showLobbyPublicPreviewSheet(context, challenger.lobbyId),
                  child: Row(
                    spacing: 6,
                    children: [
                      Flexible(
                        child: Text(
                          challenger.lobbyName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: typography.body.md.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Icon(
                        FLucideIcons.chevronRight,
                        size: 14,
                        color: colors.mutedForeground,
                      ),
                    ],
                  ),
                ),
              ),
              _Chip(
                icon: FLucideIcons.trendingUp,
                label: challenger.mmr == null
                    ? '—'
                    : challenger.hasProvisionalMmr
                    ? 'challenge.chooser.mmrProvisional'.tr(
                        namedArgs: {'mmr': '${challenger.mmr}'},
                      )
                    : '${challenger.mmr}',
              ),
            ],
          ),

          // Trust is the whole reason this mode can work without a referee, so
          // it sits beside strength rather than buried in the profile.
          Row(
            spacing: 8,
            children: [
              _Chip(
                icon: FLucideIcons.shieldCheck,
                label: 'challenge.chooser.trust'.tr(
                  namedArgs: {'score': '${challenger.trustScore ?? 40}'},
                ),
                tone: challenger.isLowTrust ? colors.destructive : null,
              ),
              _Chip(
                icon: FLucideIcons.users,
                label: '${challenger.memberCount}',
              ),
              Flexible(
                child: Text(
                  challenger.topVerdicts
                      .map(
                        (e) =>
                            '${e.value} ${e.key.getLocalizedName(context).toLowerCase()}',
                      )
                      .join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.body.sm.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ),
            ],
          ),

          // Which fixture this answers. Home can have three slots open at
          // once, so the date is not implied by the sheet being open.
          Row(
            spacing: 6,
            children: [
              Icon(
                FLucideIcons.calendar,
                size: 14,
                color: colors.mutedForeground,
              ),
              Expanded(
                child: Text(
                  [
                    if (challenger.kickoff != null)
                      formatMatchDateTime(challenger.kickoff!),
                    if ((challenger.locationName ?? '').isNotEmpty)
                      challenger.locationName!,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.body.sm.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ),
            ],
          ),

          // How many of theirs are actually coming, against the bar THEY set.
          // A lobby that scraped past its own minimum reads differently from
          // one that turned out in force.
          Row(
            spacing: 6,
            children: [
              Icon(
                FLucideIcons.userCheck,
                size: 14,
                color: colors.mutedForeground,
              ),
              Flexible(
                child: Text(
                  'challenge.chooser.turnout'.tr(
                    namedArgs: {
                      'going': '${challenger.goingCount}',
                      'threshold': '${challenger.confirmationThreshold ?? 0}',
                    },
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.body.sm.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ),
            ],
          ),

          if ((challenger.note ?? '').trim().isNotEmpty)
            Text(
              challenger.note!,
              style: typography.body.sm.copyWith(fontStyle: FontStyle.italic),
            ),

          Row(
            spacing: 8,
            children: [
              Expanded(
                child: FButton(
                  variant: .secondary,
                  onPress: busy
                      ? null
                      : () => _respond(context, ref, accept: false),
                  child: Text('challenge.chooser.decline'.tr()),
                ),
              ),
              Expanded(
                child: FButton(
                  onPress: busy
                      ? null
                      : () => _respond(context, ref, accept: true),
                  child: isMine
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('challenge.chooser.accept'.tr()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? tone;

  const _Chip({required this.icon, required this.label, this.tone});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final color = tone ?? colors.mutedForeground;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        Icon(icon, size: 14, color: color),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.theme.typography.body.sm.copyWith(color: color),
        ),
      ],
    );
  }
}
