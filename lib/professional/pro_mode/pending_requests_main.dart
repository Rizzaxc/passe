import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../core/format.dart';
import '../../ui/main.dart';
import 'pro_bookings_controller.dart';

/// Manage ▸ pro mode's "pending requests" subtab — accept/reject bookings
/// still at `requested`. Reachable from the `professional_booking_requested`
/// push notification via `ManageRequestsRoute`.
class ProPendingRequestsSection extends ConsumerStatefulWidget {
  final String professionalId;

  /// Set when reached via a professional_booking_requested notification tap
  /// — the matching card scrolls into view and highlights once.
  final String? highlightBookingId;

  const ProPendingRequestsSection({
    super.key,
    required this.professionalId,
    this.highlightBookingId,
  });

  @override
  ConsumerState<ProPendingRequestsSection> createState() =>
      _ProPendingRequestsSectionState();
}

class _ProPendingRequestsSectionState
    extends ConsumerState<ProPendingRequestsSection> {
  final _cardKeys = <String, GlobalKey>{};
  bool _scrolledToHighlight = false;

  void _maybeScrollToHighlight(List<ProBookingItem> requests) {
    final targetId = widget.highlightBookingId;
    if (targetId == null || _scrolledToHighlight) return;
    if (!requests.any((r) => r.id == targetId)) return;
    _scrolledToHighlight = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _cardKeys[targetId];
      final ctx = key?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
          alignment: 0.1,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(
      proPendingRequestsProvider(widget.professionalId),
    );

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(proPendingRequestsProvider(widget.professionalId));
        await ref.read(proPendingRequestsProvider(widget.professionalId).future);
      },
      child: requestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            PEmptySectionPlaceholder(subtitle: 'Không tải được yêu cầu'),
          ],
        ),
        data: (requests) {
          if (requests.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
              children: const [
                PEmptySectionPlaceholder(
                  title: 'Không có yêu cầu nào',
                  subtitle: 'Yêu cầu đặt lịch mới sẽ xuất hiện ở đây.',
                ),
              ],
            );
          }
          _maybeScrollToHighlight(requests);
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            itemCount: requests.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final request = requests[i];
              final key = _cardKeys.putIfAbsent(request.id, () => GlobalKey());
              return _RequestCard(
                key: key,
                professionalId: widget.professionalId,
                request: request,
                highlighted: request.id == widget.highlightBookingId,
              );
            },
          );
        },
      ),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  final String professionalId;
  final ProBookingItem request;
  final bool highlighted;

  const _RequestCard({
    super.key,
    required this.professionalId,
    required this.request,
    this.highlighted = false,
  });

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(proBookingActionControllerProvider(professionalId).notifier)
          .accept(request.id);
    } catch (e, st) {
      Talker().handle(e, st, 'Accept booking failed');
      if (context.mounted) {
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.circleX),
          variant: .destructive,
          title: const Text('Không thể xác nhận — có thể đã trùng lịch'),
          alignment: .bottomCenter,
        );
      }
    }
  }

  Future<void> _rejectWithReason(BuildContext context, WidgetRef ref) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showFDialog<bool>(
      context: context,
      builder: (dialogCtx, style, animation) => PConfirmDialog(
        animation: animation,
        title: const Text('Từ chối yêu cầu?'),
        body: FTextField(
          hint: 'Lý do (tuỳ chọn)',
          control: FTextFieldControl.managed(controller: reasonCtrl),
        ),
        direction: Axis.horizontal,
        actions: [
          FButton(
            variant: .outline,
            onPress: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Đóng'),
          ),
          FButton(
            variant: .destructive,
            onPress: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Từ Chối'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref
          .read(proBookingActionControllerProvider(professionalId).notifier)
          .reject(
            request.id,
            reason: reasonCtrl.text.trim().isEmpty
                ? null
                : reasonCtrl.text.trim(),
          );
    } catch (e, st) {
      Talker().handle(e, st, 'Reject booking failed');
      if (context.mounted) {
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.circleX),
          variant: .destructive,
          title: const Text('Không thể từ chối yêu cầu'),
          alignment: .bottomCenter,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final saving = ref.watch(
      proBookingActionControllerProvider(professionalId),
    );

    final card = PCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Text(
            request.clientName,
            style: context.theme.typography.body.sm.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (request.serviceType != null) Text(request.serviceType!),
          Row(
            spacing: 6,
            children: [
              Icon(FLucideIcons.calendar, size: 14, color: colors.mutedForeground),
              Text(
                '${request.start.day}/${request.start.month} · '
                '${request.start.hour.toString().padLeft(2, '0')}:${request.start.minute.toString().padLeft(2, '0')}'
                ' - ${request.end.hour.toString().padLeft(2, '0')}:${request.end.minute.toString().padLeft(2, '0')}',
                style: context.theme.typography.body.xs.copyWith(
                  color: colors.mutedForeground,
                ),
              ),
            ],
          ),
          if (request.locationName != null)
            Row(
              spacing: 6,
              children: [
                Icon(FLucideIcons.mapPin, size: 14, color: colors.mutedForeground),
                Expanded(
                  child: Text(
                    request.locationName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.theme.typography.body.xs.copyWith(
                      color: colors.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
          if (request.agreedRate != null)
            Text(
              '${formatVnd(request.agreedRate!)}₫',
              style: context.theme.typography.body.sm.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.primary,
              ),
            ),
          if (request.clientNotes != null && request.clientNotes!.isNotEmpty)
            Text(
              '"${request.clientNotes}"',
              style: context.theme.typography.body.xs.copyWith(
                color: colors.mutedForeground,
                fontStyle: FontStyle.italic,
              ),
            ),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: FButton(
                  variant: .outline,
                  onPress: saving ? null : () => _rejectWithReason(context, ref),
                  child: const Text('Từ Chối'),
                ),
              ),
              Expanded(
                child: FButton(
                  onPress: saving ? null : () => _accept(context, ref),
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Xác Nhận'),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (!highlighted) return card;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primary, width: 2),
      ),
      child: card,
    );
  }
}
