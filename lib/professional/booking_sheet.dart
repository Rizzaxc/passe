import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../core/format.dart';
import '../core/model/enum.dart';
import '../core/model/professional_feed_item.dart';
import '../ui/sheet.dart';
import 'booking_controller.dart';
import 'booking_location_field.dart';
import 'pending_activity_booking_state.dart';

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
  final _participantInputController = TextEditingController();

  String? _locationId;
  final List<_Participant> _participants = [];
  bool get _isCoach => widget.item.role == ProfessionalRole.coach;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _notesController.dispose();
    _participantInputController.dispose();
    super.dispose();
  }

  Future<void> _addParticipant(int maxParticipants) async {
    final input = _participantInputController.text.trim();
    if (input.isEmpty || !input.contains('#')) return;
    final parts = input.split('#');
    if (parts.length != 2) return;
    final username = parts[0];
    final tagNumber = int.tryParse(parts[1]);
    if (tagNumber == null) return;

    final response = await Supabase.instance.client
        .from('user')
        .select('id, username, tag_number')
        .eq('username', username)
        .eq('tag_number', tagNumber)
        .maybeSingle()
        .timeout(const Duration(seconds: 5));

    if (response == null) {
      if (mounted) {
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.circleX),
          variant: .destructive,
          title: const Text('Không tìm thấy người dùng này'),
          alignment: .bottomCenter,
        );
      }
      return;
    }

    final id = response['id'] as String;
    if (_participants.any((p) => p.id == id) ||
        _participants.length >= maxParticipants - 1) {
      return;
    }
    setState(() {
      _participants.add(_Participant(id: id, label: input));
      _participantInputController.clear();
    });
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
    if (_isCoach && (_locationId == null || _locationId!.isEmpty)) {
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleX),
        variant: .destructive,
        title: const Text('Vui lòng chọn hoặc đề xuất một địa điểm'),
        alignment: .bottomCenter,
      );
      return;
    }

    final durationMinutes = service.minDurationMinutes ?? 60;
    final start = _startInstant;
    final end = start.add(Duration(minutes: durationMinutes));
    final participantCount = _participants.length + 1; // + the booking client
    double? agreedRate;
    double? packageTotalPrice;
    if (service.hourlyRate != null) {
      if (service.pricingMode == 'wholesale') {
        packageTotalPrice = service.hourlyRate;
        agreedRate = service.hourlyRate;
      } else {
        final perSession = service.hourlyRate! *
            durationMinutes /
            60 *
            (service.isGroup ? participantCount : 1);
        agreedRate = perSession;
        packageTotalPrice = service.isPackage
            ? perSession * service.sessionCount
            : null;
      }
    }

    final activityId = ref
        .read(pendingActivityBookingStateProvider.notifier)
        .consume();
    // When this booking came from a lobby activity's "Đặt HLV / Trọng tài"
    // action, attach it to that activity in the slot matching this pro's role
    // (coach vs referee) — never professional_booking_id, which the
    // activity_source_exclusivity CHECK forbids on a lobby activity.
    final activityAttachColumn = activityId == null
        ? null
        : (_isCoach ? 'coach_booking_id' : 'referee_booking_id');

    try {
      await ref
          .read(professionalBookingControllerProvider(widget.item.id).notifier)
          .book(
            serviceId: service.id,
            start: start,
            end: end,
            agreedRate: agreedRate,
            notes: _notesController.text.trim(),
            locationId: _isCoach ? _locationId : null,
            participantUserIds:
                _participants.isEmpty ? null : _participants.map((p) => p.id).toList(),
            newPackageSessionCount: service.isPackage ? service.sessionCount : null,
            newPackageTotalPrice: packageTotalPrice,
            activityId: activityId,
            activityAttachColumn: activityAttachColumn,
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
                  Consumer(
                    builder: (context, ref, _) {
                      final duration = selected.minDurationMinutes ?? 60;
                      final conflictAsync = ref.watch(
                        hasBookingConflictProvider(
                          widget.item.id,
                          _startInstant,
                          _startInstant.add(Duration(minutes: duration)),
                        ),
                      );
                      final hasConflict = conflictAsync.value ?? false;
                      if (!hasConflict) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBE7D3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          spacing: 8,
                          children: [
                            const Icon(
                              FLucideIcons.triangleAlert,
                              size: 16,
                              color: Color(0xFF8E5D1F),
                            ),
                            Expanded(
                              child: Text(
                                'Khung giờ này có thể đã trùng với lịch đã xác nhận khác của ${widget.item.displayName}.',
                                style: context.theme.typography.body.xs.copyWith(
                                  color: const Color(0xFF8E5D1F),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  if (_isCoach)
                    BookingLocationField(
                      professionalId: widget.item.id,
                      value: _locationId,
                      onChanged: (id) => setState(() => _locationId = id),
                    ),
                  if (selected.isGroup)
                    _Section(
                      label: 'Người tham gia (tối đa ${selected.maxParticipants} người)',
                      children: [
                        Row(
                          spacing: 8,
                          children: [
                            Expanded(
                              child: FTextField(
                                hint: 'username#1234',
                                control: FTextFieldControl.managed(
                                  controller: _participantInputController,
                                ),
                              ),
                            ),
                            FButton(
                              variant: .outline,
                              onPress: () => _addParticipant(
                                selected.maxParticipants ?? 1,
                              ),
                              child: const Text('Thêm'),
                            ),
                          ],
                        ),
                        if (_participants.isNotEmpty)
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final p in _participants)
                                FBadge(
                                  variant: .outline,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(p.label),
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () => setState(
                                          () => _participants.remove(p),
                                        ),
                                        child: const Icon(
                                          FLucideIcons.x,
                                          size: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
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
                        : Text('Gửi Yêu Cầu${_priceSuffix(selected)}'),
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

  String _priceSuffix(ProfessionalServiceOption service) {
    if (service.hourlyRate == null) return '';
    if (service.pricingMode == 'wholesale') {
      return ' · ${formatVnd(service.hourlyRate!)}₫ trọn gói';
    }
    final duration = service.minDurationMinutes ?? 60;
    final perSession = service.hourlyRate! * duration / 60;
    if (service.isPackage) {
      return ' · ${formatVnd(perSession)}₫/buổi × ${service.sessionCount} buổi';
    }
    return ' · ${formatVnd(perSession)}₫';
  }
}

class _Participant {
  final String id;
  final String label;

  const _Participant({required this.id, required this.label});
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
              Flexible(
                child: Text(
                  service.pricingMode == 'wholesale'
                      ? '${formatVnd(service.hourlyRate!)}₫ trọn gói'
                      : service.isPackage
                      ? '${formatVnd(service.hourlyRate!)}₫/giờ · ${service.sessionCount} buổi'
                      : '${formatVnd(service.hourlyRate!)}₫/giờ',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.theme.typography.body.xs.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
