import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../../ui/main.dart';
import 'feed_controller.dart';

void showActivityNoteSheet(
  BuildContext context, {
  required String lobbyId,
  required String activityId,
}) {
  showPSheet(
    context: context,
    builder: (_) =>
        _ActivityNoteSheet(lobbyId: lobbyId, activityId: activityId),
  );
}

class _ActivityNoteSheet extends ConsumerStatefulWidget {
  final String lobbyId;
  final String activityId;

  const _ActivityNoteSheet({required this.lobbyId, required this.activityId});

  @override
  ConsumerState<_ActivityNoteSheet> createState() => _ActivityNoteSheetState();
}

class _ActivityNoteSheetState extends ConsumerState<_ActivityNoteSheet> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    String note;
    try {
      note = normalizeActivityNote(_controller.text);
    } on ArgumentError {
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleAlert),
        variant: .destructive,
        title: const Text('Ghi chú phải có từ 1–72 ký tự'),
        alignment: .bottomCenter,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(lobbyFeedControllerProvider(widget.lobbyId).notifier)
          .postActivityNote(activityId: widget.activityId, note: note);

      if (!mounted) return;
      Navigator.of(context).pop();
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.check),
        title: const Text('Đã thêm ghi chú'),
        alignment: .bottomCenter,
      );
    } on AlreadyPostedActivityNoteException {
      if (mounted) {
        Navigator.of(context).pop();
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.circleCheck),
          title: const Text('Bạn đã ghi chú cho buổi này rồi'),
          alignment: .bottomCenter,
        );
      }
    } catch (e, st) {
      Talker().handle(e, st, 'Post activity note failed');
      if (mounted) {
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.circleX),
          variant: .destructive,
          title: const Text('Không thể thêm ghi chú'),
          alignment: .bottomCenter,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      primary: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          PSheetTitle(
            label: 'Ghi Chú Buổi Chơi',
            trailing: FButton.icon(
              variant: .ghost,
              onPress: () => Navigator.of(context).pop(),
              child: const Icon(FLucideIcons.x),
            ),
          ),
          FTextField(
            label: const Text('Ghi chú'),
            hint: 'Nhắn mọi người về buổi chơi…',
            maxLines: 3,
            maxLength: maxActivityNoteLength,
            autofocus: true,
            control: FTextFieldControl.managed(controller: _controller),
            textInputAction: TextInputAction.done,
            onSubmit: (_) => _saving ? null : _submit(),
          ),
          FButton(
            onPress: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Đăng Ghi Chú'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
