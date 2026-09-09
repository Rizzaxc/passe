import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/model/challenge.dart';
import '../../../logger/talker.dart';
import '../../../ui/main.dart';
import 'friendly_challenge_controller.dart';

/// The blind result ballot.
///
/// Both lobbies file independently and neither sees the other until the match
/// resolves — enforced by RLS on `lobby_challenge_report`, not by this sheet.
/// But blind is a guarantee about the APP, not advice about the evening: this
/// screen actively tells the reporter to settle the result with the opponent
/// on the pitch first, because most of these formats need on-site bookkeeping
/// that gets fuzzy, and two teams agreeing to call it a draw is a legitimate
/// answer rather than a cop-out.
///
/// Everything is phrased from the reporter's OWN side ("đội mình thắng"), never
/// as home/away — the away team must never be asked whether *home* won. The
/// perspective conversion happens at the RPC boundary.
void showReportResultSheet(
  BuildContext context, {
  required String lobbyId,
  required FriendlyChallenge challenge,
}) {
  showPSheet(
    context: context,
    maxHeightRatio: 1.0,
    builder: (_) => _ReportResultSheet(lobbyId: lobbyId, challenge: challenge),
  );
}

class _ReportResultSheet extends ConsumerStatefulWidget {
  final String lobbyId;
  final FriendlyChallenge challenge;

  const _ReportResultSheet({required this.lobbyId, required this.challenge});

  @override
  ConsumerState<_ReportResultSheet> createState() => _ReportResultSheetState();
}

class _ReportResultSheetState extends ConsumerState<_ReportResultSheet> {
  MatchOutcome? _outcome;
  final _note = TextEditingController();

  /// `[us, them]` per set — our own score first, matching what a manager
  /// actually types. The RPC flips it for the away side, since sets are stored
  /// home-first on disk.
  final List<(TextEditingController, TextEditingController)> _sets = [];

  @override
  void initState() {
    super.initState();
    // Editing a report you already filed is allowed while the match is still
    // awaiting the opponent, so seed the form from it.
    _outcome = widget.challenge.myOutcome;
    if (_showSets) _addSet();
  }

  @override
  void dispose() {
    _note.dispose();
    for (final (a, b) in _sets) {
      a.dispose();
      b.dispose();
    }
    super.dispose();
  }

  bool get _showSets =>
      widget.challenge.ruleset.hasSets && !(_outcome?.isForfeit ?? false);

  void _addSet() =>
      _sets.add((TextEditingController(), TextEditingController()));

  List<List<int>>? _collectSets() {
    if (!_showSets) return null;
    final out = <List<int>>[];
    for (final (a, b) in _sets) {
      final us = int.tryParse(a.text.trim());
      final them = int.tryParse(b.text.trim());
      if (us == null || them == null) continue;
      out.add([us, them]);
    }
    return out.isEmpty ? null : out;
  }

  Future<void> _submit() async {
    final outcome = _outcome;
    if (outcome == null) return;
    try {
      final result = await ref
          .read(reportMatchResultControllerProvider(widget.lobbyId).notifier)
          .report(
            challengeId: widget.challenge.id,
            outcome: outcome,
            sets: _collectSets(),
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      showFToast(
        context: context,
        icon: Icon(
          result == 'disputed'
              ? FLucideIcons.triangleAlert
              : FLucideIcons.check,
        ),
        variant: result == 'disputed' ? .destructive : .primary,
        title: Text('challenge.report.outcome.$result'.tr()),
        alignment: .bottomCenter,
      );
    } catch (e, st) {
      talker.handle(e, st);
      if (!mounted) return;
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleX),
        variant: .destructive,
        title: Text(reportResultErrorMessage(e)),
        alignment: .bottomCenter,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.challenge;
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final busy = ref.watch(reportMatchResultControllerProvider(widget.lobbyId));

    return SingleChildScrollView(
      primary: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          PSheetTitle(
            label: 'challenge.report.title'.tr(),
            trailing: FButton.icon(
              variant: .ghost,
              onPress: () => Navigator.of(context).pop(),
              child: const Icon(FLucideIcons.x),
            ),
          ),

          // Which match, in one line.
          Text(
            'challenge.report.context'.tr(
              namedArgs: {
                'opponent': c.otherLobbyName,
                'when': c.proposedTime == null
                    ? '—'
                    : formatMatchDateTime(c.proposedTime!),
              },
            ),
            style: typography.body.sm.copyWith(color: colors.mutedForeground),
          ),

          // What was actually being counted. Recapped because "who won" is
          // only answerable against the format both sides agreed to — and for
          // king-of-the-hill or a team tie, that is not self-evident.
          _FormatRecap(challenge: c),

          // The honesty framing, before any input.
          _Callout(
            icon: FLucideIcons.messagesSquare,
            tone: colors.primary,
            title: 'challenge.report.agreeFirstTitle'.tr(),
            body: 'challenge.report.agreeFirstBody'.tr(),
          ),

          PSheetSectionLabel(label: 'challenge.report.outcomeLabel'.tr()),
          for (final o in MatchOutcome.values)
            _OutcomeTile(
              outcome: o,
              selected: _outcome == o,
              onTap: () => setState(() {
                _outcome = o;
                if (_showSets && _sets.isEmpty) _addSet();
              }),
            ),

          if (_showSets) ...[
            PSheetSectionLabel(label: 'challenge.report.setsLabel'.tr()),
            for (var i = 0; i < _sets.length; i++)
              _SetRow(index: i, controllers: _sets[i]),
            FButton(
              variant: .secondary,
              onPress: _sets.length >= 7
                  ? null
                  : () => setState(_addSet),
              prefix: const Icon(FLucideIcons.plus),
              child: Text('challenge.report.addSet'.tr()),
            ),
          ],

          FTextField.multiline(
            label: Text('challenge.report.noteLabel'.tr()),
            hint: 'challenge.report.noteHint'.tr(),
            control: FTextFieldControl.managed(controller: _note),
            maxLines: 3,
          ),

          // The cost, named on the screen where it is incurred. A penalty that
          // hits BOTH teams — including one that did nothing wrong — is only
          // defensible if nobody meets it as a surprise.
          _Callout(
            icon: FLucideIcons.triangleAlert,
            tone: colors.destructive,
            title: 'challenge.report.consequenceTitle'.tr(),
            body: 'challenge.report.consequenceBody'.tr(),
          ),

          // Why they cannot see the opponent's answer.
          Row(
            spacing: 6,
            children: [
              Icon(
                FLucideIcons.eyeOff,
                size: 14,
                color: colors.mutedForeground,
              ),
              Expanded(
                child: Text(
                  c.opponentReported
                      ? 'challenge.report.blindOpponentDone'.tr()
                      : 'challenge.report.blindOpponentWaiting'.tr(),
                  style: typography.body.sm.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ),
            ],
          ),

          FButton(
            onPress: (_outcome == null || busy) ? null : _submit,
            child: busy
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    c.iHaveReported
                        ? 'challenge.report.submitAgain'.tr()
                        : 'challenge.report.submit'.tr(),
                  ),
          ),
        ],
      ),
    );
  }
}

