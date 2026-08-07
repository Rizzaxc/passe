import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../core/format.dart';
import '../../core/model/enum.dart';
import '../../core/model/timeslot.dart';
import '../../core/state/pro_mode_state.dart';
import '../../core/timeslot_picker.dart';
import '../../ui/main.dart';
import 'pro_profile_controller.dart';
import 'service_editor_controller.dart';

/// Profile tab content for a linked professional in pro mode: their own
/// service listings (packages/pricing) plus bio/contact/schedule. Replaces
/// the normal player profile sections entirely — mirrors the guest-view
/// whole-screen swap already used for `user == null || user.isGuest`.
class ProProfileView extends ConsumerWidget {
  final String professionalId;

  const ProProfileView({super.key, required this.professionalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(
      myProfessionalProfileProvider(professionalId),
    );
    final servicesAsync = ref.watch(myServicesProvider(professionalId));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(myProfessionalProfileProvider(professionalId));
        ref.invalidate(myServicesProvider(professionalId));
        await Future.wait([
          ref.read(myProfessionalProfileProvider(professionalId).future),
          ref.read(myServicesProvider(professionalId).future),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: FTileGroup(
                children: [
                  FTile(
                    prefix: const Icon(FLucideIcons.briefcaseBusiness),
                    title: const Text('Chế Độ Chuyên Gia'),
                    subtitle: const Text('Tắt để quay lại hồ sơ người chơi'),
                    details: FSwitch(
                      value: true,
                      onChange: (active) =>
                          ref.read(proModeStateProvider.notifier).set(active),
                    ),
                  ),
                ],
              ),
            ),
            profileAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => const SizedBox.shrink(),
              data: (profile) => _ProfileFieldsSection(
                professionalId: professionalId,
                profile: profile,
              ),
            ),
            const SizedBox(height: 24),
            _ServicesSection(
              professionalId: professionalId,
              servicesAsync: servicesAsync,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ─── Bio / contact / schedule ──────────────────────────────────────────────

class _ProfileFieldsSection extends ConsumerStatefulWidget {
  final String professionalId;
  final ProSelfProfile profile;

  const _ProfileFieldsSection({
    required this.professionalId,
    required this.profile,
  });

  @override
  ConsumerState<_ProfileFieldsSection> createState() =>
      _ProfileFieldsSectionState();
}

class _ProfileFieldsSectionState extends ConsumerState<_ProfileFieldsSection> {
  late final TextEditingController _bioCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _scheduleNoteCtrl;
  late List<Timeslot> _schedule;

  @override
  void initState() {
    super.initState();
    _bioCtrl = TextEditingController(text: widget.profile.bio);
    _phoneCtrl = TextEditingController(text: widget.profile.contactPhone);
    _scheduleNoteCtrl = TextEditingController(
      text: widget.profile.scheduleNote,
    );
    _schedule = [...widget.profile.schedule];
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _phoneCtrl.dispose();
    _scheduleNoteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    try {
      await ref
          .read(
            proProfileEditControllerProvider(widget.professionalId).notifier,
          )
          .commit(
            bio: _bioCtrl.text.trim(),
            contactPhone: _phoneCtrl.text.trim(),
            schedule: _schedule,
            scheduleNote: _scheduleNoteCtrl.text.trim(),
          );
    } catch (e, st) {
      Talker().handle(e, st, 'Pro profile save failed');
      if (mounted) {
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.circleX),
          variant: .destructive,
          title: const Text('Không thể lưu thông tin'),
          alignment: .bottomCenter,
        );
      }
      return;
    }
    if (!mounted) return;
    showFToast(
      context: context,
      icon: const Icon(FLucideIcons.check),
      title: const Text('Đã lưu'),
      alignment: .bottomCenter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(
      proProfileEditControllerProvider(widget.professionalId),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Text(
            widget.profile.displayName,
            style: context.theme.typography.body.xl.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          FTextField(
            label: const Text('Giới thiệu'),
            control: FTextFieldControl.managed(controller: _bioCtrl),
            maxLines: 4,
          ),
          FTextField(
            label: const Text('Số điện thoại liên hệ'),
            control: FTextFieldControl.managed(controller: _phoneCtrl),
          ),
          Text(
            'Lịch rảnh',
            style: context.theme.typography.body.sm.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (_schedule.isEmpty)
            Text(
              'Chưa có khung giờ nào',
              style: context.theme.typography.body.sm.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final t in _schedule)
                  FBadge(
                    variant: .outline,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${t.dayChunk.getShortName(context)} ${t.dayOfWeek.getFullName(context)}',
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => setState(() => _schedule.remove(t)),
                          child: const Icon(FLucideIcons.x, size: 12),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          FButton(
            variant: .outline,
            onPress: () async {
              final t = await showTimeslotPicker(context: context);
              if (t != null && !_schedule.contains(t)) {
                setState(() => _schedule.add(t));
              }
            },
            child: const Text('Thêm khung giờ'),
          ),
          FTextField(
            label: const Text('Ghi chú lịch rảnh (tuỳ chọn)'),
            control: FTextFieldControl.managed(controller: _scheduleNoteCtrl),
            maxLines: 2,
          ),
          FButton(
            onPress: saving ? null : _save,
            child: saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Lưu Thông Tin'),
          ),
        ],
      ),
    );
  }
}

// ─── Services list ──────────────────────────────────────────────────────────

class _ServicesSection extends StatelessWidget {
  final String professionalId;
  final AsyncValue<List<ProfessionalServiceRow>> servicesAsync;

  const _ServicesSection({
    required this.professionalId,
    required this.servicesAsync,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Dịch vụ của tôi',
                  style: context.theme.typography.body.lg.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              FButton.icon(
                variant: .outline,
                onPress: () => showServiceEditorSheet(
                  context,
                  professionalId: professionalId,
                ),
                child: const Icon(FLucideIcons.plus),
              ),
            ],
          ),
          servicesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => Text(
              'Không tải được danh sách dịch vụ',
              style: context.theme.typography.body.sm.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
            data: (services) {
              if (services.isEmpty) {
                return PEmptySectionPlaceholder(
                  title: 'Chưa có dịch vụ nào',
                  subtitle: 'Thêm một dịch vụ để học viên có thể đặt lịch.',
                );
              }
              return Column(
                spacing: 10,
                children: [
                  for (final s in services)
                    _ServiceCard(professionalId: professionalId, service: s),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends ConsumerWidget {
  final String professionalId;
  final ProfessionalServiceRow service;

  const _ServiceCard({required this.professionalId, required this.service});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final priceLabel = service.hourlyRate == null
        ? null
        : service.pricingMode == 'wholesale'
        ? '${formatVnd(service.hourlyRate!)}₫ trọn gói'
        : '${formatVnd(service.hourlyRate!)}₫/buổi';

    return FTappable(
      onPress: () => showServiceEditorSheet(
        context,
        professionalId: professionalId,
        existing: service,
      ),
      child: PCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 6,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    service.serviceType,
                    style: context.theme.typography.body.sm.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                FSwitch(
                  value: service.isActive,
                  onChange: (v) => ref
                      .read(
                        serviceEditorControllerProvider(
                          professionalId,
                        ).notifier,
                      )
                      .setActive(service.id, v),
                ),
              ],
            ),
            if (service.description != null && service.description!.isNotEmpty)
              Text(
                service.description!,
                style: context.theme.typography.body.xs.copyWith(
                  color: colors.mutedForeground,
                ),
              ),
            Wrap(
              spacing: 10,
              runSpacing: 4,
              children: [
                if (priceLabel != null)
                  Text(
                    priceLabel,
                    style: context.theme.typography.body.sm.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.primary,
                    ),
                  ),
                if (service.sessionCount > 1)
                  Text(
                    '${service.sessionCount} buổi',
                    style: context.theme.typography.body.xs.copyWith(
                      color: colors.mutedForeground,
                    ),
                  ),
                if (service.maxParticipants != null &&
                    service.maxParticipants! > 1)
                  Text(
                    'Tối đa ${service.maxParticipants} người',
                    style: context.theme.typography.body.xs.copyWith(
                      color: colors.mutedForeground,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Create/edit sheet ──────────────────────────────────────────────────────

void showServiceEditorSheet(
  BuildContext context, {
  required String professionalId,
  ProfessionalServiceRow? existing,
}) {
  showPSheet(
    context: context,
    builder: (_) =>
        _ServiceEditorSheet(professionalId: professionalId, existing: existing),
  );
}

class _ServiceEditorSheet extends ConsumerStatefulWidget {
  final String professionalId;
  final ProfessionalServiceRow? existing;

  const _ServiceEditorSheet({required this.professionalId, this.existing});

  @override
  ConsumerState<_ServiceEditorSheet> createState() =>
      _ServiceEditorSheetState();
}

class _ServiceEditorSheetState extends ConsumerState<_ServiceEditorSheet> {
  late final TextEditingController _typeCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _sessionCountCtrl;
  late final TextEditingController _maxParticipantsCtrl;
  Sport _sport = Sport.soccer;
  String _pricingMode = 'per_session';

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _typeCtrl = TextEditingController(text: e?.serviceType);
    _descCtrl = TextEditingController(text: e?.description);
    _priceCtrl = TextEditingController(text: e?.hourlyRate?.toStringAsFixed(0));
    _durationCtrl = TextEditingController(
      text: e?.minDurationMinutes?.toString() ?? '60',
    );
    _sessionCountCtrl = TextEditingController(
      text: (e?.sessionCount ?? 1).toString(),
    );
    _maxParticipantsCtrl = TextEditingController(
      text: e?.maxParticipants?.toString() ?? '1',
    );
    if (e != null) {
      _pricingMode = e.pricingMode;
      if (e.sportId >= 0 && e.sportId < Sport.values.length) {
        _sport = Sport.values[e.sportId];
      }
    }
  }

  @override
  void dispose() {
    _typeCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    _sessionCountCtrl.dispose();
    _maxParticipantsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_typeCtrl.text.trim().isEmpty) return;
    try {
      await ref
          .read(serviceEditorControllerProvider(widget.professionalId).notifier)
          .upsert(
            id: widget.existing?.id,
            sportId: _sport.index,
            serviceType: _typeCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            hourlyRate: double.tryParse(_priceCtrl.text.trim()),
            minDurationMinutes: int.tryParse(_durationCtrl.text.trim()),
            maxParticipants: int.tryParse(_maxParticipantsCtrl.text.trim()),
            sessionCount: int.tryParse(_sessionCountCtrl.text.trim()) ?? 1,
            pricingMode: _pricingMode,
          );
    } catch (e, st) {
      Talker().handle(e, st, 'Service upsert failed');
      if (mounted) {
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.circleX),
          variant: .destructive,
          title: const Text('Không thể lưu dịch vụ'),
          alignment: .bottomCenter,
        );
      }
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(
      serviceEditorControllerProvider(widget.professionalId),
    );
    final sessionCount = int.tryParse(_sessionCountCtrl.text) ?? 1;

    return SingleChildScrollView(
      primary: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          PSheetTitle(
            label: widget.existing == null ? 'Thêm Dịch Vụ' : 'Sửa Dịch Vụ',
            trailing: FButton.icon(
              variant: .ghost,
              onPress: () => Navigator.of(context).pop(),
              child: const Icon(FLucideIcons.x),
            ),
          ),
          FSelect<Sport>.rich(
            hint: 'Môn thể thao',
            format: (s) => s.getLocalizedName(context),
            autoHide: true,
            control: FSelectControl.lifted(
              value: _sport,
              onChange: (s) => setState(() => _sport = s ?? _sport),
            ),
            children: [
              for (final s in Sport.values.where((s) => s != Sport.others))
                FSelectItem<Sport>(
                  title: Text(s.getLocalizedName(context)),
                  value: s,
                ),
            ],
          ),
          FTextField(
            label: const Text('Tên dịch vụ'),
            hint: 'VD: 1-kèm-1, Lớp nhóm...',
            control: FTextFieldControl.managed(controller: _typeCtrl),
          ),
          FTextField(
            label: const Text('Mô tả (tuỳ chọn)'),
            control: FTextFieldControl.managed(controller: _descCtrl),
            maxLines: 2,
          ),
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: FTextField(
                  label: const Text('Thời lượng (phút)'),
                  control: FTextFieldControl.managed(controller: _durationCtrl),
                  keyboardType: TextInputType.number,
                ),
              ),
              Expanded(
                child: FTextField(
                  label: const Text('Số người tối đa'),
                  control: FTextFieldControl.managed(
                    controller: _maxParticipantsCtrl,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          FTextField(
            label: const Text('Số buổi (1 = đặt lẻ, >1 = gói buổi)'),
            control: FTextFieldControl.managed(
              controller: _sessionCountCtrl,
              onChange: (_) => setState(() {}),
            ),
            keyboardType: TextInputType.number,
          ),
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: FTextField(
                  label: Text(
                    sessionCount > 1 && _pricingMode == 'wholesale'
                        ? 'Giá trọn gói'
                        : 'Giá mỗi buổi',
                  ),
                  control: FTextFieldControl.managed(controller: _priceCtrl),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          if (sessionCount > 1)
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: FButton(
                    variant: _pricingMode == 'per_session'
                        ? .primary
                        : .outline,
                    onPress: () => setState(() => _pricingMode = 'per_session'),
                    child: const Text('Giá/buổi'),
                  ),
                ),
                Expanded(
                  child: FButton(
                    variant: _pricingMode == 'wholesale' ? .primary : .outline,
                    onPress: () => setState(() => _pricingMode = 'wholesale'),
                    child: const Text('Trọn gói'),
                  ),
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
                : const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}
