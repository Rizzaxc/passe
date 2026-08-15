import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../auth/auth_controller.dart';
import '../notifications/notification_service.dart';
import '../ui/main.dart';
import 'block_report_sheet.dart';
import 'friendship_controller.dart';
import 'profile_overview_tab.dart';
import 'user_page_controller.dart';

/// `/user/:id` — another player's page: identity, the viewer's relationship to
/// them, and their read-only profile overview.
///
/// Reached from a lobby member row, a friend search result, a feed post author
/// and a tag chip. `initialName` is passed as `$extra` so the header can show a
/// name before the RPC lands, the same trick `ProfessionalDetailPage` uses.
class UserPage extends ConsumerWidget {
  final String userId;
  final String? initialName;

  const UserPage({super.key, required this.userId, this.initialName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(userId));
    final isSelf = ref.watch(currentUserIdProvider) == userId;

    return FScaffold(
      header: FHeader.nested(
        title: Text(profileAsync.value?.username ?? initialName ?? ''),
        prefixes: [
          FHeaderAction.back(
            onPress: () {
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            },
          ),
        ],
        suffixes: [
          if (!isSelf && profileAsync.value != null)
            FHeaderAction(
              icon: const Icon(FLucideIcons.ellipsisVertical),
              onPress: () =>
                  showUserActionsSheet(context, profile: profileAsync.value!),
            ),
        ],
      ),
      child: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) =>
            PEmptySectionPlaceholder(subtitle: 'social.profileError'.tr()),
        data: (profile) {
          if (profile == null) {
            return PEmptySectionPlaceholder(
              subtitle: 'social.profileMissing'.tr(),
            );
          }
          // The self-profile tab sits inside the bottom-nav shell
          // (`ScaffoldWithNavBar`), itself an `FScaffold`, so its content gets
          // the theme's horizontal childPadding applied twice — once by the
          // shell, once by the tab's own `FScaffold`. This page is a pushed
          // route with only one `FScaffold`, so it needs an explicit extra 8px
          // to match that stacked 16px total instead of coming up short.
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    children: [
                      _IdentityBlock(profile: profile),
                      const SizedBox(height: 20),
                      if (!isSelf) _FriendCta(profile: profile),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ProfileOverviewTab(
                    userId: userId,
                    details: profile.details,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _IdentityBlock extends StatelessWidget {
  final UserProfile profile;
  const _IdentityBlock({required this.profile});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return Column(
      children: [
        PUserAvatar(
          userId: profile.userId,
          username: profile.username,
          generatedAvatar: profile.generatedAvatar,
          radius: 44,
        ),
        const SizedBox(height: 12),
        // Username is user-controlled and up to 16 chars; the tag rides along
        // in the same Text.rich so the pair ellipsizes together on a narrow
        // screen rather than the tag wrapping onto its own line.
        Text.rich(
          TextSpan(children: [
            TextSpan(
              text: profile.username,
              style: typography.body.lg.copyWith(fontWeight: FontWeight.w700),
            ),
            TextSpan(
              text: ' #${profile.tagNumber}',
              style: typography.body.sm.copyWith(color: colors.mutedForeground),
            ),
          ]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 16,
          children: [
            Flexible(
              child: Text(
                'social.friendCount'
                    .tr(namedArgs: {'count': '${profile.friendCount}'}),
                style: typography.body.sm.copyWith(color: colors.mutedForeground),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (profile.sharedLobbyCount > 0)
              Flexible(
                child: Text(
                  'social.sharedLobbyCount'
                      .tr(namedArgs: {'count': '${profile.sharedLobbyCount}'}),
                  style: typography.body.sm.copyWith(color: colors.mutedForeground),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// The relationship CTA. Guests get a disabled state rather than a button that
/// throws — `send_friend_request` requires an authenticated uid.
class _FriendCta extends ConsumerStatefulWidget {
  final UserProfile profile;
  const _FriendCta({required this.profile});

  @override
  ConsumerState<_FriendCta> createState() => _FriendCtaState();
}

class _FriendCtaState extends ConsumerState<_FriendCta> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(userProfileProvider(widget.profile.userId));
    } catch (e, st) {
      Talker().handle(e, st, 'Friendship action failed');
      if (!mounted) return;
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleX),
        variant: .destructive,
        title: Text('social.actionFailed'.tr()),
        alignment: .bottomCenter,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendRequest() async {
    final notifier = ref.read(friendshipControllerProvider.notifier);
    await _run(() => notifier.sendRequest(widget.profile.userId));
    if (!mounted) return;
    // Soft-ask at the first moment notifications become meaningful, per the
    // notifications runbook — never a cold OS prompt.
    await ref
        .read(notificationServiceProvider)
        .maybePromptAndRegister(context, ref);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    final notifier = ref.read(friendshipControllerProvider.notifier);
    final profile = widget.profile;

    if (user == null || user.isGuest) {
      return FButton(
        onPress: null,
        prefix: const Icon(FLucideIcons.userPlus),
        child: Text('social.addFriendGuest'.tr()),
      );
    }

    return switch (profile.friendState) {
      FriendState.none => FButton(
          onPress: _busy ? null : _sendRequest,
          prefix: const Icon(FLucideIcons.userPlus),
          child: Text('social.addFriend'.tr()),
        ),
      FriendState.outgoing => FButton(
          variant: .outline,
          onPress: _busy
              ? null
              : () => _run(() => notifier.unfriend(profile.userId)),
          prefix: const Icon(FLucideIcons.clock),
          child: Text('social.requestSentCancel'.tr()),
        ),
      FriendState.incoming => Row(
          spacing: 8,
          children: [
            Expanded(
              child: FButton(
                onPress: _busy || profile.friendshipId == null
                    ? null
                    : () => _run(() => notifier.respond(profile.friendshipId!,
                        accept: true)),
                child: Text('social.accept'.tr()),
              ),
            ),
            Expanded(
              child: FButton(
                variant: .outline,
                onPress: _busy || profile.friendshipId == null
                    ? null
                    : () => _run(() => notifier.respond(profile.friendshipId!,
                        accept: false)),
                child: Text('social.decline'.tr()),
              ),
            ),
          ],
        ),
      FriendState.friend => FButton(
          variant: .outline,
          onPress: null,
          prefix: const Icon(FLucideIcons.userCheck),
          child: Text('social.alreadyFriends'.tr()),
        ),
      FriendState.blocked => FButton(
          variant: .outline,
          onPress:
              _busy ? null : () => _run(() => notifier.unblock(profile.userId)),
          prefix: const Icon(FLucideIcons.ban),
          child: Text('social.unblock'.tr()),
        ),
    };
  }
}