/// The agreed format, restated. Handicap included, resolved to "us"/"them"
/// through [ChallengeHandicapSide.resolve] — never shown as home/away.
class _FormatRecap extends StatelessWidget {
  final FriendlyChallenge challenge;
  const _FormatRecap({required this.challenge});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final handicap = challenge.handicapSide.getLocalizedLabel(
      context,
      weAreHome: challenge.weAreHome,
      amount: challenge.handicapAmount,
    );

    return PCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Row(
            spacing: 6,
            children: [
              Icon(
                FLucideIcons.scrollText,
                size: 14,
                color: colors.mutedForeground,
              ),
              Flexible(
                child: Text(
                  challenge.ruleset.getLocalizedName(
                    context,
                    param: challenge.rulesetParam,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.body.sm.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (handicap != null)
            Text(
              handicap,
              style: typography.body.sm.copyWith(
                color: colors.mutedForeground,
              ),
            ),
          if ((challenge.termsNote ?? '').trim().isNotEmpty)
            Text(
              challenge.termsNote!,
              style: typography.body.sm.copyWith(
                color: colors.mutedForeground,
              ),
            ),
        ],
      ),
    );
  }
}

class _OutcomeTile extends StatelessWidget {
  final MatchOutcome outcome;
  final bool selected;
  final VoidCallback onTap;

  const _OutcomeTile({
    required this.outcome,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? colors.primary : colors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          spacing: 10,
          children: [
            Icon(
              selected ? FLucideIcons.circleCheck : FLucideIcons.circle,
              size: 18,
              color: selected ? colors.primary : colors.mutedForeground,
            ),
            Expanded(
              child: Text(
                outcome.getLocalizedName(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.theme.typography.body.md.copyWith(
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One set, our score first — the order a manager thinks in.
class _SetRow extends StatelessWidget {
  final int index;
  final (TextEditingController, TextEditingController) controllers;

  const _SetRow({required this.index, required this.controllers});

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: [
        SizedBox(
          width: 28,
          child: Text(
            '${index + 1}.',
            style: context.theme.typography.body.sm.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
          ),
        ),
        Expanded(
          child: FTextField(
            label: Text('challenge.report.setUs'.tr()),
            control: FTextFieldControl.managed(controller: controllers.$1),
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
          ),
        ),
        Expanded(
          child: FTextField(
            label: Text('challenge.report.setThem'.tr()),
            control: FTextFieldControl.managed(controller: controllers.$2),
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
          ),
        ),
      ],
    );
  }
}

class _Callout extends StatelessWidget {
  final IconData icon;
  final Color tone;
  final String title;
  final String body;

  const _Callout({
    required this.icon,
    required this.tone,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final typography = context.theme.typography;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: tone.withValues(alpha: 0.08),
        border: Border.all(color: tone.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Icon(icon, size: 16, color: tone),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  title,
                  style: typography.body.sm.copyWith(
                    fontWeight: FontWeight.bold,
                    color: tone,
                  ),
                ),
                Text(body, style: typography.body.sm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
