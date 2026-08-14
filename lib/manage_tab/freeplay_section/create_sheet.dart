import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../core/location_repository.dart';
import '../../core/model/enum.dart';
import '../../core/state/selected_sport_state.dart';
import '../../core/user_preferences.dart';
import '../../freeplay/repository.dart';
import '../../ui/main.dart';
import '../lobby_section/feed/home_ground_selector.dart';

Future<void> showCreateFreeplaySheet(BuildContext context, WidgetRef ref) =>
    showPSheet(
      context: context,
      maxHeightRatio: 1,
      builder: (_) => const _CreateFreeplayForm(),
    );

class _CreateFreeplayForm extends ConsumerStatefulWidget {
  const _CreateFreeplayForm();
  @override
  ConsumerState<_CreateFreeplayForm> createState() =>
      _CreateFreeplayFormState();
}

class _CreateFreeplayFormState extends ConsumerState<_CreateFreeplayForm> {
  static const _savedVenueKey = 'FREEPLAY_SAVED_VENUE';
  final _description = TextEditingController();
  final _capacity = TextEditingController(text: '4');
  final _malePrice = TextEditingController();
  final _femalePrice = TextEditingController();
  late DateTime _date;
  TimeOfDay _start = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 20, minute: 0);
  String? _locationId;
  Map<String, String?>? _freeVenue;
  final Set<EloSeed> _skills = {EloSeed.casual};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final todayAtDefaultStart = DateTime(now.year, now.month, now.day, 18);
    _date = now.isBefore(todayAtDefaultStart)
        ? now
        : now.add(const Duration(days: 1));
    _loadSavedVenue();
  }

  /// Seeds the venue field with the last-used location id. `HomeGroundField`
  /// hydrates and renders it as an already-picked tile on its own, so there's
  /// no separate "reuse venue" affordance to maintain here.
  Future<void> _loadSavedVenue() async {
    final value = await UserPreferences.instance.getString(_savedVenueKey);
    if (!mounted || value == null) return;
    try {
      final json = jsonDecode(value) as Map<String, dynamic>;
      final locationId = json['locationId'] as String?;
      if (locationId != null) setState(() => _locationId = locationId);
    } catch (_) {}
  }

  @override
  void dispose() {
    _description.dispose();
    _capacity.dispose();
    _malePrice.dispose();
    _femalePrice.dispose();
    super.dispose();
  }

  DateTime get _startAt =>
      DateTime(_date.year, _date.month, _date.day, _start.hour, _start.minute);
  DateTime get _endAt =>
      DateTime(_date.year, _date.month, _date.day, _end.hour, _end.minute);

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      useRootNavigator: true,
      initialDate: _date,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: DateTime(
        today.year,
        today.month,
        today.day,
      ).add(const Duration(days: 7)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final sport = ref.read(selectedSportStateProvider).value;
    final capacity = int.tryParse(_capacity.text);
    final male = double.tryParse(_malePrice.text.replaceAll(',', '.'));
    final female = double.tryParse(_femalePrice.text.replaceAll(',', '.'));
    final hasLocation =
        _locationId != null ||
        (_freeVenue?['locationName']?.trim().isNotEmpty ?? false);
    if (!_endAt.isAfter(DateTime.now())) {
      showFToast(
        context: context,
        variant: .destructive,
        title: Text('freeplay.hostManage.futureTime'.tr()),
      );
      return;
    }
    if (sport == null ||
        sport == Sport.others ||
        capacity == null ||
        capacity < 1 ||
        male == null ||
        male <= 0 ||
        female == null ||
        female <= 0 ||
        _endAt.isBefore(_startAt) ||
        _endAt == _startAt ||
        !hasLocation) {
      showFToast(
        context: context,
        variant: .destructive,
        title: Text('freeplay.hostManage.completeForm'.tr()),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final resolvedLocationId = await resolveLocationId(
        pickedId: _locationId,
        freeAddress: _freeVenue,
      );
      await ref.read(freeplayRepositoryProvider).create({
        'p_sport_id': sport.index,
        'p_start_time': _startAt.toUtc().toIso8601String(),
        'p_end_time': _endAt.toUtc().toIso8601String(),
        'p_capacity': capacity,
        'p_male_price': male,
        'p_female_price': female,
        'p_recommended_skills': _skills.map((skill) => skill.name).toList(),
        'p_description': _description.text.trim(),
        'p_location_id': resolvedLocationId,
      });
      await UserPreferences.instance.setString(
        _savedVenueKey,
        jsonEncode({'locationId': resolvedLocationId}),
      );
      ref.invalidate(hostFreeplayProvider(false));
      if (mounted) Navigator.pop(context);
    } catch (e, st) {
      Talker().handle(e, st, 'Create freeplay activity failed');
      if (mounted) {
        showFToast(
          context: context,
          variant: .destructive,
          title: Text('freeplay.hostManage.createFailed'.tr()),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        PSheetTitle(
          label: 'freeplay.hostManage.createTitle'.tr(),
          trailing: FButton.icon(
            variant: .ghost,
            onPress: () => Navigator.pop(context),
            child: const Icon(FLucideIcons.x),
          ),
        ),
        PSheetSectionLabel(label: 'freeplay.hostManage.time'.tr()),
        Row(
          children: [
            Expanded(
              child: FButton(
                variant: .outline,
                onPress: _pickDate,
                child: Text(
                  DateFormat(
                    'EEE, d/M',
                    context.locale.toLanguageTag(),
                  ).format(_date),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FButton(
                variant: .outline,
                onPress: () async {
                  final value = await showTimePicker(
                    context: context,
                    useRootNavigator: true,
                    initialTime: _start,
                  );
                  if (value != null) setState(() => _start = value);
                },
                child: Text(_start.format(context)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FButton(
                variant: .outline,
                onPress: () async {
                  final value = await showTimePicker(
                    context: context,
                    useRootNavigator: true,
                    initialTime: _end,
                  );
                  if (value != null) setState(() => _end = value);
                },
                child: Text(_end.format(context)),
              ),
            ),
          ],
        ),
        PSheetSectionLabel(label: 'freeplay.hostManage.venue'.tr()),
        // HomeGroundField hydrates and shows an already-picked tile on its
        // own when `value` resolves, so a last-used location id (seeded by
        // _loadSavedVenue) is already "reuse the saved venue" — no separate
        // chip/button needed.
        HomeGroundField(
          value: _locationId,
          prefixIcon: FLucideIcons.mapPin,
          onChanged: (id) => setState(() {
            _locationId = id.isEmpty ? null : id;
            _freeVenue = null;
          }),
          onFreeAddressChanged: (value) => setState(() {
            _freeVenue = value;
            if (value != null) _locationId = null;
          }),
        ),
        PSheetSectionLabel(label: 'freeplay.hostManage.capacityAndPrice'.tr()),
        Row(
          children: [
            Expanded(
              child: FTextField(
                label: Text('freeplay.hostManage.capacity'.tr()),
                keyboardType: TextInputType.number,
                control: FTextFieldControl.managed(controller: _capacity),
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FTextField(
                label: Text('freeplay.hostManage.male'.tr()),
                keyboardType: TextInputType.number,
                control: FTextFieldControl.managed(controller: _malePrice),
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FTextField(
                label: Text('freeplay.hostManage.female'.tr()),
                keyboardType: TextInputType.number,
                control: FTextFieldControl.managed(controller: _femalePrice),
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
              ),
            ),
          ],
        ),
        PSheetSectionLabel(label: 'freeplay.hostManage.recommendedSkill'.tr()),
        for (final skill in EloSeed.values)
          FCheckbox(
            value: _skills.contains(skill),
            label: Text(skill.getLocalizedName(context)),
            onChange: (selected) => setState(() {
              if (selected) {
                _skills.add(skill);
              } else if (_skills.length > 1) {
                _skills.remove(skill);
              }
            }),
          ),
        FTextField(
          label: Text('freeplay.hostManage.description'.tr()),
          maxLines: 5,
          control: FTextFieldControl.managed(controller: _description),
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        ),
        FButton(
          onPress: _saving ? null : _save,
          child: Text(
            _saving
                ? 'freeplay.hostManage.publishing'.tr()
                : 'freeplay.hostManage.publish'.tr(),
          ),
        ),
      ],
    ),
  );
}
