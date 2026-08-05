import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../core/format.dart';
import '../../ui/main.dart';
import 'pro_bookings_controller.dart';

/// The referee's result entry for a lobby-vs-lobby challenge.
///
/// Deliberately the only writer of a scored challenge match: the DB constraint
/// `lobby_match_referee_required_for_scored_challenge` refuses a scoreline
/// without a referee booking, and a match played without one is instead logged
/// by the cron sweep as a scoreless encounter. Entry is final — recording moves
/// both lobbies' Elo and closes the booking — so there is no edit path here.
void showRecordResultSheet(
  BuildContext context, {
  required String professionalId,
  required RefereedMatch match,
}) {
  showPSheet(
    context: context,
    builder: (_) => _RecordResultSheet(
      professionalId: professionalId,
      match: match,
    ),
  );
}

class _RecordResultSheet extends ConsumerStatefulWidget {
  final String professionalId;
  final RefereedMatch match;

  const _RecordResultSheet({
    required this.professionalId,
    required this.match,
  });

  @override
  ConsumerState<_RecordResultSheet> createState() => _RecordResultSheetState();
}

class _RecordResultSheetState extends ConsumerState<_RecordResultSheet> {
  final _noteController = TextEditingController();
  final _sets = <(TextEditingController home, TextEditingController away)>[];

  @override
  void initState() {
    super.initState();
    _addSet();
  }

  @override
  void dispose() {
    _noteController.dispose();
    for (final s in _sets) {
      s.$1
        ..removeListener(_onScoreChanged)
        ..dispose();
      s.$2
        ..removeListener(_onScoreChanged)
        ..dispose();
    }
    super.dispose();
  }

  void _addSet() {
    // The result label below is derived from the scoreline, so every keystroke
    // has to rebuild — FTextField has no onChange, the controller is the hook.
    final home = TextEditingController()..addListener(_onScoreChanged);
    final away = TextEditingController()..addListener(_onScoreChanged);
    setState(() => _sets.add((home, away)));
  }

  void _onScoreChanged() {
    if (mounted) setState(() {});
  }

  void _removeSet(int i) {
    final s = _sets.removeAt(i);
    s.$1
      ..removeListener(_onScoreChanged)
      ..dispose();
    s.$2
      ..removeListener(_onScoreChanged)
      ..dispose();
    setState(() {});
  }

  /// Parsed sets, dropping rows the referee left blank.
  List<(int, int)> get _parsedSets => [
        for (final s in _sets)
          if (int.tryParse(s.$1.text.trim()) != null &&
              int.tryParse(s.$2.text.trim()) != null)
            (int.parse(s.$1.text.trim()), int.parse(s.$2.text.trim())),
      ];

  /// The result is derived from the scoreline rather than picked separately —
  /// two controls for one fact is how they end up disagreeing.
  String? get _derivedResult {
    final sets = _parsedSets;
    if (sets.isEmpty) return null;
    final home = sets.fold(0, (a, s) => a + s.$1);
    final away = sets.fold(0, (a, s) => a + s.$2);
    if (home > away) return 'win';
    if (home < away) return 'loss';
    return 'draw';
  }

  void _toast(String message, {bool bad = true}) {
    showFToast(
      context: context,
      icon: Icon(bad ? FLucideIcons.circleX : FLucideIcons.flag),
      variant: bad ? FToastVariant.destructive : FToastVariant.primary,
      title: Text(message),
      alignment: .bottomCenter,
    );
  }

