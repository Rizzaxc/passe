// Planner tab empty state — shown when a lobby has zero current/future
// activities. Extracted from the old pinned hero's empty branch.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../../../core/feature_flags.dart';
import '../../../../ui/button_styles.dart';
import '../challenge_offer_sheet.dart';
import '../schedule_activity_sheet.dart';
import 'feed_controller.dart';

const _crimson = Color(0xFFDC143C);
const _crimsonTint = Color(0xFFFFEBED);

class PlannerEmptyState extends ConsumerWidget {
  final String lobbyId;
  final bool isLeader;

  const PlannerEmptyState({
    super.key,
    required this.lobbyId,
    required this.isLeader,
  });

  Future<void> _remindCaptain(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(lobbyFeedControllerProvider(lobbyId).notifier)
          .postPersonalAction('remind_captain');
    } catch (e, st) {
      Talker().handle(e, st, 'Remind captain failed');
      if (context.mounted) {
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.circleX),
          variant: .destructive,
          title: Text('lobbyHub.planner.remindFailed'.tr()),
          alignment: .bottomCenter,
        );
      }
      return;
    }
    if (context.mounted) {
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.check),
        title: Text('lobbyHub.planner.reminded'.tr()),
        alignment: .bottomCenter,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          // Stretch so the card's own width doesn't shrink-wrap to
          // whichever CTA happens to be shown below.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: _crimsonTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_today_outlined,
                  size: 22,
                  color: _crimson,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'lobbyHub.planner.emptyTitle'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF09090B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isLeader
                  ? ClientFeatureFlags.challengerFlow
                        ? 'lobbyHub.planner.leaderChallengeHint'.tr()
                        : 'lobbyHub.planner.leaderHint'.tr()
                  : 'lobbyHub.planner.memberHint'.tr(),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: colors.mutedForeground,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (isLeader)
              Column(
                spacing: 8,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FButton(
                      size: .sm,
                      style: FButtonStyleExtension.accentBlueStyle(
                        context.theme.buttonStyles.primary.base,
                      ),
                      onPress: () =>
                          showScheduleActivitySheet(context, lobbyId),
                      child: _CTALabel(
                        icon: const Icon(
                          Icons.calendar_month_outlined,
                          size: 16,
                        ),
                        label: 'lobbyHub.planner.schedule'.tr(),
                      ),
                    ),
                  ),
                  // Was "Mời Thách Đấu" — challenging by SearchID from inside
                  // your own lobby is retired (challenges start from Discover,
                  // against a lobby that actually opted in). What replaces it
                  // is the other half of that flow: opting *this* lobby in.
                  if (ClientFeatureFlags.challengerFlow)
                    ChallengeOfferControl(
                      lobbyId: lobbyId,
                      canManage: isLeader,
                    ),
                ],
              )
            else
              GestureDetector(
                onTap: () => _remindCaptain(context, ref),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colors.secondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        FLucideIcons.bell,
                        size: 14,
                        color: colors.secondaryForeground,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'lobbyHub.planner.remind'.tr(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colors.secondaryForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Compact icon + label used inside the empty state's "Lên Lịch" button.
/// Color comes from whatever the enclosing [FButton]'s style resolves to.
class _CTALabel extends StatelessWidget {
  final Widget icon;
  final String label;

  const _CTALabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 6,
    children: [
      icon,
      Flexible(
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    ],
  );
}
