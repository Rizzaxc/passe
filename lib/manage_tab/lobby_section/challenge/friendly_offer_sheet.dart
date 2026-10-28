import 'package:easy_localization/easy_localization.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/format.dart';
import '../../../core/location_repository.dart';
import '../../../core/model/challenge.dart';
import '../../../logger/talker.dart';
import '../../../ui/main.dart';
import '../feed/home_ground_selector.dart';
import 'friendly_offer_controller.dart';

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

/// "Đăng thách đấu" entry from the planner: straight into the form for the
/// next free slot, the board only when all three are taken.
Future<void> openChallengeComposer(BuildContext context, String lobbyId) async {
  final container = ProviderScope.containerOf(context);
  ChallengeOfferBoard? board;
  try {
    board = await container
        .read(friendlyOfferControllerProvider(lobbyId).future)
        .timeout(const Duration(seconds: 5));
  } catch (_) {}
  if (!context.mounted) return;
  // Open offers are managed from their own Planner cards now, so the board is
  // only the fallback for when every slot is taken (or the load failed).
  if (board == null || board.nextFreeSlot == null) {
    return showFriendlyOfferSheet(context, lobbyId);
  }
  return showFriendlyOfferFormSheet(
    context,
    lobbyId: lobbyId,
    slot: board.nextFreeSlot!,
    board: board,
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
          if (async.value?.open.isNotEmpty ?? false)
            Text(
              'challenge.offer.explainer'.tr(),
              style: typography.body.sm.copyWith(color: colors.mutedForeground),
            )
          else
            const _HowItWorks(),
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: FCircularProgress()),
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
                for (final o in board.open)
                  _SlotCard(
                    lobbyId: lobbyId,
                    slot: o.slot,
                    offer: o,
                    board: board,
                  ),
                if (board.nextFreeSlot case final free?)
                  _SlotCard(
                    lobbyId: lobbyId,
                    slot: free,
                    offer: null,
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

/// First-use explanation, shown until the lobby has an offer open.
class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    const icons = [
      FLucideIcons.megaphone,
      FLucideIcons.search,
      FLucideIcons.swords,
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          for (var i = 0; i < icons.length; i++)
            Row(
              spacing: 10,
              children: [
                Icon(icons[i], size: 16, color: colors.primary),
                Expanded(
                  child: Text(
                    'challenge.offer.step${i + 1}'.tr(),
                    style: typography.body.sm,
                  ),
                ),
              ],
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
                  'challenge.offer.formTitleNew'.tr(),
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
      if (o.costSplit != ChallengeCostSplit.none)
        o.costSplit.getLocalizedLabel(context, weAreHome: true),
      if (o.bountyKind.isSet && o.bountyAmount != null)
        '${o.bountyKind.getLocalizedName(context)}: ${formatVnd(o.bountyAmount!)}',
    ];

    return FTappable(
      onPress: () => showFriendlyOfferFormSheet(
        context,
        lobbyId: lobbyId,
        slot: slot,
        board: board,
        existing: o,
      ),
      child: PCard(
        child: Row(
          spacing: 8,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    formatMatchDateTime(o.kickoff),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typography.body.sm.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    [o.locationName ?? '—', ...terms].join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: typography.body.xs.copyWith(
                      color: colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            if (o.liveChallengeCount > 0) _Badge(count: o.liveChallengeCount),
            FButton.icon(
              variant: .ghost,
              onPress: () => confirmWithdrawChallengeOffer(
                context,
                ref,
                lobbyId: lobbyId,
                o: o,
              ),
              child: Icon(
                FLucideIcons.trash2,
                size: 16,
                color: colors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Confirm, then withdraw an offer. Shared by the offer board and the offer's
/// own Planner card. Withdrawing lapses everyone already on the fixture and
/// retires its session, so the count is named in the prompt.
Future<void> confirmWithdrawChallengeOffer(
  BuildContext context,
  WidgetRef ref, {
  required String lobbyId,
  required ChallengeOfferSlot o,
}) async {
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

/// How far ahead the date strip reaches for a new offer.
const _offerHorizonDays = 30;

/// Bounds and default (hours before kickoff) for when the offer stops taking
/// challengers — the server's own default is 36h.
const _minCloseLeadHours = 2;
const _maxCloseLeadHoursCap = 72;
const _defaultCloseLeadHours = 36.0;

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
  // Kickoff is a day on the strip plus a time, as on the session scheduler.
  late DateTime _date;
  TimeOfDay _start = const TimeOfDay(hour: 18, minute: 0);

  /// Held as a length rather than an end time so moving kickoff carries the
  /// end along with it.
  Duration _matchLength = defaultChallengeMatchLength;

  /// How long before kickoff the offer stops taking challengers.
  double _closeLeadHours = _defaultCloseLeadHours;

  String? _locationId;
  // A typed-in venue with no picked suggestion, resolved into a real
  // location id at submit time (see _submit).
  Map<String, String?>? _freeAddress;

  ChallengeRuleset _ruleset = ChallengeRuleset.standard;

  /// Sets for best-of, rubbers for a team tie; ignored by other rulesets.
  int _rulesetParam = 3;
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
      _date = DateTime(e.kickoff.year, e.kickoff.month, e.kickoff.day);
      _start = TimeOfDay.fromDateTime(e.kickoff);
      _matchLength = e.endTime.difference(e.kickoff);
      _closeLeadHours = (e.kickoff.difference(e.expiresAt).inMinutes / 60.0)
          .roundToDouble();
      _locationId = e.locationId;
      _ruleset = e.ruleset;
      if (e.rulesetParam != null) _rulesetParam = e.rulesetParam!;
      if (e.venueCost != null) {
        _venueCost.text = e.venueCost!.round().toString();
      }
      _costSplit = e.costSplit;
      _bountyKind = e.bountyKind;
      if (e.bountyAmount != null) {
        _bountyAmount.text = e.bountyAmount!.round().toString();
      }
      _termsNote.text = e.termsNote ?? '';
    } else {
      final now = DateTime.now();
      _date = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(const Duration(days: 1));
      // A lobby nearly always offers matches at the ground it already plays on.
      _locationId = widget.board.homegroundId;
    }
    _clampCloseLead();
  }

  @override
  void dispose() {
    _venueCost.dispose();
    _bountyAmount.dispose();
    _termsNote.dispose();
    super.dispose();
  }

  DateTime get _kickoff =>
      DateTime(_date.year, _date.month, _date.day, _start.hour, _start.minute);

  DateTime get _endTime => _kickoff.add(_matchLength);

  /// Far enough out that an edited offer's own date is still on the strip.
  int get _horizonDays {
    final today = DateUtils.dateOnly(DateTime.now());
    final existing = widget.existing?.kickoff;
    final needed = existing == null
        ? 0
        : DateUtils.dateOnly(existing).difference(today).inDays;
    return needed > _offerHorizonDays ? needed : _offerHorizonDays;
  }

  double get _hoursUntilKickoff =>
      _kickoff.difference(DateTime.now()).inMinutes / 60.0;

  /// Too close to kickoff for any lead on the slider to leave an hour of
  /// gathering — the server's short-notice default takes over instead.
  bool get _closeTooSoon => _hoursUntilKickoff < _minCloseLeadHours + 1;

  /// The longest lead the slider offers right now: the cap, further capped
  /// so the offer still stays open for at least an hour from now.
  double get _maxCloseLeadHours => (_hoursUntilKickoff - 1).clamp(
    _minCloseLeadHours.toDouble(),
    _maxCloseLeadHoursCap.toDouble(),
  );

  void _clampCloseLead() {
    _closeLeadHours = _closeLeadHours.clamp(
      _minCloseLeadHours.toDouble(),
      _maxCloseLeadHours,
    );
  }

  /// The closing time the server will store: the slider's, or — too close to
  /// kickoff for the slider — `publish_challenge_offer`'s short-notice
  /// default (at least an hour from now, always before kickoff).
  DateTime? get _expiresAt => _closeTooSoon
      ? null
      : _kickoff.subtract(Duration(minutes: (_closeLeadHours * 60).round()));

  DateTime get _effectiveExpiry {
    if (_expiresAt case final e?) return e;
    final shortNotice = DateTime.now().add(const Duration(hours: 1));
    final latest = _kickoff.subtract(const Duration(minutes: 1));
    return shortNotice.isBefore(latest) ? shortNotice : latest;
  }

  void _setKickoff({DateTime? date, TimeOfDay? start}) {
    setState(() {
      if (date != null) _date = date;
      if (start != null) _start = start;
      _clampCloseLead();
    });
  }

  Future<void> _pickStart() async {
    final picked = await showPTimePicker(
      context,
      initial: _start,
      title: 'challenge.offer.kickoff'.tr(),
    );
    if (picked != null) _setKickoff(start: picked);
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
    // Client-side checks mirror the server's, purely so the manager gets the
    // message on the field rather than as a toast after a round trip. The RPC
    // and the CHECK constraints are the actual authority.
    if (!kickoff.isAfter(DateTime.now())) {
      return _toast('challenge.offer.errorPastKickoff'.tr());
    }
    final hasVenue =
        _locationId != null ||
        (_freeAddress?['locationName']?.trim().isNotEmpty ?? false);
    if (!hasVenue) return _toast('challenge.offer.errorVenue'.tr());

    if (!_effectiveExpiry.isAfter(DateTime.now())) {
      return _toast('challenge.offer.errorExpiryPast'.tr());
    }

    final param = _ruleset.takesParam ? _rulesetParam : null;
    if (_ruleset.requiresNote && _termsNote.text.trim().isEmpty) {
      return _toast('challenge.offer.errorCustomNote'.tr());
    }

    double? venueCost;
    if (_costSplit != ChallengeCostSplit.none) {
      venueCost = double.tryParse(_venueCost.text.trim());
      if (venueCost == null || venueCost <= 0) {
        return _toast('challenge.offer.errorVenueCost'.tr());
      }
    }

    double? bounty;
    if (_bountyKind.isSet) {
      bounty = double.tryParse(_bountyAmount.text.trim());
      if (bounty == null || bounty <= 0) {
        return _toast('challenge.offer.errorBountyAmount'.tr());
      }
    }

    setState(() => _busy = true);
    try {
      final locationId = await resolveLocationId(
        pickedId: _locationId,
        freeAddress: _freeAddress,
      );
      if (locationId == null) {
        return _toast('challenge.offer.errorVenue'.tr());
      }
      await ref
          .read(friendlyOfferControllerProvider(widget.lobbyId).notifier)
          .publish(
            slot: widget.slot,
            kickoff: kickoff,
            endTime: kickoff.add(_matchLength),
            locationId: locationId,
            expiresAt: _expiresAt,
            venueCost: venueCost,
            costSplit: _costSplit,
            bountyKind: _bountyKind,
            bountyAmount: bounty,
            ruleset: _ruleset,
            rulesetParam: param,
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
        spacing: 20,
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

          // The planner opens this form directly, so the feature explanation
          // lives here for a first offer.
          if (widget.existing == null && widget.board.open.isEmpty)
            const _HowItWorks(),

          // Lobbies already on this fixture committed their players to it.
          // A clarification shouldn't cost them that, so offer the one edit
          // that doesn't: adding to the note.
          if (replacing && widget.existing!.ruleset != ChallengeRuleset.custom)
            _AmendBox(lobbyId: widget.lobbyId, offer: widget.existing!),

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

          PFormSection(
            label: 'challenge.offer.whenWhere'.tr(),
            children: [
              PDateStrip(
                date: _date,
                maxDays: _horizonDays,
                onChanged: (d) => _setKickoff(date: d),
              ),
              PPickerRow(
                icon: FLucideIcons.clock,
                label: 'challenge.offer.kickoff'.tr(),
                value: formatTimeOfDay(_kickoff),
                onTap: _pickStart,
              ),
              PDurationSlider(
                label: 'challenge.offer.duration'.tr(),
                value: _matchLength,
                min: minChallengeMatchLength,
                max: maxChallengeMatchLength,
                caption: 'challenge.offer.endsAt'.tr(
                  namedArgs: {
                    // Only the time when it's the same day; a match running
                    // past midnight says which day.
                    'when': DateUtils.isSameDay(_endTime, _kickoff)
                        ? formatTimeOfDay(_endTime)
                        : formatMatchDateTime(_endTime),
                  },
                ),
                onChanged: (d) => setState(() => _matchLength = d),
              ),
              HomeGroundField(
                value: _locationId,
                lobbyId: widget.lobbyId,
                // The section label above names the field, so the pin
                // stands in for the outer label.
                prefixIcon: FLucideIcons.mapPin,
                onChanged: (id) => setState(() {
                  _locationId = id.isEmpty ? null : id;
                  _freeAddress = null;
                }),
                onFreeAddressChanged: (addr) => setState(() {
                  _locationId = null;
                  _freeAddress = addr;
                }),
              ),
            ],
          ),

          // When challengers must have committed by — a deadline on the
          // offer, not part of the match's own time, so it stands apart from
          // the section above, its own name on the row.
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              if (!_closeTooSoon)
                PLeadSlider(
                  icon: FLucideIcons.hourglass,
                  label: 'challenge.offer.deadline'.tr(),
                  hours: _closeLeadHours,
                  minHours: _minCloseLeadHours,
                  maxHours: _maxCloseLeadHours,
                  caption: 'challenge.offer.closesAt'.tr(
                    namedArgs: {'when': formatMatchDateTime(_effectiveExpiry)},
                  ),
                  onChanged: (h) => setState(() => _closeLeadHours = h),
                ),
              Text(
                _closeTooSoon
                    ? 'challenge.offer.closesSoonHint'.tr(
                        namedArgs: {
                          'time': formatMatchDateTime(_effectiveExpiry),
                        },
                      )
                    : 'challenge.offer.closesHint'.tr(),
                style: typography.body.xs.copyWith(
                  color: colors.mutedForeground,
                  height: 1.4,
                ),
              ),
            ],
          ),

          // What the two sides are agreeing to — the rules and the money —
          // as one block; each row's label already says which it is.
          PFormSection(
            label: 'challenge.offer.matchTerms'.tr(),
            children: [
              PPickerRow(
                icon: FLucideIcons.scrollText,
                label: 'challenge.offer.rules'.tr(),
                sub: _ruleset.getLocalizedDescription(context),
                value: _ruleset.getLocalizedName(context),
                onTap: () async {
                  final picked = await showPOptionSheet<ChallengeRuleset>(
                    context,
                    title: 'challenge.offer.rules'.tr(),
                    options: ChallengeRuleset.values,
                    selected: _ruleset,
                    label: (r) => r.getLocalizedName(context),
                    description: (r) => r.getLocalizedDescription(context),
                  );
                  if (picked != null) setState(() => _ruleset = picked);
                },
              ),
              if (_ruleset.takesParam)
                PStepperRow(
                  icon: FLucideIcons.hash,
                  label: _ruleset == ChallengeRuleset.bestOfSets
                      ? 'challenge.offer.paramSets'.tr()
                      : 'challenge.offer.paramRubbers'.tr(),
                  min: 1,
                  max: 9,
                  value: _rulesetParam,
                  onChanged: (v) => setState(() => _rulesetParam = v),
                ),
              PPickerRow(
                icon: FLucideIcons.wallet,
                label: 'challenge.offer.costSplit'.tr(),
                value: _costSplit.getLocalizedNeutralLabel(context),
                onTap: () async {
                  final picked = await showPOptionSheet<ChallengeCostSplit>(
                    context,
                    title: 'challenge.offer.costSplit'.tr(),
                    options: ChallengeCostSplit.values,
                    selected: _costSplit,
                    label: (c) => c.getLocalizedNeutralLabel(context),
                  );
                  if (picked != null) setState(() => _costSplit = picked);
                },
              ),
              // "No pitch fee" has no amount to state.
              if (_costSplit != ChallengeCostSplit.none)
                PAmountRow(
                  controller: _venueCost,
                  label: 'challenge.offer.venueCost'.tr(),
                  hint: '300000',
                ),
              PPickerRow(
                icon: FLucideIcons.coins,
                label: 'challenge.offer.bounty'.tr(),
                value: _bountyKind.getLocalizedName(context),
                onTap: () async {
                  final picked = await showPOptionSheet<ChallengeBountyKind>(
                    context,
                    title: 'challenge.offer.bounty'.tr(),
                    options: ChallengeBountyKind.values,
                    selected: _bountyKind,
                    label: (b) => b.getLocalizedName(context),
                  );
                  if (picked != null) setState(() => _bountyKind = picked);
                },
              ),
              if (_bountyKind.isSet)
                PAmountRow(
                  controller: _bountyAmount,
                  icon: FLucideIcons.handCoins,
                  label: 'challenge.offer.bountyAmount'.tr(),
                ),
              Text(
                'challenge.offer.moneyHint'.tr(),
                style: typography.body.xs.copyWith(
                  color: colors.mutedForeground,
                  height: 1.4,
                ),
              ),
            ],
          ),

          FTextField.multiline(
            label: Text('challenge.offer.terms'.tr()),
            hint: _ruleset.requiresNote
                ? 'challenge.offer.termsHintRequired'.tr()
                : 'challenge.offer.termsHint'.tr(),
            control: FTextFieldControl.managed(controller: _termsNote),
            minLines: 3,
            maxLines: 3,
          ),

          FButton(
            onPress: _busy ? null : _submit,
            child: _busy
                ? const FCircularProgress()
                : Text('challenge.offer.publish'.tr()),
          ),
        ],
      ),
    );
  }
}

/// "Bổ sung ghi chú": append a line to an offer's note without re-publishing,
/// so the lobbies already on it keep their place (`amend_challenge_offer`).
class _AmendBox extends ConsumerStatefulWidget {
  final String lobbyId;
  final ChallengeOfferSlot offer;

  const _AmendBox({required this.lobbyId, required this.offer});

  @override
  ConsumerState<_AmendBox> createState() => _AmendBoxState();
}

class _AmendBoxState extends ConsumerState<_AmendBox> {
  final _text = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final append = _text.text.trim();
    if (append.isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(friendlyOfferControllerProvider(widget.lobbyId).notifier)
          .amend(widget.offer.id, append);
      if (!mounted) return;
      Navigator.of(context).pop();
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.check),
        title: Text('challenge.offer.amended'.tr()),
        alignment: .bottomCenter,
      );
    } catch (e, st) {
      talker.handle(e, st, 'amend friendly offer failed');
      if (!mounted) return;
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleX),
        variant: .destructive,
        title: Text(friendlyOfferErrorMessage(e)),
        alignment: .bottomCenter,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    return PCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Text(
            'challenge.offer.amendTitle'.tr(),
            style: typography.body.sm.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            'challenge.offer.amendHint'.tr(
              namedArgs: {'count': '${widget.offer.liveChallengeCount}'},
            ),
            style: typography.body.xs.copyWith(
              color: colors.mutedForeground,
              height: 1.4,
            ),
          ),
          FTextField.multiline(
            control: FTextFieldControl.managed(controller: _text),
            maxLength: challengeOfferAmendMaxLength,
            minLines: 2,
            maxLines: 2,
          ),
          FButton(
            variant: .secondary,
            onPress: _busy ? null : _submit,
            child: _busy
                ? const FCircularProgress()
                : Text('challenge.offer.amendCta'.tr()),
          ),
        ],
      ),
    );
  }
}
