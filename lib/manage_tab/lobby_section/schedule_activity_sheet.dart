import 'package:easy_localization/easy_localization.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:share_plus/share_plus.dart';

import '../../core/location_repository.dart';
import '../../ui/dialog.dart';
import '../../ui/form_rows.dart';
import '../../ui/sheet.dart';
import 'activity/upcoming_controller.dart';
import 'feed/home_ground_selector.dart';
import 'invite_link/invite_link_card.dart';
import 'invite_link/invite_link_controller.dart';
import 'lobby_detail_controller.dart';
import 'members/controller.dart';
import 'schedule_activity_controller.dart';

/// Captain-side "schedule the next play session" flow.
///
/// Opens a form sheet asking for the full activity spec (date / time,
/// location, recurrence, cost, confirmation threshold + deadline)
/// and fires the schedule (or, when [existing] is passed, reschedule)
/// mutation on the lobby's `ScheduleActivityController`, which inserts
/// (or updates) the `activity` row and posts a matching feed item.
Future<void> showScheduleActivitySheet(
  BuildContext context,
  String lobbyId, {
  UpcomingActivity? existing,
}) async {
  await showPSheet<void>(
    context: context,
    builder: (_) =>
        _ScheduleActivitySheet(lobbyId: lobbyId, existing: existing),
  );
}

/// Cap on how far ahead captains can schedule a session. Anything
/// further out should go through a recurrence template instead.
const _maxScheduleHorizonDays = 7;

/// Bounds (in hours before kickoff) on how close to start time the
/// organizer can require confirmations to lock in, chosen via a slider.
const _minDeadlineLeadHours = 2;
const _maxDeadlineLeadHours = 72;

/// Default lead time used when the user first turns the deadline on.
const _defaultDeadlineLeadHours = 48.0;

/// Session length bounds on the duration slider. A session being edited
/// that's already longer keeps its length; the ceiling stretches to it.
const _minSessionLength = Duration(minutes: 30);
const _maxSessionLength = Duration(hours: 4);
const _defaultSessionLength = Duration(hours: 2);

class _ScheduleActivitySheet extends ConsumerStatefulWidget {
  final String lobbyId;
  final UpcomingActivity? existing;

  const _ScheduleActivitySheet({required this.lobbyId, this.existing});

  @override
  ConsumerState<_ScheduleActivitySheet> createState() =>
      _ScheduleActivitySheetState();
}

