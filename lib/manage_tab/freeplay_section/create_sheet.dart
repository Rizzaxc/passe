import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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
  DateTime _date = DateTime.now();
  TimeOfDay _start = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 20, minute: 0);
  String? _locationId;
  Map<String, String?>? _freeVenue;
  Map<String, String?>? _savedFreeVenue;
  bool _usingSavedFreeVenue = false;
  final Set<EloSeed> _skills = {EloSeed.casual};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSavedVenue();
  }

  Future<void> _loadSavedVenue() async {
    final value = await UserPreferences.instance.getString(_savedVenueKey);
    if (!mounted || value == null) return;
    try {
      final json = jsonDecode(value) as Map<String, dynamic>;
      final saved = json['freeVenue'] as Map<String, dynamic>?;
      setState(() {
        _locationId = json['locationId'] as String?;
        _savedFreeVenue = saved?.map(
          (key, value) => MapEntry(key, value?.toString()),
        );
      });
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
    final free = _freeVenue;
    final street = free == null
        ? null
        : '${free['streetNumber'] ?? ''} ${free['streetName'] ?? ''}'.trim();
    final freeComplete =
        free != null &&
        (free['locationName'] ?? '').trim().isNotEmpty &&
        (street ?? '').isNotEmpty &&
        free['cityCluster'] != null &&
        free['ward'] != null;
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
        (_locationId == null && !freeComplete)) {
      showFToast(
        context: context,
        variant: .destructive,
        title: const Text('Hãy điền đủ thông tin buổi chơi'),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(freeplayRepositoryProvider).create({
        'p_sport_id': sport.index,
        'p_start_time': _startAt.toUtc().toIso8601String(),
        'p_end_time': _endAt.toUtc().toIso8601String(),
        'p_capacity': capacity,
        'p_male_price': male,
        'p_female_price': female,
        'p_recommended_skills': _skills.map((skill) => skill.name).toList(),
        'p_description': _description.text.trim(),
        'p_location_id': _locationId,
        'p_venue_name': free?['locationName'],
        'p_street_address': street,
        'p_city_cluster': free?['cityCluster'] == null
            ? null
            : int.tryParse(free!['cityCluster']!),
        'p_ward': free?['ward'],
      });
      await UserPreferences.instance.setString(
        _savedVenueKey,
        jsonEncode({'locationId': _locationId, 'freeVenue': free}),
      );
      ref.invalidate(hostFreeplayProvider(false));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        showFToast(
          context: context,
          variant: .destructive,
          title: const Text('Không tạo được buổi chơi'),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        PSheetTitle(
          label: 'Đăng vé mới',
          trailing: FButton.icon(
            variant: .ghost,
            onPress: () => Navigator.pop(context),
            child: const Icon(FLucideIcons.x),
          ),
        ),
        const PSheetSectionLabel(label: 'Thời gian'),
        Row(
          children: [
            Expanded(
              child: FButton(
                variant: .outline,
                onPress: _pickDate,
                child: Text(DateFormat('EEE, d/M', 'vi').format(_date)),
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
        const PSheetSectionLabel(label: 'Sân'),
        if (_usingSavedFreeVenue && _freeVenue != null)
          FTile(
            prefix: const Icon(FLucideIcons.mapPinned),
            title: Text(_freeVenue!['locationName'] ?? 'Sân đã lưu'),
            subtitle: Text(
              '${_freeVenue!['streetNumber'] ?? ''} ${_freeVenue!['streetName'] ?? ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            suffix: FButton.icon(
              variant: .ghost,
              onPress: () => setState(() {
                _usingSavedFreeVenue = false;
                _freeVenue = null;
              }),
              child: const Icon(FLucideIcons.x),
            ),
          )
        else ...[
          if (_savedFreeVenue != null)
            FButton(
              variant: .outline,
              onPress: () => setState(() {
                _usingSavedFreeVenue = true;
                _freeVenue = Map<String, String?>.from(_savedFreeVenue!);
                _locationId = null;
              }),
              child: Text(
                'Dùng lại ${_savedFreeVenue!['locationName'] ?? 'sân đã lưu'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
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
        ],
        const PSheetSectionLabel(label: 'Số chỗ và giá mỗi người'),
        Row(
          children: [
            Expanded(
              child: FTextField(
                label: const Text('Số chỗ'),
                keyboardType: TextInputType.number,
                control: FTextFieldControl.managed(controller: _capacity),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FTextField(
                label: const Text('Nam'),
                keyboardType: TextInputType.number,
                control: FTextFieldControl.managed(controller: _malePrice),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FTextField(
                label: const Text('Nữ'),
                keyboardType: TextInputType.number,
                control: FTextFieldControl.managed(controller: _femalePrice),
              ),
            ),
          ],
        ),
        const PSheetSectionLabel(label: 'Trình độ đề xuất'),
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
          label: const Text('Mô tả'),
          maxLines: 5,
          control: FTextFieldControl.managed(controller: _description),
        ),
        FButton(
          onPress: _saving ? null : _save,
          child: Text(_saving ? 'Đang đăng…' : 'Đăng vé'),
        ),
      ],
    ),
  );
}
