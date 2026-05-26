import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../ui/sheet.dart';
import 'schedule_activity_controller.dart';

/// Captain-side "schedule the next play session" flow.
///
/// Opens a form sheet asking for the date + start / end time and
/// fires the schedule mutation on the lobby's controller. The
/// controller is currently a no-op (TODO) so the user gets confirmation
/// without the row actually being persisted — wiring lands separately.
void showScheduleActivitySheet(BuildContext context, String lobbyId) {
  showPSheet(
    context: context,
    builder: (_) => _ScheduleActivitySheet(lobbyId: lobbyId),
  );
}

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
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day)
        .add(const Duration(days: 1)); // default to tomorrow
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      useRootNavigator: true,
      initialDate: _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
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
        // Snap end forward if it now precedes start.
        if (_toMinutes(_end) <= _toMinutes(_start)) {
          _end = _addHours(_start, 2);
        }
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

  Future<void> _submit() async {
    final start = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _start.hour,
      _start.minute,
    );
    final end = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _end.hour,
      _end.minute,
    );

    await ref
        .read(scheduleActivityControllerProvider(widget.lobbyId).notifier)
        .schedule(start: start, end: end);

    if (!mounted) return;
    Navigator.of(context).pop();
    showFToast(
      context: context,
      icon: const Icon(FIcons.check),
      title: const Text('Đã lên lịch buổi chơi'),
      alignment: .bottomCenter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final saving = ref.watch(
      scheduleActivityControllerProvider(widget.lobbyId),
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
              child: const Icon(FIcons.x),
            ),
          ),

          _PickerRow(
            icon: FIcons.calendar,
            label: 'Ngày',
            value: _fmtDate(_date),
            onTap: _pickDate,
          ),
          _PickerRow(
            icon: FIcons.clock,
            label: 'Bắt đầu',
            value: _fmtTime(_start),
            onTap: _pickStart,
          ),
          _PickerRow(
            icon: FIcons.clock,
            label: 'Kết thúc',
            value: _fmtTime(_end),
            onTap: _pickEnd,
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
          const SizedBox(height: 4),
          Text(
            'Mọi thành viên sẽ thấy buổi này ở Hoạt động và phải đặt cọc 10 Đá để xác nhận.',
            style: context.theme.typography.sm
                .copyWith(color: colors.mutedForeground),
          ),
        ],
      ),
    );
  }

  static const _weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  String _fmtDate(DateTime d) {
    final wd = _weekdays[d.weekday - 1];
    return '$wd, ${d.day}/${d.month}/${d.year}';
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

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
                style: context.theme.typography.sm
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              value,
              style: context.theme.typography.sm.copyWith(
                color: colors.secondaryForeground,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            Icon(FIcons.chevronRight, size: 16, color: colors.mutedForeground),
          ],
        ),
      ),
    );
  }
}