class _ScheduleActivitySheetState
    extends ConsumerState<_ScheduleActivitySheet> {
  late DateTime _date;
  TimeOfDay _start = const TimeOfDay(hour: 18, minute: 0);

  /// Held as a length, not an end time: moving the start carries the end
  /// along, and a session that runs past midnight needs no special case.
  Duration _length = _defaultSessionLength;

  // Seeded from the lobby's primary homeground when the lobby info resolves;
  // HomeGroundField below renders the picker UI around this id.
  String? _locationId;

  // Set when the user is editing/typing a manual venue instead of picking
  // one — resolved into a real location id at submit time (see _submit).
  Map<String, String?>? _freeAddress;

  bool _recurring = false;

  bool _costEnabled = false;
  ActivityCostType _costType = ActivityCostType.perPax;
  final _amountController = TextEditingController(text: '50000');

  // Seeded from the roster size once it loads (see _seedThreshold) — a fixed
  // 4 auto-cancelled every small lobby's first session at kickoff.
  int _confirmationThreshold = 4;
  bool _thresholdEnabled = false;

  /// Set once the organizer touches the threshold, so a late-arriving member
  /// count doesn't overwrite their choice.
  bool _thresholdTouched = false;

  // How many hours before kickoff confirmations lock in, chosen via the
  // slider. Clamped to [_minDeadlineLeadHours, _maxAllowedDeadlineLeadHours]
  // on every date/time change.
  double _deadlineLeadHours = _defaultDeadlineLeadHours;

  // Null = the user has manually turned the deadline off, OR the session
  // is too soon for one. Otherwise this is the chosen deadline.
  DateTime? _confirmationDeadline;
  bool _deadlineManuallyOff = false;

  final _scrollController = ScrollController();

  /// Editing an occurrence that's already part of a series locks the
  /// recurring toggle ON — see the `locked` doc on `PSwitchRow`.
  bool get _seriesLocked => widget.existing?.isRecurring ?? false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _seedFromExisting(existing);
    } else {
      final now = DateTime.now();
      _date = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(const Duration(days: 1));
      // Lobby home ground default — populated once async info resolves.
      _seedDefaultsFromLobby();
      final members = ref
          .read(lobbyMembersControllerProvider(widget.lobbyId))
          .value;
      if (members != null) _seedThreshold(members.length);
    }
    _recomputeDeadline();
  }

  /// Prefill every field from the activity being edited, including the
  /// chosen lead time (derived from the stored deadline vs. start time).
  void _seedFromExisting(UpcomingActivity existing) {
    final start = existing.nextStart.toLocal();
    final end = existing.nextEnd?.toLocal();
    _date = DateTime(start.year, start.month, start.day);
    _start = TimeOfDay(hour: start.hour, minute: start.minute);
    if (end != null && end.isAfter(start)) _length = end.difference(start);
    _locationId = existing.locationId;
    _recurring = existing.isRecurring;
    _costEnabled = existing.costType != null && existing.costAmount != null;
    _costType = existing.costType == 'total'
        ? ActivityCostType.total
        : ActivityCostType.perPax;
    if (existing.costAmount != null) {
      _amountController.text = existing.costAmount!.toString();
    }
    _thresholdEnabled = existing.confirmationThreshold != null;
    _thresholdTouched = true;
    _confirmationThreshold = existing.confirmationThreshold ?? 4;
    _deadlineManuallyOff = existing.confirmationDeadline == null;
    final existingDeadline = existing.confirmationDeadline;
    if (existingDeadline != null) {
      final leadHours =
          start.difference(existingDeadline.toLocal()).inMinutes / 60.0;
      _deadlineLeadHours = leadHours.clamp(
        _minDeadlineLeadHours.toDouble(),
        _maxDeadlineLeadHours.toDouble(),
      );
    }
  }

  void _seedThreshold(int memberCount) {
    if (_thresholdTouched) return;
    _confirmationThreshold = defaultConfirmationThreshold(memberCount);
    _thresholdEnabled = thresholdEnabledByDefault(memberCount);
  }

  void _seedDefaultsFromLobby() {
    // Read the cached lobby info synchronously if it's already loaded.
    // If not, the listen() in build() picks up the value once it lands.
    final info = ref.read(lobbyDetailControllerProvider(widget.lobbyId)).value;
    if (info != null) {
      _locationId = info.lobby.primaryHomeGround;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Picker helpers ────────────────────────────────────────────

  void _setDate(DateTime picked) {
    setState(() {
      _date = DateTime(picked.year, picked.month, picked.day);
      _recomputeDeadline();
    });
  }

  Future<void> _pickStart() async {
    final picked = await showPTimePicker(
      context,
      initial: _start,
      title: 'lobbyHub.schedule.start'.tr(),
    );
    if (picked != null) {
      setState(() {
        _start = picked;
        _recomputeDeadline();
      });
    }
  }

  /// The slider's ceiling: [_maxSessionLength], or longer when the session
  /// being edited already is.
  Duration get _lengthCeiling =>
      _length > _maxSessionLength ? _length : _maxSessionLength;

  DateTime get _endInstant => _startInstant.add(_length);

  /// "Kết thúc lúc 20:30", naming the day when it runs past midnight.
  String get _endsAtCaption {
    final end = _endInstant;
    final time = _fmtTime(TimeOfDay.fromDateTime(end));
    final sameDay = end.day == _date.day;
    return 'lobbyHub.schedule.endsAt'.tr(
      namedArgs: {
        'time': sameDay
            ? time
            : '$time ${_fmtDate(DateTime(end.year, end.month, end.day))}',
      },
    );
  }

  DateTime get _startInstant =>
      DateTime(_date.year, _date.month, _date.day, _start.hour, _start.minute);

  /// The session is too soon for a confirmation cutoff if start is less
  /// than the minimum lead time (2h) away — the deadline UI flips off and
  /// locks, since no valid lead choice would leave the deadline in the
  /// future.
  bool get _tooSoonForDeadline {
    final now = DateTime.now();
    return _startInstant.isBefore(
      now.add(const Duration(hours: _minDeadlineLeadHours)),
    );
  }

  /// The largest lead time the slider can offer right now: the 72h cap,
  /// further capped by how far away the session actually is so the
  /// resulting deadline can never land in the past.
  double get _maxAllowedDeadlineLeadHours {
    final hoursUntilStart =
        _startInstant.difference(DateTime.now()).inMinutes / 60.0;
    return hoursUntilStart.clamp(
      _minDeadlineLeadHours.toDouble(),
      _maxDeadlineLeadHours.toDouble(),
    );
  }

  void _recomputeDeadline() {
    if (_tooSoonForDeadline) {
      _confirmationDeadline = null;
      return;
    }
    _deadlineLeadHours = _deadlineLeadHours.clamp(
      _minDeadlineLeadHours.toDouble(),
      _maxAllowedDeadlineLeadHours,
    );
    if (_deadlineManuallyOff) {
      _confirmationDeadline = null;
      return;
    }
    _confirmationDeadline = _startInstant.subtract(
      Duration(minutes: (_deadlineLeadHours * 60).round()),
    );
  }

  // ── Submit ────────────────────────────────────────────────────

  /// Best-effort, non-blocking collision check against the lobby's other
  /// current/future activities — same time window *and* same venue. A
  /// lobby can legitimately run several activities at once (see
  /// upcoming_controller.dart), so this only warns; it never blocks.
  UpcomingActivity? _findConflict(DateTime start, DateTime end) {
    final others =
        ref
            .read(lobbyUpcomingActivitiesControllerProvider(widget.lobbyId))
            .value ??
        const <UpcomingActivity>[];
    final myId = widget.existing?.activity.id;
    for (final other in others) {
      if (other.activity.id == myId) continue; // don't compare against self
      final oStart = other.nextStart;
      final oEnd = other.nextEnd ?? oStart;
      final overlaps = start.isBefore(oEnd) && oStart.isBefore(end);
      final sameLocation =
          _locationId != null && _locationId == other.locationId;
      if (overlaps && sameLocation) return other;
    }
    return null;
  }

  Future<bool> _showOverlapDialog(UpcomingActivity conflict) async {
    final start = conflict.nextStart.toLocal();
    final proceed = await showFDialog<bool>(
      context: context,
      builder: (dialogCtx, style, animation) => PConfirmDialog(
        animation: animation,
        title: Text('lobbyHub.schedule.conflictTitle'.tr()),
        body: Text(
          'lobbyHub.schedule.conflictBody'.tr(
            namedArgs: {
              'date': _fmtDate(DateTime(start.year, start.month, start.day)),
              'time': _fmtTime(
                TimeOfDay(hour: start.hour, minute: start.minute),
              ),
            },
          ),
        ),
        direction: Axis.horizontal,
        actions: [
          FButton(
            variant: .outline,
            onPress: () => Navigator.of(dialogCtx).pop(false),
            child: Text('lobbyHub.schedule.editAgain'.tr()),
          ),
          FButton(
            variant: .destructive,
            onPress: () => Navigator.of(dialogCtx).pop(true),
            child: Text('lobbyHub.schedule.scheduleAnyway'.tr()),
          ),
        ],
      ),
    );
    return proceed ?? false;
  }

  Future<void> _submit() async {
    final start = _startInstant;
    final end = _endInstant;

    // A one-off activity scheduled in the past would insert successfully
    // (the DB has no such constraint) but then never surface anywhere: the
    // Planner list only shows rows whose start_time is still ahead of now,
    // and History only covers *recorded* matches, not activities. A
    // recurring series' first occurrence is a real dated row too now (see
    // schema/recurring_activity_series.sql) — there's no more "it's just a
    // template" exemption to make here.
    if (start.isBefore(DateTime.now())) {
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleAlert),
        variant: .destructive,
        title: Text('lobbyHub.schedule.pastError'.tr()),
        alignment: .bottomCenter,
      );
      return;
    }

    final amountText = _amountController.text.trim();
    final amount = _costEnabled ? num.tryParse(amountText) : null;
    if (_costEnabled && (amount == null || amount <= 0)) {
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleAlert),
        variant: .destructive,
        title: Text('lobbyHub.schedule.invalidCost'.tr()),
        alignment: .bottomCenter,
      );
      return;
    }

    final conflict = _findConflict(start, end);
    if (conflict != null) {
      final proceed = await _showOverlapDialog(conflict);
      if (!mounted || !proceed) return;
    }

    // Day-of-week ISO ordering: Mon=0 … Sun=6. DateTime.weekday is
    // 1..7 (Mon..Sun) so subtract one.
    final dayOfWeek = _recurring ? _date.weekday - 1 : null;
    final existing = widget.existing;
    final controller = ref.read(
      scheduleActivityControllerProvider(widget.lobbyId).notifier,
    );

    final resolvedLocationId = await resolveLocationId(
      pickedId: _locationId,
      freeAddress: _freeAddress,
    );

    try {
      if (existing != null) {
        await controller.reschedule(
          activityId: existing.activity.id!,
          start: start,
          end: end,
          locationId: resolvedLocationId,
          costType: _costEnabled ? _costType : null,
          costAmount: amount,
          confirmationThreshold: _thresholdEnabled
              ? _confirmationThreshold
              : null,
          confirmationDeadline: _thresholdEnabled
              ? _confirmationDeadline
              : null,
          recurrenceDayOfWeek: dayOfWeek,
        );
      } else {
        await controller.schedule(
          start: start,
          end: end,
          locationId: resolvedLocationId,
          costType: _costEnabled ? _costType : null,
          costAmount: amount,
          confirmationThreshold: _thresholdEnabled
              ? _confirmationThreshold
              : null,
          confirmationDeadline: _thresholdEnabled
              ? _confirmationDeadline
              : null,
          recurrenceDayOfWeek: dayOfWeek,
        );
      }
    } on StateError catch (e) {
      if (!mounted) return;
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleAlert),
        variant: .destructive,
        title: Text(e.message),
        alignment: .bottomCenter,
      );
      return;
    }

    if (!mounted) return;
    final shareText = existing == null ? _buildShareText(start, end) : null;
    Navigator.of(context).pop();
    showFToast(
      context: context,
      icon: const Icon(FLucideIcons.check),
      title: Text(
        existing != null
            ? 'lobbyHub.schedule.updated'.tr()
            : 'lobbyHub.schedule.created'.tr(),
      ),
      // A new session is the moment people need to hear about it — the
      // lobby feed only reaches members who already have the app.
      suffixBuilder: shareText == null
          ? null
          : (toastContext, entry) => FButton(
              size: .sm,
              variant: .outline,
              onPress: () {
                entry.dismiss();
                SharePlus.instance.share(ShareParams(text: shareText));
              },
              child: Text('lobbyHub.schedule.share'.tr()),
            ),
      duration: shareText == null ? null : const Duration(seconds: 8),
      alignment: .bottomCenter,
    );
  }

  /// "{lobby} · {sport} — {date} {start}–{end} @ {venue}", plus the invite
  /// link when the lobby has one, so a recipient outside the lobby can join
  /// and RSVP in one tap.
  String _buildShareText(DateTime start, DateTime end) {
    final info = ref.read(lobbyDetailControllerProvider(widget.lobbyId)).value;
    final venue = _freeAddress != null
        ? [
            _freeAddress!['locationName'],
            _freeAddress!['streetNumber'],
            _freeAddress!['streetName'],
          ].whereType<String>().where((e) => e.isNotEmpty).join(' ')
        : info?.homeGrounds.where((h) => h.id == _locationId).firstOrNull?.name;
    final code = ref
        .read(inviteLinkControllerProvider(widget.lobbyId))
        .value
        ?.code;
    return [
      [
        if (info != null) info.lobby.name,
        if (info != null) info.lobby.sport.getLocalizedName(context),
      ].join(' · '),
      '${_fmtDate(_date)} ${_fmtTime(_start)}–'
          '${_fmtTime(TimeOfDay.fromDateTime(end))}'
          '${venue == null || venue.isEmpty ? '' : ' @ $venue'}',
      if (code != null)
        'lobbyHub.schedule.shareJoin'.tr(
          namedArgs: {'url': buildInviteLinkUrl(code)},
        ),
    ].where((l) => l.isNotEmpty).join('\n');
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final saving = ref.watch(
      scheduleActivityControllerProvider(widget.lobbyId),
    );

    // Re-seed location once the lobby info async value lands. Only for a
    // fresh schedule — an edit already seeded (possibly null / "no
    // location") from the activity being edited and shouldn't get
    // silently overwritten by the lobby's home ground default.
    ref.listen<AsyncValue<LobbyDetailInfo>>(
      lobbyDetailControllerProvider(widget.lobbyId),
      (prev, next) {
        final info = next.value;
        if (widget.existing == null && info != null && _locationId == null) {
          setState(() => _locationId = info.lobby.primaryHomeGround);
        }
      },
    );

    ref.listen(lobbyMembersControllerProvider(widget.lobbyId), (_, next) {
      final members = next.value;
      if (widget.existing == null && members != null && !_thresholdTouched) {
        setState(() => _seedThreshold(members.length));
      }
    });

    return SingleChildScrollView(
      controller: _scrollController,
      primary: false,
      child: Column(
        spacing: 20,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PSheetTitle(
            label: widget.existing != null
                ? 'lobbyHub.schedule.editTitle'.tr()
                : 'lobbyHub.schedule.createTitle'.tr(),
            trailing: FButton.icon(
              variant: .ghost,
              onPress: () => Navigator.of(context).pop(),
              child: const Icon(FLucideIcons.x),
            ),
          ),

          // ── Time & place section ────────────────────────────
          PFormSection(
            label: 'lobbyHub.schedule.whenWhere'.tr(),
            children: [
              PDateStrip(
                date: _date,
                maxDays: _maxScheduleHorizonDays,
                onChanged: _setDate,
              ),
              PPickerRow(
                icon: FLucideIcons.clock,
                label: 'lobbyHub.schedule.start'.tr(),
                value: _fmtTime(_start),
                onTap: _pickStart,
              ),
              PDurationSlider(
                label: 'lobbyHub.schedule.duration'.tr(),
                value: _length,
                min: _minSessionLength,
                max: _lengthCeiling,
                caption: _endsAtCaption,
                onChanged: (d) => setState(() => _length = d),
              ),
              HomeGroundField(
                value: _locationId,
                lobbyId: widget.lobbyId,
                // No outer label — the "Khi nào & ở đâu" section title
                // above already says what this field is for. The pin
                // icon inside the field carries the visual cue.
                prefixIcon: FLucideIcons.mapPin,
                onChanged: (id) => setState(() {
                  _locationId = id.isEmpty ? null : id;
                  _freeAddress = null;
                }),
                // A manually-entered venue is resolved into a real
                // location id at submit time (see _submit) — no longer
                // dropped.
                onFreeAddressChanged: (addr) => setState(() {
                  _locationId = null;
                  _freeAddress = addr;
                }),
              ),
              PSwitchRow(
                icon: FLucideIcons.repeat,
                label: 'lobbyHub.schedule.repeatWeekly'.tr(),
                sub: _seriesLocked
                    ? 'lobbyHub.schedule.seriesLocked'.tr()
                    : _recurring
                    ? 'lobbyHub.schedule.repeatsOn'.tr(
                        namedArgs: {'weekday': _weekdayLong(_date.weekday)},
                      )
                    : 'lobbyHub.schedule.once'.tr(),
                value: _recurring,
                onChanged: (v) => setState(() => _recurring = v),
                locked: _seriesLocked,
              ),
            ],
          ),

          // ── Cost section ─────────────────────────────────────
          PFormSection(
            label: 'lobbyHub.schedule.cost'.tr(),
            children: [
              PSwitchRow(
                icon: FLucideIcons.wallet,
                label: 'lobbyHub.schedule.hasCost'.tr(),
                sub: _costEnabled
                    ? 'lobbyHub.schedule.autoSplit'.tr()
                    : 'lobbyHub.schedule.free'.tr(),
                value: _costEnabled,
                onChanged: (v) => setState(() => _costEnabled = v),
              ),
              if (_costEnabled) ...[
                _CostTypePicker(
                  value: _costType,
                  onChanged: (v) => setState(() => _costType = v),
                ),
                PAmountRow(
                  controller: _amountController,
                  label: 'lobbyHub.common.amount'.tr(),
                ),
              ],
            ],
          ),

          // ── Confirmation section ────────────────────────────
          PFormSection(
            label: 'lobbyHub.schedule.attendance'.tr(),
            children: [
              // Off means no quorum: nothing freezes RSVPs and nothing
              // auto-cancels the session at kickoff.
              PSwitchRow(
                icon: FLucideIcons.userCheck,
                label: 'lobbyHub.schedule.requireQuorum'.tr(),
                sub: _thresholdEnabled
                    ? 'lobbyHub.schedule.requireQuorumOn'.tr()
                    : 'lobbyHub.schedule.requireQuorumOff'.tr(),
                value: _thresholdEnabled,
                onChanged: (v) => setState(() {
                  _thresholdTouched = true;
                  _thresholdEnabled = v;
                }),
              ),
              if (_thresholdEnabled) ...[
                PStepperRow(
                  icon: FLucideIcons.users,
                  label: 'lobbyHub.schedule.threshold'.tr(),
                  sub: 'lobbyHub.schedule.thresholdHint'.tr(),
                  min: 1,
                  max: 30,
                  value: _confirmationThreshold,
                  onChanged: (v) => setState(() {
                    _thresholdTouched = true;
                    _confirmationThreshold = v;
                  }),
                ),
                _DeadlineRow(
                  tooSoon: _tooSoonForDeadline,
                  manuallyOff: _deadlineManuallyOff,
                  deadline: _confirmationDeadline,
                  onChanged: (on) => setState(() {
                    _deadlineManuallyOff = !on;
                    _recomputeDeadline();
                  }),
                ),
              ],
              if (_thresholdEnabled &&
                  !_tooSoonForDeadline &&
                  !_deadlineManuallyOff)
                PLeadSlider(
                  label: 'lobbyHub.schedule.lockBefore'.tr(),
                  hours: _deadlineLeadHours,
                  minHours: _minDeadlineLeadHours,
                  maxHours: _maxAllowedDeadlineLeadHours,
                  onChanged: (h) => setState(() {
                    _deadlineLeadHours = h;
                    _recomputeDeadline();
                  }),
                ),
            ],
          ),

          FButton(
            onPress: saving ? null : _submit,
            child: saving
                ? const FCircularProgress()
                : Text(
                    widget.existing != null
                        ? 'lobbyHub.schedule.update'.tr()
                        : 'lobbyHub.schedule.confirm'.tr(),
                  ),
          ),
          Text(
            _costEnabled
                ? 'lobbyHub.schedule.visibilityNoteWithCost'.tr()
                : 'lobbyHub.schedule.visibilityNote'.tr(),
            style: context.theme.typography.body.sm.copyWith(
              color: colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  // ── Formatting ────────────────────────────────────────────────

  List<String> get _weekdayShort => [
    'lobbyHub.schedule.weekdaysShort.monday'.tr(),
    'lobbyHub.schedule.weekdaysShort.tuesday'.tr(),
    'lobbyHub.schedule.weekdaysShort.wednesday'.tr(),
    'lobbyHub.schedule.weekdaysShort.thursday'.tr(),
    'lobbyHub.schedule.weekdaysShort.friday'.tr(),
    'lobbyHub.schedule.weekdaysShort.saturday'.tr(),
    'lobbyHub.schedule.weekdaysShort.sunday'.tr(),
  ];
  List<String> get _weekdayLongNames => [
    'lobbyHub.schedule.weekdays.monday'.tr(),
    'lobbyHub.schedule.weekdays.tuesday'.tr(),
    'lobbyHub.schedule.weekdays.wednesday'.tr(),
    'lobbyHub.schedule.weekdays.thursday'.tr(),
    'lobbyHub.schedule.weekdays.friday'.tr(),
    'lobbyHub.schedule.weekdays.saturday'.tr(),
    'lobbyHub.schedule.weekdays.sunday'.tr(),
  ];

  String _fmtDate(DateTime d) =>
      '${_weekdayShort[d.weekday - 1]}, ${d.day}/${d.month}/${d.year}';

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _weekdayLong(int weekday) => _weekdayLongNames[weekday - 1];
}

// ── Rows specific to scheduling ─────────────────────────────────

class _CostTypePicker extends StatelessWidget {
  final ActivityCostType value;
  final ValueChanged<ActivityCostType> onChanged;

  const _CostTypePicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          _CostTypeOption(
            label: 'lobbyHub.schedule.perPerson'.tr(),
            active: value == ActivityCostType.perPax,
            onTap: () => onChanged(ActivityCostType.perPax),
          ),
          _CostTypeOption(
            label: 'lobbyHub.schedule.total'.tr(),
            active: value == ActivityCostType.total,
            onTap: () => onChanged(ActivityCostType.total),
          ),
        ],
      ),
    );
  }
}

