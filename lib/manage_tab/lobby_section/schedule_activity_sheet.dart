import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../ui/sheet.dart';
import 'feed/home_ground_selector.dart';
import 'lobby_detail_controller.dart';
import 'schedule_activity_controller.dart';

/// Captain-side "schedule the next play session" flow.
///
/// Opens a form sheet asking for the full activity spec (date / time,
/// location, recurrence, prepayment, confirmation threshold + deadline)
/// and fires the schedule mutation on the lobby's controller. The
/// controller is currently a no-op (TODO) so the user gets confirmation
/// without the row actually being persisted — wiring lands separately.
void showScheduleActivitySheet(BuildContext context, String lobbyId) {
  showPSheet(
    context: context,
    builder: (_) => _ScheduleActivitySheet(lobbyId: lobbyId),
  );
}

/// Cap on how far ahead captains can schedule a session. Anything
/// further out should go through a recurrence template instead.
const _maxScheduleHorizonDays = 7;

/// Default "lock confirmations N days before start" used when the user
/// turns the deadline on for a session that's far enough out.
const _defaultDeadlineLeadDays = 2;

class _ScheduleActivitySheet extends ConsumerStatefulWidget {
  final String lobbyId;

  const _ScheduleActivitySheet({required this.lobbyId});

  @override
  ConsumerState<_ScheduleActivitySheet> createState() =>
      _ScheduleActivitySheetState();
}

