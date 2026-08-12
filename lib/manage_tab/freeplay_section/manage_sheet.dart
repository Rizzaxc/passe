import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../freeplay/model.dart';
import '../../freeplay/repository.dart';
import '../../ui/main.dart';

Future<void> showManageFreeplaySheet(
  BuildContext context,
  FreeplayActivity activity,
) => showPSheet(
  context: context,
  maxHeightRatio: 1,
  builder: (_) => _ManageFreeplay(activity: activity),
);

class _ManageFreeplay extends ConsumerStatefulWidget {
  final FreeplayActivity activity;
  const _ManageFreeplay({required this.activity});

  @override
  ConsumerState<_ManageFreeplay> createState() => _ManageFreeplayState();
}

class _ManageFreeplayState extends ConsumerState<_ManageFreeplay> {
  late final TextEditingController _capacity = TextEditingController(
    text: widget.activity.capacity.toString(),
  );
  late final TextEditingController _description = TextEditingController(
    text: widget.activity.description,
  );
  late final Set<String> _skills = widget.activity.recommendedSkills.toSet();
  bool _busy = false;

  @override
  void dispose() {
    _capacity.dispose();
    _description.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(hostFreeplayProvider(false));
    ref.invalidate(freeplayDetailProvider(widget.activity.id));
  }

  Future<void> _save() async {
    final capacity = int.tryParse(_capacity.text);
    if (capacity == null ||
        capacity < widget.activity.capacity ||
        _skills.isEmpty) {
      showFToast(
        context: context,
        variant: .destructive,
        title: Text('freeplay.hostManage.capacityCanOnlyIncrease'.tr()),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(freeplayRepositoryProvider)
          .update(
            widget.activity.id,
            capacity: capacity,
            description: _description.text.trim(),
            skills: _skills.toList(),
          );
      _refresh();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        showFToast(
          context: context,
          variant: .destructive,
          title: Text('freeplay.hostManage.updateFailed'.tr()),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        PSheetTitle(
          label: 'freeplay.hostManage.manageTitle'.tr(),
          trailing: FButton.icon(
            variant: .ghost,
            onPress: () => Navigator.pop(context),
            child: const Icon(FLucideIcons.x),
          ),
        ),
        FTextField(
          label: Text('freeplay.hostManage.capacity'.tr()),
          keyboardType: TextInputType.number,
          control: FTextFieldControl.managed(controller: _capacity),
        ),
        FTextField(
          label: Text('freeplay.hostManage.description'.tr()),
          maxLines: 5,
          control: FTextFieldControl.managed(controller: _description),
        ),
        PSheetSectionLabel(label: 'freeplay.hostManage.recommendedSkill'.tr()),
        for (final value in const ['beginner', 'casual', 'fair', 'good', 'advanced'])
          FCheckbox(
            value: _skills.contains(value),
            label: Text('freeplay.skill.$value'.tr()),
            onChange: (selected) => setState(() {
              if (selected) {
                _skills.add(value);
              } else if (_skills.length > 1) {
                _skills.remove(value);
              }
            }),
          ),
        FButton(
          onPress: _busy ? null : _save,
          child: Text('freeplay.hostManage.saveChanges'.tr()),
        ),
        FButton(
          variant: .outline,
          onPress:
              _busy ||
                  (widget.activity.intakeClosed &&
                      !DateTime.now().isBefore(widget.activity.startTime))
              ? null
              : () async {
                  setState(() => _busy = true);
                  try {
                    await ref
                        .read(freeplayRepositoryProvider)
                        .setIntake(
                          widget.activity.id,
                          !widget.activity.intakeClosed,
                        );
                    _refresh();
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  } finally {
                    if (mounted) setState(() => _busy = false);
                  }
                },
          child: Text(
            widget.activity.intakeClosed
                ? 'freeplay.hostManage.openIntake'.tr()
                : 'freeplay.hostManage.closeIntake'.tr(),
          ),
        ),
        FButton(
          variant: .destructive,
          onPress: _busy
              ? null
              : () async {
                  final confirmed = await showFDialog<bool>(
                    context: context,
                    builder: (dialogContext, style, animation) =>
                        PConfirmDialog(
                          animation: animation,
                          title: Text(
                            'freeplay.hostManage.cancelConfirmTitle'.tr(),
                          ),
                          body: Text(
                            'freeplay.hostManage.cancelConfirmBody'.tr(),
                          ),
                          actions: [
                            FButton(
                              variant: .ghost,
                              onPress: () =>
                                  Navigator.pop(dialogContext, false),
                              child: Text('freeplay.hostManage.keep'.tr()),
                            ),
                            FButton(
                              variant: .destructive,
                              onPress: () => Navigator.pop(dialogContext, true),
                              child: Text('freeplay.hostManage.cancel'.tr()),
                            ),
                          ],
                        ),
                  );
                  if (confirmed != true) return;
                  setState(() => _busy = true);
                  try {
                    await ref
                        .read(freeplayRepositoryProvider)
                        .cancelActivity(widget.activity.id);
                    _refresh();
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  } finally {
                    if (mounted) setState(() => _busy = false);
                  }
                },
          child: Text('freeplay.hostManage.cancel'.tr()),
        ),
      ],
    ),
  );
}