class _CostTypeOption extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _CostTypeOption({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Expanded(
      child: FTappable(
        onPress: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: context.theme.typography.body.sm.copyWith(
              fontWeight: FontWeight.w700,
              color: active
                  ? colors.primaryForeground
                  : colors.secondaryForeground,
            ),
          ),
        ),
      ),
    );
  }
}

class _DeadlineRow extends StatelessWidget {
  final bool tooSoon;
  final bool manuallyOff;
  final DateTime? deadline;
  final ValueChanged<bool> onChanged;

  const _DeadlineRow({
    required this.tooSoon,
    required this.manuallyOff,
    required this.deadline,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final on = !tooSoon && !manuallyOff;
    final sub = tooSoon
        ? 'lobbyHub.schedule.tooSoon'.tr()
        : on
        ? 'lobbyHub.schedule.deadlineAt'.tr(
            namedArgs: {'time': _fmtAbs(deadline!)},
          )
        : 'lobbyHub.schedule.noDeadline'.tr();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(
            FLucideIcons.alarmClock,
            size: 18,
            color: colors.secondaryForeground,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'lobbyHub.schedule.deadline'.tr(),
                  style: context.theme.typography.body.sm.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  sub,
                  style: context.theme.typography.body.xs.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          Opacity(
            opacity: tooSoon ? 0.5 : 1,
            child: FSwitch(value: on, onChange: tooSoon ? null : onChanged),
          ),
        ],
      ),
    );
  }

  List<String> get _wd => [
    'lobbyHub.schedule.weekdaysShort.monday'.tr(),
    'lobbyHub.schedule.weekdaysShort.tuesday'.tr(),
    'lobbyHub.schedule.weekdaysShort.wednesday'.tr(),
    'lobbyHub.schedule.weekdaysShort.thursday'.tr(),
    'lobbyHub.schedule.weekdaysShort.friday'.tr(),
    'lobbyHub.schedule.weekdaysShort.saturday'.tr(),
    'lobbyHub.schedule.weekdaysShort.sunday'.tr(),
  ];

  String _fmtAbs(DateTime d) {
    final wd = _wd[d.weekday - 1];
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$wd, ${d.day}/${d.month} $hh:$mm';
  }
}