  Future<void> _submit() async {
    final result = _derivedResult;
    if (result == null) return _toast('Nhập ít nhất một hiệp có tỉ số');

    try {
      final note = _noteController.text.trim();
      await ref
          .read(recordChallengeResultControllerProvider(widget.professionalId)
              .notifier)
          .record(
            challengeId: widget.match.challengeId,
            result: result,
            sets: _parsedSets,
            note: note.isEmpty ? null : note,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      _toast('Đã ghi kết quả', bad: false);
    } catch (e, st) {
      Talker().handle(e, st, 'record challenge result failed');
      if (!mounted) return;
      _toast(recordResultErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final busy =
        ref.watch(recordChallengeResultControllerProvider(widget.professionalId));
    final match = widget.match;
    final result = _derivedResult;

    return SingleChildScrollView(
      primary: false,
      child: Column(
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PSheetTitle(
            label: 'Ghi Kết Quả',
            trailing: FButton.icon(
              variant: .ghost,
              onPress: () => Navigator.of(context).pop(),
              child: const Icon(FLucideIcons.x),
            ),
          ),

          // Home vs away header. Both names are user-supplied, so each gets
          // half the row and ellipsizes rather than pushing the other out.
          Row(
            children: [
              Expanded(
                child: _TeamLabel(
                  name: match.homeLobbyName,
                  caption: 'Chủ nhà',
                  align: TextAlign.left,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'vs',
                  style: context.theme.typography.body.xs
                      .copyWith(color: colors.mutedForeground),
                ),
              ),
              Expanded(
                child: _TeamLabel(
                  name: match.awayLobbyName,
                  caption: 'Khách',
                  align: TextAlign.right,
                ),
              ),
            ],
          ),

          if (match.activityEnd != null)
            Text(
              formatMatchDateTime(match.activityEnd!),
              textAlign: TextAlign.center,
              style: context.theme.typography.body.xs
                  .copyWith(color: colors.mutedForeground),
            ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              for (var i = 0; i < _sets.length; i++)
                Row(
                  children: [
                    SizedBox(
                      width: 52,
                      child: Text(
                        'Hiệp ${i + 1}',
                        style: context.theme.typography.body.xs
                            .copyWith(color: colors.mutedForeground),
                      ),
                    ),
                    Expanded(
                      child: FTextField(
                        hint: 'Chủ nhà',
                        keyboardType: TextInputType.number,
                        control: FTextFieldControl.managed(
                          controller: _sets[i].$1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FTextField(
                        hint: 'Khách',
                        keyboardType: TextInputType.number,
                        control: FTextFieldControl.managed(
                          controller: _sets[i].$2,
                        ),
                      ),
                    ),
                    if (_sets.length > 1)
                      FButton.icon(
                        variant: .ghost,
                        onPress: () => _removeSet(i),
                        child: const Icon(FLucideIcons.x, size: 16),
                      ),
                  ],
                ),
              FButton(
                variant: .outline,
                onPress: _addSet,
                child: const Text('Thêm hiệp'),
              ),
            ],
          ),

          // Derived, not chosen — shown so the referee can sanity-check the
          // scoreline they typed before it becomes final.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colors.secondary.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(FLucideIcons.flag, size: 16, color: colors.mutedForeground),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    switch (result) {
                      'win' => '${match.homeLobbyName} thắng',
                      'loss' => '${match.awayLobbyName} thắng',
                      'draw' => 'Hoà',
                      _ => 'Nhập tỉ số để xác định kết quả',
                    },
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.theme.typography.body.sm.copyWith(
                      fontWeight: FontWeight.w700,
                      color: result == null
                          ? colors.mutedForeground
                          : colors.foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),

          FTextField(
            label: const Text('Ghi chú (tuỳ chọn)'),
            maxLines: 2,
            control: FTextFieldControl.managed(controller: _noteController),
          ),

          Text(
            'Kết quả do trọng tài ghi là kết quả cuối cùng và sẽ cập nhật '
            'điểm MMR của cả hai đội.',
            style: context.theme.typography.body.xs
                .copyWith(color: colors.mutedForeground, height: 1.45),
          ),

          FButton(
            onPress: (busy || result == null) ? null : _submit,
            child: busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Ghi Kết Quả'),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _TeamLabel extends StatelessWidget {
  final String name;
  final String caption;
  final TextAlign align;

  const _TeamLabel({
    required this.name,
    required this.caption,
    required this.align,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Column(
      crossAxisAlignment: align == TextAlign.left
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          textAlign: align,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.theme.typography.body.sm
              .copyWith(fontWeight: FontWeight.w700),
        ),
        Text(
          caption,
          style: context.theme.typography.body.xs
              .copyWith(color: colors.mutedForeground),
        ),
      ],
    );
  }
}
