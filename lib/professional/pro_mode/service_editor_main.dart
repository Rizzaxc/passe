import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../core/format.dart';
import '../../core/icon/main.dart';
import '../../core/model/enum.dart';
import '../../core/model/timeslot.dart';
import '../../core/model/user_contact.dart';
import '../../core/state/pro_mode_state.dart';
import '../../core/timeslot_picker.dart';
import '../../profile_tab/edit_zalo_sheet.dart';
import '../../profile_tab/user_contact_controller.dart';
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
                    title: Text('homeTab.professional.mode.title'.tr()),
                    subtitle: Text(
                      'homeTab.professional.mode.backToPlayer'.tr(),
                    ),
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
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _displayNameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _scheduleNoteCtrl;
  late List<Timeslot> _schedule;

  @override
  void initState() {
    super.initState();
    _displayNameCtrl = TextEditingController(text: widget.profile.displayName);
    _bioCtrl = TextEditingController(text: widget.profile.bio);
    _phoneCtrl = TextEditingController(text: widget.profile.contactPhone);
    _scheduleNoteCtrl = TextEditingController(
      text: widget.profile.scheduleNote,
    );
    _schedule = [...widget.profile.schedule];
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _bioCtrl.dispose();
    _phoneCtrl.dispose();
    _scheduleNoteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      await ref
          .read(
            proProfileEditControllerProvider(widget.professionalId).notifier,
          )
          .commit(
            displayName: _displayNameCtrl.text.trim(),
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
          title: Text('homeTab.professional.mode.profile.saveFailed'.tr()),
          alignment: .bottomCenter,
        );
      }
      return;
    }
    if (!mounted) return;
    showFToast(
      context: context,
      icon: const Icon(FLucideIcons.check),
      title: Text('homeTab.professional.mode.profile.saved'.tr()),
      alignment: .bottomCenter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(
      proProfileEditControllerProvider(widget.professionalId),
    );
    // Same `user_contact` row user mode edits, via the same edit sheet — pro
    // mode fully replaces the player profile screen, so without this the
    // Zalo tile is unreachable while pro mode is on. `contactPhone` above is
    // a separate, unrelated field (professional.contact_details.phone).
    final myContact =
        ref.watch(userContactControllerProvider).value ?? const UserContact();

    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            FTextFormField(
              label: Text('homeTab.professional.mode.profile.displayName'.tr()),
              hint: 'homeTab.professional.mode.profile.displayNameHint'.tr(),
              description: Text(
                'homeTab.professional.mode.profile.displayNameDescription'.tr(),
              ),
              maxLength: 80,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              control: FTextFieldControl.managed(controller: _displayNameCtrl),
              validator: (value) {
                final name = value?.trim() ?? '';
                if (name.isEmpty) {
                  return 'homeTab.professional.mode.profile.displayNameRequired'
                      .tr();
                }
                if (name.length > 80) {
                  return 'homeTab.professional.mode.profile.displayNameTooLong'
                      .tr();
                }
                return null;
              },
            ),
            FTextField(
              label: Text('homeTab.professional.mode.profile.bio'.tr()),
              control: FTextFieldControl.managed(controller: _bioCtrl),
              maxLines: 4,
            ),
            FTextField(
              label: Text(
                'homeTab.professional.mode.profile.contactPhone'.tr(),
              ),
              control: FTextFieldControl.managed(controller: _phoneCtrl),
            ),
            FTileGroup(
              children: [
                FTile(
                  suffix: myContact.zaloPublic
                      ? Icon(
                          FLucideIcons.globe,
                          color: context.theme.colors.primary,
                        )
                      : null,
                  title: const SizedBox(
                    width: 32,
                    height: 32,
                    child: PasseIcons.zaloLogo,
                  ),
                  details: Text(
                    myContact.zalo ?? 'notSet'.tr(),
                    style: TextStyle(
                      color: myContact.zalo != null
                          ? context.theme.colors.primary
                          : context.theme.colors.mutedForeground,
                    ),
                  ),
                  onPress: () => showEditZaloSheet(context, myContact),
                ),
              ],
            ),
            Text(
              'homeTab.professional.mode.profile.availability'.tr(),
              style: context.theme.typography.body.sm.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (_schedule.isEmpty)
              Text(
                'homeTab.professional.mode.profile.noAvailability'.tr(),
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
              child: Text('homeTab.professional.mode.profile.addTimeslot'.tr()),
            ),
            FTextField(
              label: Text(
                'homeTab.professional.mode.profile.scheduleNote'.tr(),
              ),
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
                  : Text('homeTab.professional.mode.profile.save'.tr()),
            ),
          ],
        ),
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
                  'homeTab.professional.mode.services.mine'.tr(),
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
              'homeTab.professional.mode.services.loadFailed'.tr(),
              style: context.theme.typography.body.sm.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
            data: (services) {
              if (services.isEmpty) {
                return PEmptySectionPlaceholder(
                  title: 'homeTab.professional.mode.services.emptyTitle'.tr(),
                  subtitle: 'homeTab.professional.mode.services.emptySubtitle'
                      .tr(),
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
    final priceLabel = service.priceAmount == null
        ? null
        : (service.pricingKind == ProfessionalPricingKind.hourly
                  ? 'homeTab.professional.pricePerHour'
                  : 'homeTab.professional.pricePerSession')
              .tr(namedArgs: {'price': formatVnd(service.priceAmount!)});

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
                    'homeTab.professional.mode.services.sessionCount'.plural(
                      service.sessionCount,
                    ),
                    style: context.theme.typography.body.xs.copyWith(
                      color: colors.mutedForeground,
                    ),
                  ),
                if (service.maxParticipants != null &&
                    service.maxParticipants! > 1)
                  Text(
                    'homeTab.professional.mode.services.maxParticipants'.plural(
                      service.maxParticipants!,
                    ),
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
  ProfessionalPricingKind _pricingKind = ProfessionalPricingKind.hourly;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _typeCtrl = TextEditingController(text: e?.serviceType);
    _descCtrl = TextEditingController(text: e?.description);
    _priceCtrl = TextEditingController(
      text: e?.priceAmount?.toStringAsFixed(0),
    );
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
      _pricingKind = e.pricingKind;
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
            priceAmount: double.tryParse(_priceCtrl.text.trim()),
            minDurationMinutes: int.tryParse(_durationCtrl.text.trim()),
            maxParticipants: int.tryParse(_maxParticipantsCtrl.text.trim()),
            sessionCount: int.tryParse(_sessionCountCtrl.text.trim()) ?? 1,
            pricingKind: _pricingKind,
          );
    } catch (e, st) {
      Talker().handle(e, st, 'Service upsert failed');
      if (mounted) {
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.circleX),
          variant: .destructive,
          title: Text('homeTab.professional.mode.services.saveFailed'.tr()),
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
    return SingleChildScrollView(
      primary: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          PSheetTitle(
            label: widget.existing == null
                ? 'homeTab.professional.mode.services.add'.tr()
                : 'homeTab.professional.mode.services.edit'.tr(),
            trailing: FButton.icon(
              variant: .ghost,
              onPress: () => Navigator.of(context).pop(),
              child: const Icon(FLucideIcons.x),
            ),
          ),
          FSelect<Sport>.rich(
            hint: 'homeTab.professional.mode.services.sport'.tr(),
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
            label: Text('homeTab.professional.mode.services.name'.tr()),
            hint: 'homeTab.professional.mode.services.nameHint'.tr(),
            control: FTextFieldControl.managed(controller: _typeCtrl),
          ),
          FTextField(
            label: Text(
              'homeTab.professional.mode.services.descriptionOptional'.tr(),
            ),
            control: FTextFieldControl.managed(controller: _descCtrl),
            maxLines: 2,
          ),
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: FTextField(
                  label: Text(
                    'homeTab.professional.mode.services.durationMinutes'.tr(),
                  ),
                  control: FTextFieldControl.managed(controller: _durationCtrl),
                  keyboardType: TextInputType.number,
                ),
              ),
              Expanded(
                child: FTextField(
                  label: Text(
                    'homeTab.professional.mode.services.maxParticipantsLabel'
                        .tr(),
                  ),
                  control: FTextFieldControl.managed(
                    controller: _maxParticipantsCtrl,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          FTextField(
            label: Text(
              'homeTab.professional.mode.services.sessionCountLabel'.tr(),
            ),
            control: FTextFieldControl.managed(
              controller: _sessionCountCtrl,
              onChange: (_) => setState(() {}),
            ),
            keyboardType: TextInputType.number,
          ),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: FButton(
                  variant: _pricingKind == ProfessionalPricingKind.hourly
                      ? .primary
                      : .outline,
                  onPress: () => setState(
                    () => _pricingKind = ProfessionalPricingKind.hourly,
                  ),
                  child: Text('homeTab.professional.mode.services.hourly'.tr()),
                ),
              ),
              Expanded(
                child: FButton(
                  variant: _pricingKind == ProfessionalPricingKind.perSession
                      ? .primary
                      : .outline,
                  onPress: () => setState(
                    () => _pricingKind = ProfessionalPricingKind.perSession,
                  ),
                  child: Text(
                    'homeTab.professional.mode.services.perSession'.tr(),
                  ),
                ),
              ),
            ],
          ),
          FTextField(
            label: Text(
              _pricingKind == ProfessionalPricingKind.hourly
                  ? 'homeTab.professional.mode.services.hourlyPrice'.tr()
                  : 'homeTab.professional.mode.services.perSessionPrice'.tr(),
            ),
            control: FTextFieldControl.managed(controller: _priceCtrl),
            keyboardType: TextInputType.number,
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
                : Text('homeTab.professional.mode.services.save'.tr()),
          ),
        ],
      ),
    );
  }
}
