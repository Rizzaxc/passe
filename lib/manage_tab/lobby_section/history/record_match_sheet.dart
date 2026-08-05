import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../../ui/main.dart';
import '../lobby_detail_controller.dart';
import '../members/controller.dart';
import 'match.dart';
import 'record_match_controller.dart';

void showRecordMatchSheet(BuildContext context, String lobbyId) {
  showPSheet(
    context: context,
    builder: (_) => _RecordMatchSheet(lobbyId: lobbyId),
  );
}

class _RecordMatchSheet extends ConsumerStatefulWidget {
  final String lobbyId;
  const _RecordMatchSheet({required this.lobbyId});

  @override
  ConsumerState<_RecordMatchSheet> createState() => _RecordMatchSheetState();
}

class _RecordMatchSheetState extends ConsumerState<_RecordMatchSheet> {
  LobbyMatchResult _result = LobbyMatchResult.win;
  final _opponentController = TextEditingController();
  final _venueController = TextEditingController();
  final _noteController = TextEditingController();
  final List<(TextEditingController, TextEditingController)> _sets = [];
  String? _mvpUserId;
  bool _venueSeeded = false;

  @override
  void initState() {
    super.initState();
    _addSet();
  }

  @override
  void dispose() {
    _opponentController.dispose();
    _venueController.dispose();
    _noteController.dispose();
    for (final s in _sets) {
      s.$1.dispose();
      s.$2.dispose();
    }
    super.dispose();
  }

  void _addSet() {
    if (_sets.length >= 7) return;
    setState(() => _sets.add((TextEditingController(), TextEditingController())));
  }

  void _removeSet(int i) {
    setState(() {
      _sets[i].$1.dispose();
      _sets[i].$2.dispose();
      _sets.removeAt(i);
    });
  }

  bool get _isPractice => _result == LobbyMatchResult.practice;

