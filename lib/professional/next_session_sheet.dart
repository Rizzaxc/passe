import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../ui/sheet.dart';
import 'booking_controller.dart';
import 'booking_location_field.dart';
import 'professional_booking.dart';

/// Cap on how far ahead a client can schedule the next session in a package
/// — mirrors [showProfessionalBookingSheet]'s booking-sheet cap.
const _maxBookingHorizonDays = 30;

/// Rolling-package continuation: once a session completes and the package
/// isn't finished (`ProfessionalBookingItem.needsNextPackageSession`), this
/// schedules session N+1 against the same `package_id`/`service_id` —
/// participants and location are re-picked fresh each time, not locked from
/// session 1 (see grill-me decision on package edge cases).
void showNextPackageSessionSheet(
  BuildContext context, {
  required ProfessionalBookingItem booking,
}) {
  showPSheet(
    context: context,
    builder: (_) => _NextSessionSheet(booking: booking),
  );
}

class _NextSessionSheet extends ConsumerStatefulWidget {
  final ProfessionalBookingItem booking;

  const _NextSessionSheet({required this.booking});

  @override
  ConsumerState<_NextSessionSheet> createState() => _NextSessionSheetState();
}

class _NextSessionSheetState extends ConsumerState<_NextSessionSheet> {
  late DateTime _date;
  TimeOfDay _start = const TimeOfDay(hour: 18, minute: 0);
  String? _locationId;
  String? _customLocationName;
  final _participantInputController = TextEditingController();
  final List<(String id, String label)> _participants = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _participantInputController.dispose();
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

  Future<void> _addParticipant(int maxParticipants) async {
    final input = _participantInputController.text.trim();
    if (input.isEmpty || !input.contains('#')) return;
    final parts = input.split('#');
    if (parts.length != 2) return;
    final tagNumber = int.tryParse(parts[1]);
    if (tagNumber == null) return;

    final response = await Supabase.instance.client
        .from('user')
        .select('id')
        .eq('username', parts[0])
        .eq('tag_number', tagNumber)
        .maybeSingle()
        .timeout(const Duration(seconds: 5));

    if (response == null) return;
    final id = response['id'] as String;
    if (_participants.any((p) => p.$1 == id) ||
        _participants.length >= maxParticipants - 1) {
      return;
    }
    setState(() {
      _participants.add((id, input));
      _participantInputController.clear();
    });
  }

  Future<void> _submit() async {
    final serviceId = widget.booking.serviceId;
    final packageId = widget.booking.packageId;
    if (serviceId == null || packageId == null) return;
    if ((_locationId == null || _locationId!.isEmpty) &&
        (_customLocationName == null || _customLocationName!.isEmpty)) {
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleX),
        variant: .destructive,
        title: const Text('Vui lòng chọn hoặc đề xuất một địa điểm'),
        alignment: .bottomCenter,
      );
      return;
    }

    final duration = widget.booking.end.difference(widget.booking.start);
    final start = _startInstant;
    final end = start.add(duration);

    try {
      await ref
          .read(
            professionalBookingControllerProvider(
              widget.booking.professionalId,
            ).notifier,
          )
          .book(
            serviceId: serviceId,
            start: start,
            end: end,
            locationId: _locationId,
            customLocationName: _customLocationName,
            existingPackageId: packageId,
            participantUserIds: _participants.isEmpty
                ? null
                : _participants.map((p) => p.$1).toList(),
          );
    } catch (e, st) {
      Talker().handle(e, st, 'Schedule next package session failed');
      if (mounted) {
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.circleX),
          variant: .destructive,
          title: const Text('Không thể đặt buổi tiếp theo'),
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
      title: const Text('Đã gửi yêu cầu buổi tiếp theo'),
      alignment: .bottomCenter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(
      professionalBookingControllerProvider(widget.booking.professionalId),
    );
    final maxParticipants = widget.booking.maxParticipants ?? 1;
    final sessionsUsed = widget.booking.packageSessionsUsed ?? 0;
    final sessionsTotal = widget.booking.packageSessionsTotal ?? 0;

    return SingleChildScrollView(
      primary: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          PSheetTitle(
            label: 'Buổi ${sessionsUsed + 1}/$sessionsTotal',
            trailing: FButton.icon(
              variant: .ghost,
              onPress: () => Navigator.of(context).pop(),
              child: const Icon(FLucideIcons.x),
            ),
          ),
          Text(
            'Đặt buổi tiếp theo với ${widget.booking.professionalName}',
            style: context.theme.typography.body.sm.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
          ),
          FTileGroup(
            children: [
              FTile(
                prefix: const Icon(FLucideIcons.calendar),
                title: const Text('Ngày'),
                details: Text('${_date.day}/${_date.month}/${_date.year}'),
                onPress: _pickDate,
              ),
              FTile(
                prefix: const Icon(FLucideIcons.clock),
                title: const Text('Giờ bắt đầu'),
                details: Text(
                  '${_start.hour.toString().padLeft(2, '0')}:${_start.minute.toString().padLeft(2, '0')}',
                ),
                onPress: _pickStart,
              ),
            ],
          ),
          BookingLocationField(
            professionalId: widget.booking.professionalId,
            locationId: _locationId,
            customLocationName: _customLocationName,
            onChanged: (id, name) => setState(() {
              _locationId = id;
              _customLocationName = name;
            }),
          ),
          if (maxParticipants > 1) ...[
            Text(
              'Người tham gia (tối đa $maxParticipants người)',
              style: context.theme.typography.body.sm.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
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
                  onPress: () => _addParticipant(maxParticipants),
                  child: const Text('Thêm'),
                ),
              ],
            ),
          ],
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
                : const Text('Gửi Yêu Cầu'),
          ),
        ],
      ),
    );
  }
}
