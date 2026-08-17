import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../core/model/user_contact.dart';
import '../ui/main.dart';
import 'user_contact_controller.dart';

void showEditZaloSheet(BuildContext context, UserContact contact) {
  showPSheet(
    context: context,
    builder: (_) => _EditZaloSheet(contact: contact),
  );
}

class _EditZaloSheet extends ConsumerStatefulWidget {
  final UserContact contact;
  const _EditZaloSheet({required this.contact});

  @override
  ConsumerState<_EditZaloSheet> createState() => _EditZaloSheetState();
}

class _EditZaloSheetState extends ConsumerState<_EditZaloSheet> {
  late final _controller = TextEditingController(
    text: widget.contact.zalo ?? '',
  );
  late bool _public = widget.contact.zaloPublic;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final value = _controller.text.trim();
    ref
        .read(userContactControllerProvider.notifier)
        .save(
          UserContact(zalo: value.isEmpty ? null : value, zaloPublic: _public),
        );
    Navigator.of(context).pop();
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
      const SizedBox(height: 12),
      Text(
        'profile.zaloPrivacyDisclaimer'.tr(),
        style: context.theme.typography.body.sm.copyWith(
          color: context.theme.colors.mutedForeground,
        ),
      ),
      const SizedBox(height: 8),
      FTile(
        prefix: const Icon(FLucideIcons.globe),
        title: Text('profile.zaloMakePublic'.tr()),
        details: FSwitch(
          value: _public,
          onChange: (v) => setState(() => _public = v),
        ),
      ),
      const SizedBox(height: 16),
      FButton(onPress: _save, child: Text('done'.tr())),
    ],
  );
}
