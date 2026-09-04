import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';

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

class _Requests extends ConsumerStatefulWidget {
  final String activityId;
  const _Requests({required this.activityId});

  @override
  ConsumerState<_Requests> createState() => _RequestsState();
}

class _RequestsState extends ConsumerState<_Requests> {
  // Per-request, not a single sheet-wide flag — responding to one request
  // shouldn't freeze the buttons on every other row in the list.
  final _busyIds = <String>{};

  Future<void> _respond(FreeplayRequestItem request, bool accept) async {
    setState(() => _busyIds.add(request.id));
    try {
      await ref.read(freeplayRepositoryProvider).respond(request.id, accept);
      ref.invalidate(freeplayRequestsProvider(widget.activityId));
      if (accept) ref.invalidate(hostFreeplayProvider(false));
    } catch (e, st) {
      Talker().handle(e, st, 'Respond to freeplay request failed');
      if (mounted) {
        // "Full" is the one failure worth naming specifically — the host
        // just watched the roster fill from another request accepted a beat
        // earlier. Everything else (activity ended, network hiccup) gets the
        // generic message rather than a misleading "session is full".
        final full =
            e is PostgrestException && e.message.contains('activity is full');
        showFToast(
          context: context,
          variant: .destructive,
          title: Text(
            (full
                    ? 'freeplay.hostManage.sessionFull'
                    : 'freeplay.hostManage.respondFailed')
                .tr(),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busyIds.remove(request.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(freeplayRequestsProvider(widget.activityId));
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .78,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PSheetTitle(
            label: 'freeplay.hostManage.requestsTitle'.tr(),
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
              error: (_, _) => Center(
                child: Text('freeplay.hostManage.requestsLoadFailed'.tr()),
              ),
              data: (items) => items.isEmpty
                  ? Center(child: Text('freeplay.hostManage.noRequests'.tr()))
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final request = items[index];
                        final busy = _busyIds.contains(request.id);
                        return FTile(
                          prefix: const Icon(FLucideIcons.userRound),
                          title: Text(
                            request.username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${request.skill == null ? 'freeplay.skill.undeclared'.tr() : 'freeplay.skill.${request.skill}'.tr()} · ${_statusKey(request.status).tr()}',
                          ),
                          suffix:
                              request.status == FreeplayRequestStatus.pending
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FButton.icon(
                                      variant: .outline,
                                      size: .sm,
                                      onPress: busy
                                          ? null
                                          : () => _respond(request, false),
                                      child: const Icon(FLucideIcons.x),
                                    ),
                                    const SizedBox(width: 6),
                                    FButton.icon(
                                      size: .sm,
                                      onPress: busy
                                          ? null
                                          : () => _respond(request, true),
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

String _statusKey(FreeplayRequestStatus status) => switch (status) {
  FreeplayRequestStatus.pending => 'freeplay.status.pending',
  FreeplayRequestStatus.accepted => 'freeplay.status.accepted',
  FreeplayRequestStatus.declined => 'freeplay.status.declined',
  FreeplayRequestStatus.cancelled => 'freeplay.status.cancelled',
  FreeplayRequestStatus.hostCancelled => 'freeplay.status.hostCancelled',
  FreeplayRequestStatus.lapsed => 'freeplay.status.lapsed',
  FreeplayRequestStatus.blocked => 'freeplay.status.blocked',
};
