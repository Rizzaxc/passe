import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../freeplay/model.dart';
import '../../../freeplay/repository.dart';
import '../../../router.dart';
import '../../../ui/main.dart';

class PlayerFreeplaySection extends ConsumerWidget {
  const PlayerFreeplaySection({super.key});

  Future<void> _showHistory(BuildContext context) => showPSheet(
    context: context,
    maxHeightRatio: 1,
    builder: (_) => const _History(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(myFreeplayProvider(false));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PSectionHeader(
          title: 'Xé vé của bạn',
          suffix: FButton.icon(
            variant: .ghost,
            onPress: () => _showHistory(context),
            child: const Icon(FLucideIcons.history),
          ),
        ),
        sessions.when(
          loading: () => const SizedBox(
            height: 52,
            child: Center(child: FCircularProgress()),
          ),
          error: (_, _) => const SizedBox.shrink(),
          data: (items) => items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(
                    'Các yêu cầu và buổi đã nhận sẽ xuất hiện ở đây.',
                    style: context.theme.typography.body.sm.copyWith(
                      color: context.theme.colors.mutedForeground,
                    ),
                  ),
                )
              : ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 210),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, index) =>
                        _SessionTile(activity: items[index]),
                  ),
                ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

class _SessionTile extends StatelessWidget {
  final FreeplayActivity activity;
  const _SessionTile({required this.activity});
  @override
  Widget build(BuildContext context) => FTile(
    prefix: Icon(
      activity.myRequestStatus == FreeplayRequestStatus.accepted
          ? FLucideIcons.ticketCheck
          : FLucideIcons.clock3,
    ),
    title: Text(
      activity.hostName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    subtitle: Text(
      '${DateFormat('EEE d/M, HH:mm', 'vi').format(activity.startTime)} · ${activity.venueName}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    suffix: const Icon(FLucideIcons.chevronRight),
    onPress: () => FreeplayDetailRoute(id: activity.id).push(context),
  );
}

class _History extends ConsumerWidget {
  const _History();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(myFreeplayProvider(true));
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .76,
      child: Column(
        children: [
          PSheetTitle(
            label: 'Lịch sử Xé vé',
            trailing: FButton.icon(
              variant: .ghost,
              onPress: () => Navigator.pop(context),
              child: const Icon(FLucideIcons.x),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: history.when(
              loading: () => const Center(child: FCircularProgress()),
              error: (_, _) =>
                  const Center(child: Text('Không tải được lịch sử')),
              data: (items) => items.isEmpty
                  ? const Center(child: Text('Chưa có lịch sử'))
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (context, index) =>
                          _SessionTile(activity: items[index]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
