import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/model/challenge.dart';
import '../../../logger/talker.dart';
import '../../../ui/main.dart';
import 'friendly_offer_controller.dart';
import 'offer_fields.dart';

/// The three fixtures a lobby is advertising.
///
/// A lobby holds up to three open offers at once, so this is a board rather
/// than a single on/off control: a club with a Saturday morning slot and a
/// Wednesday evening one should be able to advertise both without choosing.
Future<void> showFriendlyOfferSheet(BuildContext context, String lobbyId) {
  return showPSheet(
    context: context,
    maxHeightRatio: 1.0,
    builder: (_) => _OfferBoardSheet(lobbyId: lobbyId),
  );
}

class _OfferBoardSheet extends ConsumerWidget {
  final String lobbyId;
  const _OfferBoardSheet({required this.lobbyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(friendlyOfferControllerProvider(lobbyId));
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return SingleChildScrollView(
      primary: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          PSheetTitle(
            label: 'challenge.offer.title'.tr(),
            trailing: FButton.icon(
              variant: .ghost,
              onPress: () => Navigator.of(context).pop(),
              child: const Icon(FLucideIcons.x),
            ),
          ),
          Text(
            'challenge.offer.explainer'.tr(),
            style: typography.body.sm.copyWith(color: colors.mutedForeground),
          ),
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'errorGeneric'.tr(),
                style: TextStyle(color: colors.destructive),
              ),
            ),
            data: (board) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
              children: [
                for (var slot = 1; slot <= ChallengeOfferBoard.maxSlots; slot++)
                  _SlotCard(
                    lobbyId: lobbyId,
                    slot: slot,
                    offer: board.bySlot(slot),
                    board: board,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotCard extends ConsumerWidget {
  final String lobbyId;
  final int slot;
  final ChallengeOfferSlot? offer;
  final ChallengeOfferBoard board;

  const _SlotCard({
    required this.lobbyId,
    required this.slot,
    required this.offer,
    required this.board,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final o = offer;

    if (o == null) {
      return FTappable(
        onPress: () => showFriendlyOfferFormSheet(
          context,
          lobbyId: lobbyId,
          slot: slot,
          board: board,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border, style: BorderStyle.solid),
          ),
          child: Row(
            spacing: 8,
            children: [
              Icon(FLucideIcons.plus, size: 16, color: colors.mutedForeground),
              Expanded(
                child: Text(
                  'challenge.offer.emptySlot'.tr(
                    namedArgs: {'slot': '$slot'},
                  ),
                  style: typography.body.sm.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final terms = <String>[
      o.ruleset.getLocalizedName(context, param: o.rulesetParam),
      // The publisher IS home, so "us" resolves correctly with weAreHome: true.
      ?o.handicapSide.getLocalizedLabel(
        context,
        weAreHome: true,
        amount: o.handicapAmount,
      ),
      if (o.costSplit != ChallengeCostSplit.none)
        o.costSplit.getLocalizedLabel(context, weAreHome: true),
      if (o.bountyKind.isSet && o.bountyAmount != null)
        '${o.bountyKind.getLocalizedName(context)}: ${formatVnd(o.bountyAmount!)}',
    ];

    return PCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Row(
            spacing: 6,
            children: [
              Icon(FLucideIcons.calendar, size: 14, color: colors.primary),
              Expanded(
                child: Text(
                  formatMatchDateTime(o.kickoff),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.body.sm.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (o.liveChallengeCount > 0)
                _Badge(count: o.liveChallengeCount),
            ],
          ),
          Text(
            o.locationName ?? '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: typography.body.sm.copyWith(color: colors.mutedForeground),
          ),
          Text(
            terms.join(' · '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: typography.body.xs.copyWith(color: colors.mutedForeground),
          ),
          // When the advert stops taking challengers. Distinct from kickoff so
          // the lobby knows whether it has a match while there is still time to
          // find another one.
          Text(
            'challenge.offer.closesAt'.tr(
              namedArgs: {'when': formatMatchDateTime(o.expiresAt)},
            ),
            style: typography.body.xs.copyWith(color: colors.mutedForeground),
          ),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: FButton(
                  size: .sm,
                  variant: .secondary,
                  onPress: () => _withdraw(context, ref, o),
                  child: Text('challenge.offer.withdraw'.tr()),
                ),
              ),
              Expanded(
                child: FButton(
                  size: .sm,
                  onPress: () => showFriendlyOfferFormSheet(
                    context,
                    lobbyId: lobbyId,
                    slot: slot,
                    board: board,
                    existing: o,
                  ),
                  child: Text('challenge.offer.edit'.tr()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _withdraw(
    BuildContext context,
    WidgetRef ref,
    ChallengeOfferSlot o,
  ) async {
    // Withdrawing lapses everyone already on the fixture, so the count is
    // named in the prompt rather than discovered afterwards.
    final confirmed = await showFDialog<bool>(
      context: context,
      builder: (dialogCtx, style, animation) => PConfirmDialog(
        animation: animation,
        title: Text('challenge.offer.withdrawTitle'.tr()),
        body: Text(
          o.liveChallengeCount > 0
              ? 'challenge.offer.withdrawBodyWithChallengers'.tr(
                  namedArgs: {'count': '${o.liveChallengeCount}'},
                )
              : 'challenge.offer.withdrawBody'.tr(),
        ),
        actions: [
          FButton(
            variant: .outline,
            onPress: () => Navigator.of(dialogCtx).pop(false),
            child: Text('challenge.offer.cancel'.tr()),
          ),
          FButton(
            variant: .destructive,
            onPress: () => Navigator.of(dialogCtx).pop(true),
            child: Text('challenge.offer.withdraw'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref
          .read(friendlyOfferControllerProvider(lobbyId).notifier)
          .withdraw(o.id);
    } catch (e, st) {
      talker.handle(e, st, 'withdraw friendly offer failed');
      if (!context.mounted) return;
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleX),
        variant: .destructive,
        title: Text(friendlyOfferErrorMessage(e)),
        alignment: .bottomCenter,
      );
    }
  }
}

class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'challenge.offer.challengerCount'.tr(namedArgs: {'count': '$count'}),
        style: context.theme.typography.body.xs.copyWith(
          color: colors.primaryForeground,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// The form for one slot
// ─────────────────────────────────────────────────────────────────────────────

/// Compose or edit the fixture in one slot.
///
/// The publisher is always the HOME side, so every "us/them" term here resolves
/// with `weAreHome: true` — this form is the one place in the app where that is
/// a constant rather than a lookup.
Future<void> showFriendlyOfferFormSheet(
  BuildContext context, {
  required String lobbyId,
  required int slot,
  required ChallengeOfferBoard board,
  ChallengeOfferSlot? existing,
}) {
  return showPSheet(
    context: context,
    maxHeightRatio: 1.0,
    builder: (_) => _OfferFormSheet(
      lobbyId: lobbyId,
      slot: slot,
      board: board,
      existing: existing,
    ),
  );
}

class _OfferFormSheet extends ConsumerStatefulWidget {
  final String lobbyId;
  final int slot;
  final ChallengeOfferBoard board;
  final ChallengeOfferSlot? existing;

  const _OfferFormSheet({
    required this.lobbyId,
    required this.slot,
    required this.board,
    this.existing,
  });

  @override
  ConsumerState<_OfferFormSheet> createState() => _OfferFormSheetState();
}

class _OfferFormSheetState extends ConsumerState<_OfferFormSheet> {
  DateTime? _kickoff;
  DateTime? _expiresAt;
  String? _locationId;
  String? _locationName;

  ChallengeRuleset _ruleset = ChallengeRuleset.standard;
  final _rulesetParam = TextEditingController();
  ChallengeHandicapSide _handicapSide = ChallengeHandicapSide.none;
  final _handicapAmount = TextEditingController();
  final _venueCost = TextEditingController();
  ChallengeCostSplit _costSplit = ChallengeCostSplit.none;
  ChallengeBountyKind _bountyKind = ChallengeBountyKind.none;
  final _bountyAmount = TextEditingController();
  final _termsNote = TextEditingController();

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _kickoff = e.kickoff;
      _expiresAt = e.expiresAt;
      _locationId = e.locationId;
      _locationName = e.locationName;
      _ruleset = e.ruleset;
      if (e.rulesetParam != null) _rulesetParam.text = '${e.rulesetParam}';
      _handicapSide = e.handicapSide;
      if (e.handicapAmount != null) _handicapAmount.text = '${e.handicapAmount}';
      if (e.venueCost != null) _venueCost.text = e.venueCost!.round().toString();
      _costSplit = e.costSplit;
      _bountyKind = e.bountyKind;
      if (e.bountyAmount != null) {
        _bountyAmount.text = e.bountyAmount!.round().toString();
      }
      _termsNote.text = e.termsNote ?? '';
    } else {
      // A lobby nearly always offers matches at the ground it already plays on.
      _locationId = widget.board.homegroundId;
      _locationName = widget.board.homegroundName;
    }
  }

  @override
  void dispose() {
    _rulesetParam.dispose();
    _handicapAmount.dispose();
    _venueCost.dispose();
    _bountyAmount.dispose();
    _termsNote.dispose();
    super.dispose();
  }

  /// Mirrors the server default so the form never shows a blank where a real
  /// value will end up.
  DateTime? get _effectiveExpiry =>
      _expiresAt ?? _kickoff?.subtract(const Duration(hours: 24));

  Future<DateTime?> _pickDateTime(DateTime? seed, {DateTime? notBefore}) async {
    final now = DateTime.now();
    final first = notBefore ?? now;
    final date = await showDatePicker(
      context: context,
      useRootNavigator: true,
      initialDate: seed ?? now.add(const Duration(days: 1)),
      firstDate: DateTime(first.year, first.month, first.day),
      lastDate: now.add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      useRootNavigator: true,
      initialTime: TimeOfDay.fromDateTime(
        seed ?? date.copyWith(hour: 18, minute: 0),
      ),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _toast(String message, {bool bad = true}) {
    showFToast(
      context: context,
      icon: Icon(bad ? FLucideIcons.circleX : FLucideIcons.swords),
      variant: bad ? FToastVariant.destructive : FToastVariant.primary,
      title: Text(message),
      alignment: .bottomCenter,
    );
  }

  Future<void> _submit() async {
    final kickoff = _kickoff;
    final locationId = _locationId;

    // Client-side checks mirror the server's, purely so the manager gets the
    // message on the field rather than as a toast after a round trip. The RPC
    // and the CHECK constraints are the actual authority.
    if (kickoff == null) return _toast('challenge.offer.errorPickKickoff'.tr());
    if (!kickoff.isAfter(DateTime.now())) {
      return _toast('challenge.offer.errorPastKickoff'.tr());
    }
    if (locationId == null) return _toast('challenge.offer.errorVenue'.tr());

    final expiry = _effectiveExpiry;
    if (expiry != null && !expiry.isBefore(kickoff)) {
      return _toast('challenge.offer.errorExpiryOrder'.tr());
    }

    int? param;
    if (_ruleset.takesParam) {
      param = int.tryParse(_rulesetParam.text.trim());
      if (param == null || param <= 0) {
        return _toast('challenge.offer.errorRulesetParam'.tr());
      }
    }
    if (_ruleset.requiresNote && _termsNote.text.trim().isEmpty) {
      return _toast('challenge.offer.errorCustomNote'.tr());
    }

    int? handicap;
    if (_handicapSide != ChallengeHandicapSide.none) {
      handicap = int.tryParse(_handicapAmount.text.trim());
      if (handicap == null || handicap <= 0) {
        return _toast('challenge.offer.errorHandicapAmount'.tr());
      }
    }

    double? bounty;
    if (_bountyKind.isSet) {
      bounty = double.tryParse(_bountyAmount.text.trim().replaceAll('.', ''));
      if (bounty == null || bounty <= 0) {
        return _toast('challenge.offer.errorBountyAmount'.tr());
      }
    }

    setState(() => _busy = true);
    try {
      await ref
          .read(friendlyOfferControllerProvider(widget.lobbyId).notifier)
          .publish(
            slot: widget.slot,
            kickoff: kickoff,
            locationId: locationId,
            expiresAt: _expiresAt,
            venueCost: double.tryParse(
              _venueCost.text.trim().replaceAll('.', ''),
            ),
            costSplit: _costSplit,
            bountyKind: _bountyKind,
            bountyAmount: bounty,
            ruleset: _ruleset,
            rulesetParam: param,
            handicapSide: _handicapSide,
            handicapAmount: handicap,
            termsNote: _termsNote.text.trim().isEmpty
                ? null
                : _termsNote.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      _toast('challenge.offer.published'.tr(), bad: false);
    } catch (e, st) {
      talker.handle(e, st, 'publish friendly offer failed');
      if (!mounted) return;
      _toast(friendlyOfferErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final replacing = (widget.existing?.liveChallengeCount ?? 0) > 0;

    return SingleChildScrollView(
      primary: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          PSheetTitle(
            label: widget.existing == null
                ? 'challenge.offer.formTitleNew'.tr()
                : 'challenge.offer.formTitleEdit'.tr(),
            trailing: FButton.icon(
              variant: .ghost,
              onPress: () => Navigator.of(context).pop(),
              child: const Icon(FLucideIcons.x),
            ),
          ),

          // Editing an offer that already has challengers on it lapses them.
          // Said before the form, not after the save.
          if (replacing)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: colors.destructive.withValues(alpha: 0.08),
                border: Border.all(
                  color: colors.destructive.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                'challenge.offer.editWarning'.tr(
                  namedArgs: {
                    'count': '${widget.existing!.liveChallengeCount}',
                  },
                ),
                style: typography.body.sm,
              ),
            ),

          PSheetSectionLabel(label: 'challenge.offer.whenWhere'.tr()),
          ChallengeFieldTile(
            icon: FLucideIcons.calendar,
            label: 'challenge.offer.kickoff'.tr(),
            value: _kickoff == null
                ? 'notSet'.tr()
                : formatMatchDateTime(_kickoff!),
            filled: _kickoff != null,
            onTap: () async {
              final picked = await _pickDateTime(_kickoff);
              if (picked != null) setState(() => _kickoff = picked);
            },
          ),
          ChallengeFieldTile(
            icon: FLucideIcons.hourglass,
            label: 'challenge.offer.closes'.tr(),
            value: _effectiveExpiry == null
                ? 'notSet'.tr()
                : formatMatchDateTime(_effectiveExpiry!),
            filled: _expiresAt != null,
            onTap: () async {
              final picked = await _pickDateTime(_effectiveExpiry);
              if (picked != null) setState(() => _expiresAt = picked);
            },
          ),
          Text(
            'challenge.offer.closesHint'.tr(),
            style: typography.body.xs.copyWith(color: colors.mutedForeground),
          ),
          ChallengeVenuePicker(
            selectedName: _locationName,
            onSelected: (loc) => setState(() {
              _locationId = loc.id;
              _locationName = loc.name;
            }),
          ),

          PSheetSectionLabel(label: 'challenge.offer.format'.tr()),
          _ChipRow<ChallengeRuleset>(
            values: ChallengeRuleset.values,
            selected: _ruleset,
            label: (r) => r.getLocalizedName(context),
            onSelected: (r) => setState(() => _ruleset = r),
          ),
          Text(
            _ruleset.getLocalizedDescription(context),
            style: typography.body.xs.copyWith(color: colors.mutedForeground),
          ),
          if (_ruleset.takesParam)
            FTextField(
              label: Text(
                _ruleset == ChallengeRuleset.bestOfSets
                    ? 'challenge.offer.paramSets'.tr()
                    : 'challenge.offer.paramRubbers'.tr(),
              ),
              control: FTextFieldControl.managed(controller: _rulesetParam),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: false,
              ),
            ),

          PSheetSectionLabel(label: 'challenge.offer.handicap'.tr()),
          Text(
            'challenge.offer.handicapHint'.tr(),
            style: typography.body.xs.copyWith(color: colors.mutedForeground),
          ),
          _ChipRow<ChallengeHandicapSide>(
            values: ChallengeHandicapSide.values,
            selected: _handicapSide,
            // The publisher is home, so `weAreHome: true` is a constant here.
            label: (h) => h == ChallengeHandicapSide.none
                ? 'challenge.offer.handicapNone'.tr()
                : h.resolve(weAreHome: true).getLocalizedName(context),
            onSelected: (h) => setState(() => _handicapSide = h),
          ),
          if (_handicapSide != ChallengeHandicapSide.none)
            FTextField(
              label: Text('challenge.offer.handicapAmount'.tr()),
              control: FTextFieldControl.managed(controller: _handicapAmount),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: false,
              ),
            ),

          PSheetSectionLabel(label: 'challenge.offer.money'.tr()),
          Text(
            'challenge.offer.moneyHint'.tr(),
            style: typography.body.xs.copyWith(color: colors.mutedForeground),
          ),
          FTextField(
            label: Text('challenge.offer.venueCost'.tr()),
            hint: '300000',
            control: FTextFieldControl.managed(controller: _venueCost),
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
          ),
          _ChipRow<ChallengeCostSplit>(
            values: ChallengeCostSplit.values,
            selected: _costSplit,
            label: (c) => c.getLocalizedNeutralLabel(context),
            onSelected: (c) => setState(() => _costSplit = c),
          ),
          _ChipRow<ChallengeBountyKind>(
            values: ChallengeBountyKind.values,
            selected: _bountyKind,
            label: (b) => b.getLocalizedName(context),
            onSelected: (b) => setState(() => _bountyKind = b),
          ),
          if (_bountyKind.isSet)
            FTextField(
              label: Text('challenge.offer.bountyAmount'.tr()),
              hint: '50000',
              control: FTextFieldControl.managed(controller: _bountyAmount),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: false,
              ),
            ),

          FTextField.multiline(
            label: Text('challenge.offer.terms'.tr()),
            hint: _ruleset.requiresNote
                ? 'challenge.offer.termsHintRequired'.tr()
                : 'challenge.offer.termsHint'.tr(),
            control: FTextFieldControl.managed(controller: _termsNote),
            maxLines: 3,
          ),

          FButton(
            onPress: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('challenge.offer.publish'.tr()),
          ),
        ],
      ),
    );
  }
}

/// A wrapped row of single-select chips.
class _ChipRow<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;

  const _ChipRow({
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final v in values)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onSelected(v),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: v == selected
                    ? colors.primary.withValues(alpha: 0.12)
                    : null,
                border: Border.all(
                  color: v == selected ? colors.primary : colors.border,
                  width: v == selected ? 1.5 : 1,
                ),
              ),
              child: Text(
                label(v),
                style: context.theme.typography.body.sm.copyWith(
                  color: v == selected
                      ? colors.primary
                      : colors.mutedForeground,
                  fontWeight: v == selected
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
