import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/model/activity.dart';
import 'controller.dart';

class UpcomingSection extends ConsumerWidget {
  final String lobbyId;

  const UpcomingSection({super.key, required this.lobbyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingAsync = ref.watch(lobbyUpcomingControllerProvider(lobbyId));

    return upcomingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text('errorGeneric'.tr()),
      ),
      data: (activities) => activities.isEmpty
          ? _UpcomingEmpty(lobbyId: lobbyId)
          : Column(
              children: activities
                  .map((a) => _ActivityTile(activity: a))
                  .toList(),
            ),
    );
  }
}

class _UpcomingEmpty extends StatelessWidget {
  final String lobbyId;

  const _UpcomingEmpty({required this.lobbyId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: FCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'lobby.detail.noUpcoming'.tr(),
                  style: context.theme.typography.body.sm.copyWith(
                    color: context.theme.colors.mutedForeground,
                  ),
                ),
              ),
              FButton(
                variant: .outline,
                onPress: () {
                  // TODO: navigate to schedule new event screen
                },
                child: Text('lobby.detail.scheduleEvent'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final Activity activity;

  const _ActivityTile({required this.activity});

  @override
  Widget build(BuildContext context) {
    final local = activity.startTime.toLocal();
    final dateStr = DateFormat('EEE, dd MMM').format(local);
    final timeStr = DateFormat('HH:mm').format(local);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: FCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    dateStr,
                    style: context.theme.typography.body.sm
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    timeStr,
                    style: context.theme.typography.body.sm.copyWith(
                      color: context.theme.colors.mutedForeground,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Icon(
                FLucideIcons.calendarDays,
                size: 16,
                color: context.theme.colors.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
