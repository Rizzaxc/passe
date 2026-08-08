// "Đòi tiền trà đá" — any confirmed (going) attendee of a session can start
// an ancillary payment request against tagged lobby mates. Candidate/tag
// data reuses the wall composer's taggable-users infra (attendees + lobby
// members, attendees first) — same shape, different destination.
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../../feed_tab/compose_controller.dart';
import '../../../ui/main.dart';
import 'feed_controller.dart';

void showPaymentRequestSheet(
  BuildContext context, {
  required String lobbyId,
  required String activityId,
}) {
  showPSheet(
    context: context,
    maxHeightRatio: 1.0,
    builder: (_) => _PaymentRequestSheet(lobbyId: lobbyId, activityId: activityId),
  );
}

class _PaymentRequestSheet extends ConsumerStatefulWidget {
  final String lobbyId;
  final String activityId;
  const _PaymentRequestSheet({required this.lobbyId, required this.activityId});

  @override
  ConsumerState<_PaymentRequestSheet> createState() => _PaymentRequestSheetState();
}

class _PaymentRequestSheetState extends ConsumerState<_PaymentRequestSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController(text: 'Trà đá');
  Set<String>? _selected; // null until candidates load, then seeded to attendees
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _seedIfNeeded(List<TaggableUser> candidates) {
    if (_selected != null) return;
    _selected = {for (final c in candidates.where((c) => c.attended)) c.userId};
  }

  Future<void> _submit() async {
    final amount = num.tryParse(_amountController.text.trim());
    final tagged = _selected ?? const <String>{};
    if (amount == null || amount <= 0) {
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleAlert),
        variant: .destructive,
        title: const Text('Số tiền không hợp lệ'),
        alignment: .bottomCenter,
      );
      return;
    }
    if (tagged.isEmpty) {
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleAlert),
        variant: .destructive,
        title: const Text('Chọn ít nhất một người'),
        alignment: .bottomCenter,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final note = _noteController.text.trim();
      await ref
          .read(lobbyFeedControllerProvider(widget.lobbyId).notifier)
          .createAncillaryPaymentRequest(
            activityId: widget.activityId,
            amount: amount,
            note: note.isEmpty ? null : note,
            taggedUserIds: tagged.toList(),
          );

      if (!mounted) return;
      Navigator.of(context).pop();
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.check),
        title: const Text('Đã gửi yêu cầu thanh toán'),
        alignment: .bottomCenter,
      );
    } catch (e, st) {
      Talker().handle(e, st, 'Create ancillary payment request failed');
      if (mounted) {
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.circleX),
          variant: .destructive,
          title: const Text('Không thể gửi yêu cầu'),
          alignment: .bottomCenter,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final candidatesAsync =
        ref.watch(taggableUsersProvider(activityId: widget.activityId));

    return SingleChildScrollView(
      primary: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          PSheetTitle(
            label: 'Đòi Tiền Trà Đá',
            trailing: FButton.icon(
              variant: .ghost,
              onPress: () => Navigator.of(context).pop(),
              child: const Icon(FLucideIcons.x),
            ),
          ),
          FTextField(
            label: const Text('Số tiền'),
            hint: '50000?',
            control: FTextFieldControl.managed(controller: _amountController),
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
          ),
          FTextField(
            label: const Text('Ghi chú'),
            hint: 'Trà đá',
            control: FTextFieldControl.managed(controller: _noteController),
          ),
          PSheetSectionLabel(label: 'Chia cho'),
          candidatesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) =>
                const PEmptySectionPlaceholder(subtitle: 'Không tải được danh sách'),
            data: (candidates) {
              _seedIfNeeded(candidates);
              if (candidates.isEmpty) {
                return const PEmptySectionPlaceholder(subtitle: 'Không có ai để chọn');
              }
              final selected = _selected ?? const <String>{};
              final perPerson = selected.isEmpty
                  ? null
                  : num.tryParse(_amountController.text.trim());
              return Column(
                children: [
                  for (final c in candidates)
                    FTile(
                      prefix: PUserAvatar(
                        userId: c.userId,
                        username: c.username,
                        generatedAvatar: c.generatedAvatar,
                        radius: 16,
                      ),
                      title: Text(
                        c.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(c.attended ? 'Đã tham gia' : 'Thành viên lobby'),
                      suffix: selected.contains(c.userId)
                          ? Icon(FLucideIcons.circleCheck,
                              color: context.theme.colors.primary)
                          : const Icon(FLucideIcons.circle),
                      onPress: () => setState(() {
                        final next = {...selected};
                        if (next.contains(c.userId)) {
                          next.remove(c.userId);
                        } else {
                          next.add(c.userId);
                        }
                        _selected = next;
                      }),
                    ),
                  if (perPerson != null && selected.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Mỗi người khoảng ${(perPerson / selected.length).ceil()}đ '
                      '(làm tròn đến 1.000đ)',
                      style: context.theme.typography.body.xs.copyWith(
                        color: context.theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          FButton(
            onPress: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Gửi Yêu Cầu'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
