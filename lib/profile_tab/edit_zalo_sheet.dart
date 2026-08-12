import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../ui/main.dart';
import 'user_contact_controller.dart';

void showEditZaloSheet(BuildContext context, String? zalo) {
  showPSheet(
    context: context,
    builder: (_) => _EditZaloSheet(zalo: zalo),
  );
}

class _EditZaloSheet extends ConsumerStatefulWidget {
  final String? zalo;
  const _EditZaloSheet({required this.zalo});

  @override
  ConsumerState<_EditZaloSheet> createState() => _EditZaloSheetState();
}

class _EditZaloSheetState extends ConsumerState<_EditZaloSheet> {
  late final _controller = TextEditingController(text: widget.zalo ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final value = _controller.text.trim();
    try {
      await ref
          .read(userContactControllerProvider.notifier)
          .setZalo(value.isEmpty ? null : value);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.circleX),
          variant: .destructive,
          title: Text('error'.tr()),
          description: Text('errorGeneric'.tr()),
          alignment: .bottomCenter,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      PSheetTitle(
        label: 'profile.zalo'.tr(),
        trailing: FButton.icon(
          variant: .ghost,
          onPress: () => Navigator.pop(context),
          child: const Icon(FLucideIcons.x),
        ),
      ),
      const SizedBox(height: 12),
      FTextField(
        control: FTextFieldControl.managed(controller: _controller),
        hint: 'profile.zaloHint'.tr(),
        keyboardType: TextInputType.phone,
      ),
      const SizedBox(height: 16),
      FButton(
        onPress: _saving ? null : _save,
        child: _saving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text('done'.tr()),
      ),
    ],
  );
}
