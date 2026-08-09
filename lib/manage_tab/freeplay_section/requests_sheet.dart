import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../freeplay/chat_sheet.dart';
import '../../freeplay/model.dart';
import '../../freeplay/repository.dart';
import '../../ui/main.dart';

Future<void> showHostFreeplayRequests(
  BuildContext context,
  String activityId,
) => showPSheet(
  context: context,
  maxHeightRatio: 1,
  builder: (_) => _Requests(activityId: activityId),
);

class _Requests extends ConsumerWidget {
  final String activityId;
  const _Requests({required this.activityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(freeplayRequestsProvider(activityId));
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .78,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PSheetTitle(
            label: 'Yêu cầu tham gia',
            trailing: FButton.icon(
              variant: .ghost,
              onPress: () => Navigator.pop(context),
              child: const Icon(FLucideIcons.x),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: requests.when(
              loading: () => const Center(child: FCircularProgress()),
              error: (_, _) =>
                  const Center(child: Text('Không tải được yêu cầu')),
              data: (items) => items.isEmpty
                  ? const Center(child: Text('Chưa có yêu cầu'))
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final request = items[index];
                        return FTile(
                          prefix: const Icon(FLucideIcons.userRound),
                          title: Text(
                            request.username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${request.skill ?? 'Chưa khai báo'} · ${request.status.name}',
                          ),
                          suffix:
                              request.status == FreeplayRequestStatus.pending
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FButton.icon(
                                      variant: .outline,
                                      size: .sm,
                                      onPress: () async {
                                        await ref
                                            .read(freeplayRepositoryProvider)
                                            .respond(request.id, false);
                                        ref.invalidate(
                                          freeplayRequestsProvider(activityId),
                                        );
                                      },
                                      child: const Icon(FLucideIcons.x),
                                    ),
                                    const SizedBox(width: 6),
                                    FButton.icon(
                                      size: .sm,
                                      onPress: () async {
                                        try {
                                          await ref
                                              .read(freeplayRepositoryProvider)
                                              .respond(request.id, true);
                                          ref.invalidate(
                                            freeplayRequestsProvider(
                                              activityId,
                                            ),
                                          );
                                          ref.invalidate(
                                            hostFreeplayProvider(false),
                                          );
                                        } catch (_) {
                                          if (context.mounted) {
                                            showFToast(
                                              context: context,
                                              variant: .destructive,
                                              title: const Text(
                                                'Buổi chơi đã đủ chỗ',
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      child: const Icon(FLucideIcons.check),
                                    ),
                                  ],
                                )
                              : FButton.icon(
                                  variant: .ghost,
                                  onPress: request.status.isOpen
                                      ? () => showFreeplayChatSheet(
                                          context,
                                          request.id,
                                          host: true,
                                        )
                                      : null,
                                  child: const Icon(FLucideIcons.messageCircle),
                                ),
                          onPress: request.status.isOpen
                              ? () => showFreeplayChatSheet(
                                  context,
                                  request.id,
                                  host: true,
                                )
                              : null,
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
