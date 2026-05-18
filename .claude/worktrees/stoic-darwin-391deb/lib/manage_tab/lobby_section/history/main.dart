import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/model/activity.dart';
import '../../../ui/empty_section_placeholder.dart';
import 'controller.dart';

class HistorySection extends ConsumerWidget {
  final String lobbyId;

  const HistorySection({super.key, required this.lobbyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(lobbyHistoryControllerProvider(lobbyId));

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text('errorGeneric'.tr()),
      ),
      data: (activities) => activities.isEmpty
          ? PEmptySectionPlaceholder(
              subtitle: 'lobby.detail.noHistory'.tr(),
            )
          : Column(
              children: activities
                  .map((a) => _HistoryTile(activity: a))
                  .toList(),
            ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final Activity activity;

  const _HistoryTile({required this.activity});

  @override
  Widget build(BuildContext context) {
    final local = activity.startTime.toLocal();
    final dateStr = DateFormat('EEE, dd MMM').format(local);
    final timeStr = DateFormat('HH:mm').format(local);

    String? durationStr;
    if (activity.endTime != null) {
      final dur = activity.endTime!.difference(activity.startTime);
      final h = dur.inHours;
      final m = dur.inMinutes.remainder(60);
      durationStr = h > 0 ? '${h}h ${m}m' : '${m}m';
    }

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
                    style: context.theme.typography.sm
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    timeStr,
                    style: context.theme.typography.sm.copyWith(
                      color: context.theme.colors.mutedForeground,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (durationStr != null)
                Text(
                  durationStr,
                  style: context.theme.typography.sm.copyWith(
                    color: context.theme.colors.mutedForeground,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
