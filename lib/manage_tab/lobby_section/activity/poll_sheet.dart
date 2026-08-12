// Captain-only "create a poll" sheet — posts a lobby_feed_item(kind: 'poll').
// RLS ("Captain can post updates and polls") enforces the captain-only part
// server-side too; the picker already only shows this tile to the captain.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../../auth/auth_controller.dart';
import '../../../ui/sheet.dart';
import '../members/controller.dart';
import 'feed_controller.dart';

void showCreatePollSheet(BuildContext context, String lobbyId) {
  showPSheet(
    context: context,
    builder: (_) => _CreatePollSheet(lobbyId: lobbyId),
  );
}

class _CreatePollSheet extends ConsumerStatefulWidget {
  final String lobbyId;
  const _CreatePollSheet({required this.lobbyId});

  @override
  ConsumerState<_CreatePollSheet> createState() => _CreatePollSheetState();
}

class _CreatePollSheetState extends ConsumerState<_CreatePollSheet> {
  static const _maxOptions = 4;
  static const _minOptions = 2;

  final _questionController = TextEditingController();
  final _optionControllers = <TextEditingController>[
    TextEditingController(),
    TextEditingController(),
  ];
  bool _saving = false;

  @override
  void dispose() {
    _questionController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length >= _maxOptions) return;
    setState(() => _optionControllers.add(TextEditingController()));
  }

  void _removeOption(int i) {
    if (_optionControllers.length <= _minOptions) return;
    setState(() => _optionControllers.removeAt(i).dispose());
  }

  Future<void> _submit() async {
    final question = _questionController.text.trim();
    final options = _optionControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (question.isEmpty || options.length < _minOptions) {
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleAlert),
        variant: .destructive,
        title: Text('lobbyHub.poll.validation'.tr()),
        alignment: .bottomCenter,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;

      // Best-effort member count for the "x/N đã bình chọn" footer —
      // falls back to the option count's own vote total if the roster
      // hasn't loaded, since the CHECK constraint only requires the key
      // to be present, not accurate.
      final members = ref
          .read(lobbyMembersControllerProvider(widget.lobbyId))
          .value;
      final totalMembers = members?.length ?? options.length;

      await Supabase.instance.client
          .from('lobby_feed_item')
          .insert({
            'lobby_id': widget.lobbyId,
            'author_id': userId,
            'kind': 'poll',
            'payload': {
              'question': question,
              'options': [
                for (final label in options) {'label': label},
              ],
              'total_members': totalMembers,
              // No real poll-deadline scheduling yet — fixed copy, tweak
              // later if that becomes a real field.
              'deadline': 'lobbyHub.poll.deadline'.tr(),
            },
          })
          .timeout(const Duration(seconds: 5));

      ref.invalidate(lobbyFeedControllerProvider(widget.lobbyId));
      if (!mounted) return;
      Navigator.of(context).pop();
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.check),
        title: Text('lobbyHub.poll.created'.tr()),
        alignment: .bottomCenter,
      );
    } catch (e, st) {
      Talker().handle(e, st, 'Create poll failed');
      if (mounted) {
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.circleX),
          variant: .destructive,
          title: Text('lobbyHub.poll.failed'.tr()),
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
      child: Column(
        spacing: 14,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PSheetTitle(
            label: 'lobbyHub.poll.title'.tr(),
            trailing: FButton.icon(
              variant: .ghost,
              onPress: () => Navigator.of(context).pop(),
              child: const Icon(FLucideIcons.x),
            ),
          ),
          FTextField(
            label: Text('lobbyHub.poll.question'.tr()),
            hint: 'lobbyHub.poll.questionHint'.tr(),
            control: FTextFieldControl.managed(controller: _questionController),
          ),
          for (var i = 0; i < _optionControllers.length; i++)
            Row(
              children: [
                Expanded(
                  child: FTextField(
                    label: Text(
                      'lobbyHub.poll.option'.tr(
                        namedArgs: {'number': '${i + 1}'},
                      ),
                    ),
                    control: FTextFieldControl.managed(
                      controller: _optionControllers[i],
                    ),
                  ),
                ),
                if (_optionControllers.length > _minOptions)
                  FButton.icon(
                    variant: .ghost,
                    onPress: () => _removeOption(i),
                    child: const Icon(FLucideIcons.x, size: 16),
                  ),
              ],
            ),
          if (_optionControllers.length < _maxOptions)
            FButton(
              variant: .outline,
              onPress: _addOption,
              child: Text('lobbyHub.poll.addOption'.tr()),
            ),
          FButton(
            onPress: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('lobbyHub.poll.submit'.tr()),
          ),
        ],
      ),
    );
  }
}
