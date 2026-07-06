import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../core/format.dart';
import '../core/model/professional_feed_item.dart';
import '../ui/sheet.dart';
import 'booking_controller.dart';

/// "Đặt lịch" flow: pick one of the professional's active services, a date
/// + start time, an optional note, then insert a `professional_booking` row
/// (status defaults to `requested` — the professional accepts/rejects out
/// of band; there's no in-app professional-side flow yet).
void showProfessionalBookingSheet(
  BuildContext context,
  ProfessionalFeedItem item,
) {
  showPSheet(
    context: context,
    builder: (_) => _BookingSheet(item: item),
  );
}

/// Cap on how far ahead a client can request a booking.
const _maxBookingHorizonDays = 30;

class _BookingSheet extends ConsumerStatefulWidget {
  final ProfessionalFeedItem item;

  const _BookingSheet({required this.item});

  @override
  ConsumerState<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends ConsumerState<_BookingSheet> {
  String? _serviceId;
  late DateTime _date;
  TimeOfDay _start = const TimeOfDay(hour: 18, minute: 0);
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      useRootNavigator: true,
      initialDate: _date,
      firstDate: today,
      lastDate: today.add(const Duration(days: _maxBookingHorizonDays)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickStart() async {
    final picked = await showTimePicker(
      context: context,
      useRootNavigator: true,
      initialTime: _start,
    );
    if (picked != null) setState(() => _start = picked);
  }

  DateTime get _startInstant =>
      DateTime(_date.year, _date.month, _date.day, _start.hour, _start.minute);

  Future<void> _submit(ProfessionalServiceOption service) async {
    final durationMinutes = service.minDurationMinutes ?? 60;
    final start = _startInstant;
    final end = start.add(Duration(minutes: durationMinutes));
    final agreedRate = service.hourlyRate != null
        ? service.hourlyRate! * durationMinutes / 60
        : null;

    try {
      await ref
          .read(professionalBookingControllerProvider(widget.item.id).notifier)
          .book(
            serviceId: service.id,
            start: start,
            end: end,
            agreedRate: agreedRate,
            notes: _notesController.text.trim(),
          );
    } catch (e, st) {
      Talker().handle(e, st, 'Professional booking failed');
      if (mounted) {
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.circleX),
          variant: .destructive,
          title: const Text('Không thể gửi yêu cầu đặt lịch'),
          alignment: .bottomCenter,
        );
      }
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    showFToast(
      context: context,
      icon: const Icon(FLucideIcons.check),
      title: Text('Đã gửi yêu cầu tới ${widget.item.displayName}'),
      alignment: .bottomCenter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final servicesAsync = ref.watch(
      professionalServicesProvider(widget.item.id),
    );
    final saving = ref.watch(
      professionalBookingControllerProvider(widget.item.id),
    );

    return SingleChildScrollView(
      primary: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 20,
        children: [
          PSheetTitle(
            label: 'Đặt Lịch',
            trailing: FButton.icon(
              variant: .ghost,
              onPress: () => Navigator.of(context).pop(),
              child: const Icon(FLucideIcons.x),
            ),
          ),
          servicesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => Text(
              'Không tải được danh sách dịch vụ',
              style: context.theme.typography.body.sm.copyWith(
                color: colors.mutedForeground,
              ),
            ),
            data: (services) {
              if (services.isEmpty) {
                return Text(
                  '${widget.item.displayName} chưa có dịch vụ khả dụng để đặt lịch.',
                  style: context.theme.typography.body.sm.copyWith(
                    color: colors.mutedForeground,
                  ),
                );
              }
              _serviceId ??= services.first.id;
              final selected = services.firstWhere(
                (s) => s.id == _serviceId,
                orElse: () => services.first,
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 16,
                children: [
                  _Section(
                    label: 'Dịch vụ',
                    children: [
                      for (final service in services)
                        _ServiceOption(
                          service: service,
                          selected: service.id == selected.id,
                          onTap: () => setState(() => _serviceId = service.id),
                        ),
                    ],
                  ),
                  _Section(
                    label: 'Khi nào',
                    children: [
                      _PickerRow(
                        icon: FLucideIcons.calendar,
                        label: 'Ngày',
                        value: _fmtDate(_date),
                        onTap: _pickDate,
                      ),
                      _PickerRow(
                        icon: FLucideIcons.clock,
                        label: 'Giờ bắt đầu',
                        value: _fmtTime(_start),
                        onTap: _pickStart,
                      ),
                    ],
                  ),
                  FTextField(
                    label: const Text('Ghi chú (tuỳ chọn)'),
                    hint: 'VD: sân tập, mục tiêu buổi học...',
                    control: FTextFieldControl.managed(
                      controller: _notesController,
                    ),
                    maxLines: 3,
                  ),
                  FButton(
                    onPress: saving ? null : () => _submit(selected),
                    child: saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            selected.hourlyRate != null
                                ? 'Gửi Yêu Cầu · ${formatVnd(selected.hourlyRate! * (selected.minDurationMinutes ?? 60) / 60)}₫'
                                : 'Gửi Yêu Cầu',
                          ),
                  ),
                  Text(
                    '${widget.item.displayName} sẽ xác nhận yêu cầu này. Bạn có thể huỷ ở '
                    'Quản lý trước khi được xác nhận.',
                    style: context.theme.typography.body.xs.copyWith(
                      color: colors.mutedForeground,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  static const _weekdayShort = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  String _fmtDate(DateTime d) =>
      '${_weekdayShort[d.weekday - 1]}, ${d.day}/${d.month}/${d.year}';

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

// ── Reusable rows (kept file-local — mirrors schedule_activity_sheet.dart's
// private widgets, which aren't importable across files) ──────────────────

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
                style: context.theme.typography.body.sm.copyWith(
                  fontWeight: FontWeight.w600,
                ),
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
            Icon(
              FLucideIcons.chevronRight,
              size: 16,
              color: colors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceOption extends StatelessWidget {
  final ProfessionalServiceOption service;
  final bool selected;
  final VoidCallback onTap;

  const _ServiceOption({
    required this.service,
    required this.selected,
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
          color: selected
              ? colors.primary.withValues(alpha: 0.08)
              : colors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? colors.primary : colors.border),
        ),
        child: Row(
          children: [
            Icon(
              selected ? FLucideIcons.circleCheck : FLucideIcons.circle,
              size: 18,
              color: selected ? colors.primary : colors.mutedForeground,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: 2,
                children: [
                  Text(
                    service.serviceType,
                    style: context.theme.typography.body.sm.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (service.description != null &&
                      service.description!.isNotEmpty)
                    Text(
                      service.description!,
                      style: context.theme.typography.body.xs.copyWith(
                        color: colors.mutedForeground,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (service.hourlyRate != null)
              Text(
                '${formatVnd(service.hourlyRate!)}₫/giờ',
                style: context.theme.typography.body.xs.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
