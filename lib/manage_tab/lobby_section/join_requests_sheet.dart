import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../ui/sheet.dart';
import 'join_requests_controller.dart';
import 'members/controller.dart';

void showJoinRequestsSheet(BuildContext context, String lobbyId) {
  showPSheet(
    context: context,
    builder: (_) => _JoinRequestsSheet(lobbyId: lobbyId),
  );
}

class _JoinRequestsSheet extends ConsumerWidget {
  final String lobbyId;

  const _JoinRequestsSheet({required this.lobbyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(joinRequestsControllerProvider(lobbyId));
    final colors = context.theme.colors;

    return SingleChildScrollView(
      primary: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          PSheetTitle(
            label: 'lobby.joinRequests.title'.tr(),
            trailing: FButton.icon(
              variant: .ghost,
              onPress: () => Navigator.of(context).pop(),
              child: const Icon(FIcons.x),
            ),
          ),
          requestsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('errorGeneric'.tr(),
                  style: TextStyle(color: colors.destructive)),
            ),
            data: (requests) => requests.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'lobby.joinRequests.empty'.tr(),
                        style: context.theme.typography.sm
                            .copyWith(color: colors.mutedForeground),
                      ),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < requests.length; i++) ...[
                          _RequestRow(
                            request: requests[i],
                            lobbyId: lobbyId,
                          ),
                          if (i < requests.length - 1)
                            Divider(
                              height: 1,
                              indent: 60,
                              color: colors.border.withValues(alpha: 0.5),
                            ),
                        ],
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _RequestRow extends ConsumerStatefulWidget {
  final JoinRequest request;
  final String lobbyId;

  const _RequestRow({required this.request, required this.lobbyId});

  @override
  ConsumerState<_RequestRow> createState() => _RequestRowState();
}

class _RequestRowState extends ConsumerState<_RequestRow> {
  bool _loading = false;

  Color _avatarColor(String name) {
    const palette = [
      Color(0xFF6366F1),
      Color(0xFF0EA5E9),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEC4899),
      Color(0xFF8B5CF6),
    ];
    return palette[name.hashCode.abs() % palette.length];
  }

  Future<void> _act(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
    } catch (e, st) {
      Talker().handle(e, st, 'join request action failed');
      if (!mounted) return;
      showFToast(
        context: context,
        icon: const Icon(FIcons.circleX),
        variant: .destructive,
        title: Text('errorGeneric'.tr()),
        alignment: .bottomCenter,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final r = widget.request;
    final initial = r.username.isNotEmpty ? r.username[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _avatarColor(r.username),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.username,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF09090B),
                  ),
                ),
                Text(
                  '#${r.tagNumber}',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          if (_loading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else ...[
            FButton.icon(
              variant: .ghost,
              onPress: () => _act(() => ref
                  .read(joinRequestsControllerProvider(widget.lobbyId).notifier)
                  .decline(r.id)),
              child: Icon(FIcons.x, size: 16, color: colors.mutedForeground),
            ),
            const SizedBox(width: 4),
            FButton.icon(
              variant: .secondary,
              onPress: () => _act(() async {
                await ref
                    .read(joinRequestsControllerProvider(widget.lobbyId)
                        .notifier)
                    .accept(r.id);
                ref.invalidate(lobbyMembersControllerProvider(widget.lobbyId));
              }),
              child: const Icon(FIcons.check, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}
