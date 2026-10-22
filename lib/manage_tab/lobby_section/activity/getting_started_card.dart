import 'package:easy_localization/easy_localization.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/user_preferences.dart';
import '../invite_member_sheet.dart';
import '../members/controller.dart';
import '../schedule_activity_sheet.dart';
import 'upcoming_controller.dart';

/// Which "Bắt đầu" steps a lobby has already done, read from real data rather
/// than from taps — inviting someone who never joins doesn't tick step 1.
class GettingStartedProgress {
  final bool hasMembers;
  final bool hasActivity;

  const GettingStartedProgress({
    required this.hasMembers,
    required this.hasActivity,
  });

  /// [hasScheduledBefore] covers a lobby whose sessions are all in the
  /// past: it has done this step even with nothing upcoming.
  factory GettingStartedProgress.from({
    required int memberCount,
    required int upcomingCount,
    bool hasScheduledBefore = false,
  }) => GettingStartedProgress(
    hasMembers: memberCount > 1,
    hasActivity: upcomingCount > 0 || hasScheduledBefore,
  );

  int get doneCount => (hasMembers ? 1 : 0) + (hasActivity ? 1 : 0);
  bool get isComplete => hasMembers && hasActivity;
}

/// Per-user list of lobby ids whose card was dismissed. User-namespaced on
/// purpose: a different account on the same phone should still see it.
class GettingStartedPrefs {
  GettingStartedPrefs._();

  static const _dismissedKey = 'LOBBY_GETTING_STARTED_DISMISSED';

  static Future<bool> isDismissed(String lobbyId) async {
    final ids = await UserPreferences.instance.getStringList(_dismissedKey);
    return ids?.contains(lobbyId) ?? false;
  }

  static Future<void> dismiss(String lobbyId) async {
    final ids = {
      ...?await UserPreferences.instance.getStringList(_dismissedKey),
      lobbyId,
    };
    await UserPreferences.instance.setStringList(_dismissedKey, ids.toList());
  }
}

final _dismissedProvider = FutureProvider.autoDispose.family<bool, String>(
  (ref, lobbyId) => GettingStartedPrefs.isDismissed(lobbyId),
);

/// The two things a brand-new lobby needs before its Feed has anything in
/// it: people, and a first session. Shown to captains/coordinators at the
/// top of the Feed until both are done or they dismiss it — it replaces what
/// used to be a blank screen right after "Tạo".
class LobbyGettingStartedCard extends ConsumerWidget {
  final String lobbyId;

  /// Whether the lobby's feed already shows a session being scheduled —
  /// passed in by the Feed tab, which has the items in hand.
  final bool hasScheduledBefore;

  const LobbyGettingStartedCard({
    super.key,
    required this.lobbyId,
    this.hasScheduledBefore = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(lobbyMembersControllerProvider(lobbyId));
    final upcoming = ref.watch(
      lobbyUpcomingActivitiesControllerProvider(lobbyId),
    );
    final dismissed = ref.watch(_dismissedProvider(lobbyId));

    // Never flash a half-known checklist: wait for both reads.
    if (!members.hasValue || !upcoming.hasValue || !dismissed.hasValue) {
      return const SizedBox.shrink();
    }
    if (dismissed.value!) return const SizedBox.shrink();

    final progress = GettingStartedProgress.from(
      memberCount: members.value!.length,
      upcomingCount: upcoming.value!.length,
      hasScheduledBefore: hasScheduledBefore,
    );
    if (progress.isComplete) return const SizedBox.shrink();

    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'lobbyHub.gettingStarted.title'.tr(),
                  style: typography.body.md.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${progress.doneCount}/2',
                style: typography.body.xs.copyWith(
                  color: colors.mutedForeground,
                  fontWeight: FontWeight.w600,
                ),
              ),
              FButton.icon(
                variant: .ghost,
                size: .sm,
                onPress: () async {
                  await GettingStartedPrefs.dismiss(lobbyId);
                  ref.invalidate(_dismissedProvider(lobbyId));
                },
                child: const Icon(FLucideIcons.x, size: 16),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 6),
            child: Text(
              'lobbyHub.gettingStarted.body'.tr(),
              style: typography.body.xs.copyWith(color: colors.mutedForeground),
            ),
          ),
          _Step(
            done: progress.hasMembers,
            icon: FLucideIcons.userPlus,
            title: 'lobbyHub.gettingStarted.invite'.tr(),
            subtitle: 'lobbyHub.gettingStarted.inviteHint'.tr(),
            onPress: () => showInviteMemberSheet(context, lobbyId),
          ),
          _Step(
            done: progress.hasActivity,
            icon: FLucideIcons.calendarPlus,
            title: 'lobbyHub.gettingStarted.schedule'.tr(),
            subtitle: 'lobbyHub.gettingStarted.scheduleHint'.tr(),
            onPress: () => showScheduleActivitySheet(context, lobbyId),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final bool done;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPress;

  const _Step({
    required this.done,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return FTappable(
      onPress: done ? null : onPress,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
        child: Row(
          spacing: 12,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? colors.primary : colors.secondary,
              ),
              child: Icon(
                done ? FLucideIcons.check : icon,
                size: 16,
                color: done ? colors.primaryForeground : colors.primary,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typography.body.sm.copyWith(
                      fontWeight: FontWeight.w700,
                      color: done ? colors.mutedForeground : colors.foreground,
                      decoration: done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (!done)
                    Text(
                      subtitle,
                      style: typography.body.xs.copyWith(
                        color: colors.mutedForeground,
                      ),
                    ),
                ],
              ),
            ),
            if (!done)
              Icon(
                FLucideIcons.chevronRight,
                size: 16,
                color: colors.mutedForeground,
              ),
          ],
        ),
      ),
    );
  }
}