class _ScheduleActivitySheetState
    extends ConsumerState<_ScheduleActivitySheet> {
  late DateTime _date;
  TimeOfDay _start = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 20, minute: 0);

  // Seeded from the lobby's home_ground when the lobby info resolves;
  // HomeGroundField below renders the picker UI around this id.
  String? _locationId;

  bool _recurring = false;

  bool _prepaymentRequired = false;
  ActivityPaymentType _paymentType = ActivityPaymentType.da;
  final _amountController = TextEditingController(text: '50');

  int _confirmationThreshold = 4;

  // Null = the user has manually turned the deadline off, OR the session
  // is too soon for one. Otherwise this is the chosen deadline.
  DateTime? _confirmationDeadline;
  bool _deadlineManuallyOff = false;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day)
        .add(const Duration(days: 1));
    // Lobby home ground default — populated once async info resolves.
    _seedDefaultsFromLobby();
    _recomputeDeadline();
  }

  void _seedDefaultsFromLobby() {
    // Read the cached lobby info synchronously if it's already loaded.
    // If not, the listen() in build() picks up the value once it lands.
    final info = ref.read(lobbyDetailControllerProvider(widget.lobbyId)).value;
    if (info != null) {
      _locationId = info.lobby.homeGround;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Picker helpers ────────────────────────────────────────────

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      useRootNavigator: true,
      initialDate: _date,
      firstDate: today,
      // Captains can schedule at most a week out. Anything further is a
      // recurrence concern, not an ad-hoc session.
      lastDate: today.add(const Duration(days: _maxScheduleHorizonDays)),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _recomputeDeadline();
      });
    }
  }

  Future<void> _pickStart() async {
    final picked = await showTimePicker(
      context: context,
      useRootNavigator: true,
      initialTime: _start,
    );
    if (picked != null) {
      setState(() {
        _start = picked;
        if (_toMinutes(_end) <= _toMinutes(_start)) {
          _end = _addHours(_start, 2);
        }
        _recomputeDeadline();
      });
    }
  }

  Future<void> _pickEnd() async {
    final picked = await showTimePicker(
      context: context,
      useRootNavigator: true,
      initialTime: _end,
    );
    if (picked != null) setState(() => _end = picked);
  }

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;
  TimeOfDay _addHours(TimeOfDay t, int hours) => TimeOfDay(
        hour: (t.hour + hours) % 24,
        minute: t.minute,
      );

  DateTime get _startInstant => DateTime(
        _date.year,
        _date.month,
        _date.day,
        _start.hour,
        _start.minute,
      );

  /// The session is too soon for a confirmation cutoff if start is
  /// less than the default lead time (2 days) away — the deadline UI
  /// flips off and locks.
  bool get _tooSoonForDeadline {
    final now = DateTime.now();
    return _startInstant.isBefore(
        now.add(const Duration(days: _defaultDeadlineLeadDays)));
  }

  void _recomputeDeadline() {
    if (_tooSoonForDeadline) {
      _confirmationDeadline = null;
      return;
    }
    if (_deadlineManuallyOff) {
      _confirmationDeadline = null;
      return;
    }
    // Default: 2 days before start, anchored at start_time so it lines
    // up nicely with the rest of the schedule.
    _confirmationDeadline =
        _startInstant.subtract(const Duration(days: _defaultDeadlineLeadDays));
  }

  // ── Submit ────────────────────────────────────────────────────

  Future<void> _submit() async {
    final start = _startInstant;
    final end = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _end.hour,
      _end.minute,
    );

    final amountText = _amountController.text.trim();
    final amount = _prepaymentRequired ? num.tryParse(amountText) : null;
    if (_prepaymentRequired && (amount == null || amount <= 0)) {
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleAlert),
        variant: .destructive,
        title: const Text('Số tiền đặt cọc không hợp lệ'),
        alignment: .bottomCenter,
      );
      return;
    }

    // Day-of-week ISO ordering: Mon=0 … Sun=6. DateTime.weekday is
    // 1..7 (Mon..Sun) so subtract one.
    final dayOfWeek = _recurring ? _date.weekday - 1 : null;

    await ref
        .read(scheduleActivityControllerProvider(widget.lobbyId).notifier)
        .schedule(
          start: start,
          end: end,
          locationId: _locationId,
          prepaymentRequired: _prepaymentRequired,
          paymentType: _prepaymentRequired ? _paymentType : null,
          prepaymentAmount: amount,
          confirmationThreshold: _confirmationThreshold,
          confirmationDeadline: _confirmationDeadline,
          recurrenceDayOfWeek: dayOfWeek,
        );

    if (!mounted) return;
    Navigator.of(context).pop();
    showFToast(
      context: context,
      icon: const Icon(FLucideIcons.check),
      title: const Text('Đã lên lịch buổi chơi'),
      alignment: .bottomCenter,
    );
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final saving = ref.watch(
      scheduleActivityControllerProvider(widget.lobbyId),
    );

    // Re-seed location once the lobby info async value lands.
    ref.listen<AsyncValue<LobbyDetailInfo>>(
      lobbyDetailControllerProvider(widget.lobbyId),
      (prev, next) {
        final info = next.value;
        if (info != null && _locationId == null) {
          setState(() => _locationId = info.lobby.homeGround);
        }
      },
    );

    return SingleChildScrollView(
      controller: _scrollController,
      primary: false,
      child: Column(
        spacing: 20,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PSheetTitle(
            label: 'Lên Lịch Buổi Chơi',
            trailing: FButton.icon(
              variant: .ghost,
              onPress: () => Navigator.of(context).pop(),
              child: const Icon(FLucideIcons.x),
            ),
          ),

          // ── Time & place section ────────────────────────────
          _Section(
            label: 'Khi nào & ở đâu',
            children: [
              _PickerRow(
                icon: FLucideIcons.calendar,
                label: 'Ngày',
                value: _fmtDate(_date),
                onTap: _pickDate,
              ),
              _PickerRow(
                icon: FLucideIcons.clock,
                label: 'Bắt đầu',
                value: _fmtTime(_start),
                onTap: _pickStart,
              ),
              _PickerRow(
                icon: FLucideIcons.clock,
                label: 'Kết thúc',
                value: _fmtTime(_end),
                onTap: _pickEnd,
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
                }),
                // Activities can't point at an ad-hoc address yet —
                // schema currently only stores `location_id`. If the
                // user lands in free-text mode we just drop the
                // selection so the row reverts to "no location" until
                // they pick a real one.
                onFreeAddressChanged: (_) => setState(() {
                  _locationId = null;
                }),
              ),
              _SwitchRow(
                icon: FLucideIcons.repeat,
                label: 'Lặp lại hằng tuần',
                sub: _recurring
                    ? 'Vào ${_weekdayLong(_date.weekday)} hằng tuần'
                    : 'Chỉ một lần',
                value: _recurring,
                onChanged: (v) => setState(() => _recurring = v),
              ),
            ],
          ),

          // ── Prepayment section ──────────────────────────────
          _Section(
            label: 'Đặt cọc',
            children: [
              _SwitchRow(
                icon: FLucideIcons.wallet,
                label: 'Yêu cầu đặt cọc trước',
                sub: _prepaymentRequired
                    ? 'Thành viên phải đặt cọc để xác nhận'
                    : 'Xác nhận miễn phí',
                value: _prepaymentRequired,
                onChanged: (v) => setState(() => _prepaymentRequired = v),
              ),
              if (_prepaymentRequired) ...[
                _PaymentTypePicker(
                  value: _paymentType,
                  onChanged: (v) => setState(() => _paymentType = v),
                ),
                _AmountRow(
                  controller: _amountController,
                  suffix: _paymentType == ActivityPaymentType.da ? 'Đá' : 'đ',
                ),
              ],
            ],
          ),

          // ── Confirmation section ────────────────────────────
          _Section(
            label: 'Xác nhận tham gia',
            children: [
              _ThresholdRow(
                value: _confirmationThreshold,
                onChanged: (v) =>
                    setState(() => _confirmationThreshold = v),
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
          ),

          FButton(
            onPress: saving ? null : _submit,
            child: saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Xác Nhận Lịch'),
          ),
          Text(
            'Mọi thành viên sẽ thấy buổi này ở Hoạt động và '
            '${_prepaymentRequired ? "phải đặt cọc" : "có thể xác nhận"} '
            'để tham gia.',
            style: context.theme.typography.body.sm
                .copyWith(color: colors.mutedForeground),
          ),
        ],
      ),
    );
  }

  // ── Formatting ────────────────────────────────────────────────

  static const _weekdayShort = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  static const _weekdayLongNames = [
    'Thứ Hai',
    'Thứ Ba',
    'Thứ Tư',
    'Thứ Năm',
    'Thứ Sáu',
    'Thứ Bảy',
    'Chủ Nhật',
  ];

  String _fmtDate(DateTime d) =>
      '${_weekdayShort[d.weekday - 1]}, ${d.day}/${d.month}/${d.year}';

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _weekdayLong(int weekday) => _weekdayLongNames[weekday - 1];
}