  Future<void> _submit() async {
    final venue = _venueController.text.trim();
    if (venue.isEmpty) {
      _toast('manageTab.recordMatch.venueRequired'.tr(), destructive: true);
      return;
    }

    // Parse sets (only for decisive results). Skip blank rows.
    List<(int, int)>? sets;
    if (!_isPractice) {
      final parsed = <(int, int)>[];
      for (final s in _sets) {
        final us = s.$1.text.trim();
        final them = s.$2.text.trim();
        if (us.isEmpty && them.isEmpty) continue;
        final u = int.tryParse(us);
        final t = int.tryParse(them);
        if (u == null || t == null) {
          _toast('manageTab.recordMatch.setsInvalid'.tr(), destructive: true);
          return;
        }
        parsed.add((u, t));
      }
      if (parsed.isNotEmpty) sets = parsed;
    }

    try {
      await ref.read(recordMatchControllerProvider(widget.lobbyId).notifier).record(
            lobbyId: widget.lobbyId,
            result: _result,
            opponentName: _isPractice ? null : _opponentController.text,
            sets: sets,
            mvpUserId: _mvpUserId,
            venue: venue,
            note: _noteController.text,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      _toast('manageTab.recordMatch.success'.tr());
    } catch (e, st) {
      Talker().handle(e, st, 'record match failed');
      if (!mounted) return;
      _toast('errorGeneric'.tr(), destructive: true);
    }
  }

  void _toast(String msg, {bool destructive = false}) {
    showFToast(
      context: context,
      icon: Icon(destructive ? FLucideIcons.circleX : FLucideIcons.check),
      variant: destructive ? FToastVariant.destructive : FToastVariant.primary,
      title: Text(msg),
      alignment: FToastAlignment.bottomCenter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final busy = ref.watch(recordMatchControllerProvider(widget.lobbyId));
    final members =
        ref.watch(lobbyMembersControllerProvider(widget.lobbyId)).value ??
            const [];

    // Seed the venue with the homeground once, without clobbering edits.
    final homeground =
        ref.watch(lobbyDetailControllerProvider(widget.lobbyId)).value?.homeGroundName;
    if (!_venueSeeded && homeground != null && homeground.isNotEmpty) {
      _venueController.text = homeground;
      _venueSeeded = true;
    }

    return SingleChildScrollView(
      primary: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          PSheetTitle(
            label: 'manageTab.recordMatch.title'.tr(),
            trailing: FButton.icon(
              variant: .ghost,
              onPress: () => Navigator.of(context).pop(),
              child: const Icon(FLucideIcons.x),
            ),
          ),

          // Result
          PSegmentedButton<LobbyMatchResult>(
            values: LobbyMatchResult.values,
            selected: _result,
            format: (v) => Text(switch (v) {
              LobbyMatchResult.win => 'manageTab.recordMatch.win'.tr(),
              LobbyMatchResult.loss => 'manageTab.recordMatch.loss'.tr(),
              LobbyMatchResult.draw => 'manageTab.recordMatch.draw'.tr(),
              LobbyMatchResult.practice =>
                'manageTab.recordMatch.practice'.tr(),
            }),
            onChange: (v) {
              if (v == null) return;
              setState(() => _result = v);
            },
          ),

          if (!_isPractice) ...[
            FTextField(
              label: Text('manageTab.recordMatch.opponent'.tr()),
              hint: 'manageTab.recordMatch.opponentHint'.tr(),
              control: FTextFieldControl.managed(controller: _opponentController),
            ),

            // Sets editor
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text('manageTab.recordMatch.sets'.tr(),
                    style: context.theme.typography.body.sm
                        .copyWith(fontWeight: FontWeight.w600)),
                for (var i = 0; i < _sets.length; i++)
                  Row(
                    spacing: 8,
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text('${i + 1}.',
                            style: TextStyle(color: colors.mutedForeground)),
                      ),
                      Expanded(child: _SetField(controller: _sets[i].$1)),
                      Text('–', style: TextStyle(color: colors.mutedForeground)),
                      Expanded(child: _SetField(controller: _sets[i].$2)),
                      FButton.icon(
                        variant: .ghost,
                        onPress: _sets.length > 1 ? () => _removeSet(i) : null,
                        child: Icon(FLucideIcons.minus,
                            size: 16, color: colors.mutedForeground),
                      ),
                    ],
                  ),
                FButton(
                  variant: .outline,
                  onPress: _sets.length < 7 ? _addSet : null,
                  prefix: const Icon(FLucideIcons.plus, size: 14),
                  child: Text('manageTab.recordMatch.addSet'.tr()),
                ),
              ],
            ),
          ],

          // MVP picker
          if (members.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text('manageTab.recordMatch.mvp'.tr(),
                    style: context.theme.typography.body.sm
                        .copyWith(fontWeight: FontWeight.w600)),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final m in members)
                      _MemberChip(
                        label: m.username,
                        selected: _mvpUserId == m.userId,
                        onTap: () => setState(() => _mvpUserId =
                            _mvpUserId == m.userId ? null : m.userId),
                      ),
                  ],
                ),
              ],
            ),

          // Venue
          FTextField(
            label: Text('manageTab.recordMatch.venue'.tr()),
            hint: 'manageTab.recordMatch.venueHint'.tr(),
            control: FTextFieldControl.managed(controller: _venueController),
          ),

          // Note
          FTextField(
            label: Text('manageTab.recordMatch.note'.tr()),
            hint: 'manageTab.recordMatch.noteHint'.tr(),
            maxLines: 2,
            control: FTextFieldControl.managed(controller: _noteController),
          ),

          FButton(
            onPress: busy ? null : _submit,
            child: busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text('manageTab.recordMatch.submit'.tr()),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SetField extends StatelessWidget {
  final TextEditingController controller;
  const _SetField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return FTextField(
      control: FTextFieldControl.managed(controller: controller),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textAlign: TextAlign.center,
      hint: '0',
    );
  }
}

class _MemberChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MemberChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.secondary,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            if (selected)
              Icon(Icons.star_rounded,
                  size: 13, color: colors.primaryForeground),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? colors.primaryForeground
                    : colors.secondaryForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
