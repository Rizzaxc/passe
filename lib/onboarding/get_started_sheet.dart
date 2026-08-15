import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../auth/guest_prompt.dart';
import '../manage_tab/lobby_section/feed/lobby_form_sheet.dart';
import '../router.dart';
import '../social/friends_screen.dart';
import '../ui/sheet.dart';
import 'onboarding_controller.dart';
import 'onboarding_step_badge.dart';

/// Closing step of the onboarding follow-up chain. A new user's Feed (the
/// first tab) has no posts until they have friends or lobby-mates — see
/// `lib/feed_tab/CLAUDE.md` — so ending the guide on the passive coach-mark
/// tour alone leaves them staring at an empty screen. This hands them one
/// concrete next action instead: each tile is a real deep-link into that
/// flow, not another label pointing at a tab.
///
/// "Create a lobby with people you already know" is the hero action, not
/// just another tile: Discover-based matching (find teammates, add a
/// friend by search) only works if there's someone else nearby to match
/// against — a real risk on a freshly-launched, thin-liquidity app.
/// Creating a lobby with your own existing group succeeds unconditionally,
/// so it's the one path that never dead-ends a new user the way an empty
/// Discover result can.
Future<void> showGetStartedSheet(BuildContext context, WidgetRef ref) async {
  await showPSheet(
    context: context,
    builder: (_) => const _GetStartedContent(),
  );
  if (!context.mounted) return;
  await ref.read(onboardingStateProvider.notifier).completeGetStarted();
}

class _GetStartedContent extends ConsumerWidget {
  const _GetStartedContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;

    // Unlike the other actions, this one waits for the pushed sheet's
    // result before popping — canceling lobby creation should return the
    // user to this sheet to pick something else, not dump them out of the
    // guide entirely.
    Future<void> createLobby() async {
      if (!ensureSignedIn(context, ref)) return;
      final lobby = await showLobbyFormSheet(context: context, ref: ref);
      if (!context.mounted || lobby == null) return;
      Navigator.of(context).pop();
      LobbyDetailRoute(id: lobby.id!, $extra: lobby.name).go(context);
    }

    // Guard *before* popping this sheet — ensureSignedIn needs a live
    // context to show its own prompt sheet on top when it returns false.
    void addFriends() {
      if (!ensureSignedIn(context, ref)) return;
      Navigator.of(context).pop();
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const FriendsScreen()));
    }

    void findTeammates() {
      Navigator.of(context).pop();
      // Opens straight into the filter sheet rather than a bare (possibly
      // empty) list — see TeammateSubtab.openFilter.
      const DiscoverTeammateRoute(openFilter: true).go(context);
    }

    void findCoach() {
      Navigator.of(context).pop();
      const DiscoverProfessionalRoute().go(context);
    }

    void connectWearable() {
      if (!ensureSignedIn(context, ref)) return;
      Navigator.of(context).pop();
      const HealthRoute().go(context);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PSheetTitle(
            label: 'onboarding.getStarted.title'.tr(),
            trailing: const OnboardingStepBadge(step: 4, total: 4),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'onboarding.getStarted.body'.tr(),
              style: context.theme.typography.body.sm.copyWith(
                color: colors.mutedForeground,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _HeroAction(
            icon: FLucideIcons.shieldPlus,
            title: 'onboarding.getStarted.createLobby.title'.tr(),
            subtitle: 'onboarding.getStarted.createLobby.subtitle'.tr(),
            badge: 'onboarding.getStarted.createLobby.badge'.tr(),
            onPress: createLobby,
          ),
          const SizedBox(height: 12),
          FTileGroup(
            children: [
              FTile(
                prefix: const Icon(FLucideIcons.userPlus),
                title: Text(
                  'onboarding.getStarted.friends.title'.tr(),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
                subtitle: Text(
                  'onboarding.getStarted.friends.subtitle'.tr(),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
                suffix: const Icon(FLucideIcons.chevronRight),
                onPress: addFriends,
              ),
              FTile(
                prefix: const Icon(FLucideIcons.users),
                title: Text(
                  'onboarding.getStarted.lobby.title'.tr(),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
                subtitle: Text(
                  'onboarding.getStarted.lobby.subtitle'.tr(),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
                suffix: const Icon(FLucideIcons.chevronRight),
                onPress: findTeammates,
              ),
              FTile(
                prefix: const Icon(FLucideIcons.graduationCap),
                title: Text(
                  'onboarding.getStarted.coach.title'.tr(),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
                subtitle: Text(
                  'onboarding.getStarted.coach.subtitle'.tr(),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
                suffix: const Icon(FLucideIcons.chevronRight),
                onPress: findCoach,
              ),
              FTile(
                prefix: const Icon(FLucideIcons.activity),
                title: Text(
                  'onboarding.getStarted.wearable.title'.tr(),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
                subtitle: Text(
                  'onboarding.getStarted.wearable.subtitle'.tr(),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
                suffix: Text(
                  'onboarding.getStarted.wearable.optional'.tr(),
                  style: context.theme.typography.body.sm.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
                onPress: connectWearable,
              ),
            ],
          ),
          const SizedBox(height: 16),
          FButton(
            variant: .outline,
            onPress: () => Navigator.of(context).pop(),
            child: Text('onboarding.skip'.tr()),
          ),
        ],
      ),
    );
  }
}

/// The one option on this sheet styled as a hero rather than a plain
/// [FTile] — see the "Create a lobby" doc comment above for why it's
/// singled out.
class _HeroAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final VoidCallback onPress;

  const _HeroAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final onPrimary = colors.primaryForeground;

    return FTappable(
      onPress: onPress,
      builder: (context, states, child) => DecoratedBox(
        decoration: BoxDecoration(
          color: colors.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: child,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: onPrimary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: onPrimary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge sits on its own line above the title rather than
                  // sharing a Row with it — at this card width a longer
                  // title (Vietnamese or English) plus badge overflowed the
                  // available space and silently truncated the title.
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: onPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge,
                      style: context.theme.typography.body.xs.copyWith(
                        color: onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: context.theme.typography.body.md.copyWith(
                      color: onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: context.theme.typography.body.sm.copyWith(
                      color: onPrimary.withValues(alpha: 0.85),
                    ),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(FLucideIcons.chevronRight, color: onPrimary),
          ],
        ),
      ),
    );
  }
}