// ── Generic section wrapper ─────────────────────────────────────

class _Section extends StatelessWidget {
  final String label;
  final List<Widget> children;

  const _Section({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PSheetSectionLabel(label: label),
        const SizedBox(height: 8),
        ...List.generate(children.length, (i) {
          if (i == 0) return children[i];
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: children[i],
          );
        }),
      ],
    );
  }
}

// ── Reusable rows ───────────────────────────────────────────────

class _PickerRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _PickerRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return FTappable(
      onPress: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: colors.secondaryForeground),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: context.theme.typography.body.sm
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Flexible(
              child: Text(
                value,
                style: context.theme.typography.body.sm.copyWith(
                  color: colors.secondaryForeground,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Icon(FLucideIcons.chevronRight, size: 16, color: colors.mutedForeground),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sub;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.icon,
    required this.label,
    this.sub,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.secondaryForeground),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: context.theme.typography.body.sm
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                if (sub != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    sub!,
                    style: context.theme.typography.body.xs
                        .copyWith(color: colors.mutedForeground),
                  ),
                ],
              ],
            ),
          ),
          FSwitch(
            value: value,
            onChange: onChanged,
          ),
        ],
      ),
    );
  }
}

class _PaymentTypePicker extends StatelessWidget {
  final ActivityPaymentType value;
  final ValueChanged<ActivityPaymentType> onChanged;

  const _PaymentTypePicker({required this.value, required this.onChanged});

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
          _PaymentTypeOption(
            label: 'Đá (app)',
            active: value == ActivityPaymentType.da,
            onTap: () => onChanged(ActivityPaymentType.da),
          ),
          _PaymentTypeOption(
            label: 'Thủ công',
            active: value == ActivityPaymentType.manual,
            onTap: () => onChanged(ActivityPaymentType.manual),
          ),
        ],
      ),
    );
  }
}

class _PaymentTypeOption extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _PaymentTypeOption({
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
              color:
                  active ? colors.primaryForeground : colors.secondaryForeground,
            ),
          ),
        ),
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final TextEditingController controller;
  final String suffix;

  const _AmountRow({required this.controller, required this.suffix});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Row(
      children: [
        Expanded(
          child: FTextField(
            label: const Text('Số tiền'),
            hint: '50',
            control: FTextFieldControl.managed(controller: controller),
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Text(
            suffix,
            style: context.theme.typography.body.sm.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.secondaryForeground,
            ),
          ),
        ),
      ],
    );
  }
}

class _ThresholdRow extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _ThresholdRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(FLucideIcons.users, size: 18, color: colors.secondaryForeground),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ngưỡng xác nhận',
                  style: context.theme.typography.body.sm
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Buổi chơi chính thức khi đủ số người',
                  style: context.theme.typography.body.xs
                      .copyWith(color: colors.mutedForeground),
                ),
              ],
            ),
          ),
          _StepperButton(
            icon: FLucideIcons.minus,
            onTap: value > 2 ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: context.theme.typography.body.lg.copyWith(
                fontWeight: FontWeight.w800,
                color: colors.foreground,
              ),
            ),
          ),
          _StepperButton(
            icon: FLucideIcons.plus,
            onTap: value < 30 ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepperButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final enabled = onTap != null;
    return FTappable(
      onPress: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: enabled ? colors.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 14,
          color: enabled ? colors.foreground : colors.mutedForeground,
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
        ? 'Buổi quá gần (<2 ngày) — tắt sẵn'
        : on
            ? 'Hạn: ${_fmtAbs(deadline!)}'
            : 'Không có hạn chót';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(FLucideIcons.alarmClock, size: 18, color: colors.secondaryForeground),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hạn chót xác nhận',
                  style: context.theme.typography.body.sm
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  sub,
                  style: context.theme.typography.body.xs
                      .copyWith(color: colors.mutedForeground),
                ),
              ],
            ),
          ),
          Opacity(
            opacity: tooSoon ? 0.5 : 1,
            child: FSwitch(
              value: on,
              onChange: tooSoon ? null : onChanged,
            ),
          ),
        ],
      ),
    );
  }

  static const _wd = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  String _fmtAbs(DateTime d) {
    final wd = _wd[d.weekday - 1];
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$wd, ${d.day}/${d.month} $hh:$mm';
  }
}
