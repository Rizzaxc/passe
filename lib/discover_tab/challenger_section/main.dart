import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/format.dart';
import '../../core/model/challenge.dart';
import '../../logger/talker.dart';
import '../../router.dart';
import '../../ui/main.dart';
import '../filter.dart';
import '../lobby_public_preview_sheet.dart';
import '../main.dart';
import 'confirm_challenge_sheet.dart';
import 'feed_controller.dart';
import 'friendly_offer_feed_controller.dart';

/// Discover ▸ Thách đấu, friendly mode.
///
/// The unit of this feed is an advertised FIXTURE, not a lobby: a club can have
/// three dates open and a challenger is choosing between dates as much as
/// between opponents. Sending is not a bare "challenge" button either — it
/// commits the challenger's own members first, so the confirm sheet is where
/// they set the bar their side has to clear.
class ChallengerSubtab extends ConsumerWidget {
  const ChallengerSubtab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contextOptions = ref.watch(contextLobbyOptionsProvider);
    final hasNoLobby = contextOptions.value?.isEmpty ?? false;
    final feed = ref.watch(friendlyOfferFeedProvider);

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
                ref.invalidate(friendlyOfferFeedProvider);
                await ref.read(friendlyOfferFeedProvider.future);
              },
              child: feed.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, st) {
                  talker.handle(e, st, 'friendly offer feed failed');
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      PEmptySectionPlaceholder(
                        subtitle: 'errorGeneric'.tr(),
                      ),
                    ],
                  );
                },
                data: (offers) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  children: [
                    if (offers.isEmpty)
                      PEmptySectionPlaceholder(
                        hero: Icon(
                          FLucideIcons.swords,
                          size: 64,
                          color: context.theme.colors.mutedForeground,
                        ),
                        title: 'challenge.feed.emptyTitle'.tr(),
                        subtitle: 'challenge.feed.emptySubtitle'.tr(),
                      )
                    else
                      for (final o in offers) _OfferCard(offer: o),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _OfferCard extends ConsumerWidget {
  final FriendlyOffer offer;
  const _OfferCard({required this.offer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    final terms = <String>[
      offer.ruleset.getLocalizedName(context, param: offer.rulesetParam),
      // The viewer of this feed is always the prospective AWAY side.
      ?offer.handicapSide.getLocalizedLabel(
        context,
        weAreHome: false,
        amount: offer.handicapAmount,
      ),
      if (offer.costSplit != ChallengeCostSplit.none)
        offer.costSplit.getLocalizedLabel(context, weAreHome: false),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () =>
                        showLobbyPublicPreviewSheet(context, offer.lobbyId),
                    child: Row(
                      spacing: 6,
                      children: [
                        Flexible(
                          child: Text(
                            offer.lobbyName,
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
                _FavorabilityChip(value: offer.favorability),
              ],
            ),

            // Strength and trustworthiness sit together: without a referee,
            // who you're agreeing to meet matters as much as how good they are.
            Row(
              spacing: 10,
              children: [
                _Meta(
                  icon: FLucideIcons.trendingUp,
                  label: offer.lobbyMmr == null
                      ? '—'
                      : offer.hasProvisionalMmr
                      ? 'challenge.chooser.mmrProvisional'.tr(
                          namedArgs: {'mmr': '${offer.lobbyMmr}'},
                        )
                      : '${offer.lobbyMmr}',
                ),
                _Meta(
                  icon: FLucideIcons.shieldCheck,
                  label: 'challenge.chooser.trust'.tr(
                    namedArgs: {'score': '${offer.trustScore ?? 40}'},
                  ),
                  tone: offer.isLowTrust ? colors.destructive : null,
                ),
                _Meta(
                  icon: FLucideIcons.users,
                  label: '${offer.memberCount}',
                ),
              ],
            ),

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
                      formatMatchDateTime(offer.kickoff),
                      if ((offer.locationName ?? '').isNotEmpty)
                        offer.locationName!,
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

            Text(
              terms.join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: typography.body.xs.copyWith(
                color: colors.mutedForeground,
              ),
            ),

            FButton(
              size: .sm,
              onPress: offer.alreadyChallenged
                  ? null
                  : () => showConfirmFriendlyChallengeSheet(context, offer),
              child: Text(
                offer.alreadyChallenged
                    ? 'challenge.send.alreadySent'.tr()
                    : 'challenge.send.cta'.tr(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavorabilityChip extends StatelessWidget {
  final String value;
  const _FavorabilityChip({required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final tone = switch (value) {
      'harder' => colors.destructive,
      'easier' => colors.primary,
      _ => colors.mutedForeground,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: tone.withValues(alpha: 0.12),
      ),
      child: Text(
        'challenge.feed.favorability.$value'.tr(),
        style: context.theme.typography.body.xs.copyWith(
          color: tone,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? tone;
  const _Meta({required this.icon, required this.label, this.tone});

  @override
  Widget build(BuildContext context) {
    final color = tone ?? context.theme.colors.mutedForeground;
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Icon(icon, size: 14, color: color),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.theme.typography.body.sm.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
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
                      ref.read(discoverSubtabRequestProvider.notifier).state = 1,
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
