import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:forui/forui.dart';

import '../../core/model/enum.dart';
import '../../core/model/location.dart';
import '../../ui/search_field.dart';
import 'lobby_controller.dart';

/// Typeahead field for selecting a named PoI.
/// Once a location is picked the field switches to a tile display.
/// A toggle lets the user switch to free-text mode with structured address fields;
/// in that mode [onFreeAddressChanged] is called instead of [onChanged].
class HomeGroundField extends ConsumerStatefulWidget {
  final String? value;
  final ValueChanged<String> onChanged;
  final ValueChanged<Map<String, String?>?> onFreeAddressChanged;
  final String? lobbyId;

  const HomeGroundField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onFreeAddressChanged,
    this.lobbyId,
  });

  @override
  ConsumerState<HomeGroundField> createState() => _HomeGroundFieldState();
}

class _HomeGroundFieldState extends ConsumerState<HomeGroundField> {
  late final TextEditingController _controller;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _streetNumberCtrl;
  late final TextEditingController _streetNameCtrl;
  Location? _selected;
  bool _freeTextMode = false;
  City? _selectedCity;
  District? _selectedDistrict;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _nameCtrl = TextEditingController();
    _streetNumberCtrl = TextEditingController();
    _streetNameCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameCtrl.dispose();
    _streetNumberCtrl.dispose();
    _streetNameCtrl.dispose();
    super.dispose();
  }

  void _clear() {
    setState(() => _selected = null);
    _controller.clear();
    widget.onChanged('');
  }

  void _toggleMode() {
    setState(() {
      _freeTextMode = !_freeTextMode;
      _selected = null;
      _controller.clear();
      _nameCtrl.clear();
      _streetNumberCtrl.clear();
      _streetNameCtrl.clear();
      _selectedCity = null;
      _selectedDistrict = null;
    });
    if (_freeTextMode) {
      widget.onFreeAddressChanged({
        'locationName': '',
        'streetNumber': '',
        'streetName': '',
        'district': null,
        'city': null,
      });
    } else {
      widget.onFreeAddressChanged(null);
      widget.onChanged('');
    }
  }

  Widget _modeToggleIcon(BuildContext context) {
    return Positioned(
      right: 8,
      bottom: 12,
      child: FTappable(
        onPress: _toggleMode,
        child: Icon(
          _freeTextMode ? FIcons.search : FIcons.pencil,
          size: 16,
          color: context.theme.colors.mutedForeground,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lobbyFormController = ref.read(
      lobbyFormControllerProvider(widget.lobbyId).notifier,
    );

    if (_freeTextMode) {
      void notifyAddress() {
        widget.onFreeAddressChanged({
          'locationName': _nameCtrl.text,
          'streetNumber': _streetNumberCtrl.text,
          'streetName': _streetNameCtrl.text,
          'district': _selectedDistrict?.getLocalizedFullName(context),
          'city': _selectedCity?.getLocalizedName(context),
        });
      }

      void notify(_) => notifyAddress();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          // Row 1: Location name (required)
          Stack(
            children: [
              FTextField(
                label: Text('createLobby.homeGround'.tr()),
                hint: 'createLobby.homeGroundFreeHint'.tr(),
                prefixBuilder: (context, style, states) => Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 0, 4),
                  child: const Icon(FIcons.pencil),
                ),
                control: FTextFieldControl.managed(
                  controller: _nameCtrl,
                  onChange: notify,
                ),
              ),
              _modeToggleIcon(context),
            ],
          ),
          // Row 2: Street number + street name
          Row(
            spacing: 8,
            children: [
              Expanded(
                flex: 2,
                child: FTextField(
                  hint: 'createLobby.streetNumber'.tr(),
                  control: FTextFieldControl.managed(
                    controller: _streetNumberCtrl,
                    onChange: notify,
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: FTextField(
                  hint: 'createLobby.streetName'.tr(),
                  control: FTextFieldControl.managed(
                    controller: _streetNameCtrl,
                    onChange: notify,
                  ),
                ),
              ),
            ],
          ),
          // Row 3: City + District
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: FSelect<City>.rich(
                  hint: context.tr('createLobby.city'),
                  format: (city) => city.getLocalizedName(context),
                  autoHide: true,
                  control: FSelectControl.lifted(
                    value: _selectedCity,
                    onChange: (city) {
                      setState(() {
                        _selectedCity = city;
                        _selectedDistrict = null;
                      });
                      notifyAddress();
                    },
                  ),
                  children: [
                    FSelectItem<City>(
                      title: Text(City.hochiminh.getLocalizedName(context)),
                      value: City.hochiminh,
                    ),
                    FSelectItem<City>(
                      title: Text(City.hanoi.getLocalizedName(context)),
                      value: City.hanoi,
                    ),
                  ],
                ),
              ),
              if (_selectedCity != null)
                Expanded(
                  child: _SingleDistrictSelect(
                    key: ValueKey(_selectedCity),
                    city: _selectedCity!,
                    selected: _selectedDistrict,
                    onChanged: (d) {
                      setState(() => _selectedDistrict = d);
                      notifyAddress();
                    },
                  ),
                ),
            ],
          ),
        ],
      );
    }

    if (_selected != null) {
      final fieldStyle = context.theme.textFieldStyle;
      final locAddr = [
        _selected!.streetNumber?.toString(),
        _selected!.streetName,
        _selected!.district,
        _selected!.city,
      ].where((s) => s != null && s.isNotEmpty).join(', ');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Padding(
            padding: fieldStyle.labelPadding,
            child: DefaultTextStyle.merge(
              style: fieldStyle.labelTextStyle.resolve({}),
              child: Text('createLobby.homeGround'.tr()),
            ),
          ),
          FTileGroup(
            children: [
              FTile(
                title: Text(_selected!.name),
                subtitle: locAddr.isNotEmpty ? Text(locAddr) : null,
                suffix: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    GestureDetector(
                      onTap: _toggleMode,
                      child: Icon(
                        FIcons.pencil,
                        size: 16,
                        color: context.theme.colors.mutedForeground,
                      ),
                    ),
                    GestureDetector(
                      onTap: _clear,
                      child: const Icon(FIcons.x, size: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Stack(
      children: [
        PSearchField<Location>(
          label: Text('createLobby.homeGround'.tr()),
          hint: 'createLobby.homeGroundHint'.tr(),
          controller: _controller,
          suggestionsBuilder: lobbyFormController.searchHomeGround,
          displayStringForOption: (loc) => loc.fullAddress ?? loc.name,
          onSuggestionSelected: (loc) {
            setState(() => _selected = loc);
            widget.onChanged(loc.id);
          },
          onChange: widget.onChanged,
          formatSuggestion: (context, loc) {
            final locAddr = [
              loc.streetNumber,
              loc.streetName,
              loc.district,
              loc.city,
            ].where((s) => s != null && s.isNotEmpty).join(', ');
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  loc.name,
                  style: context.theme.typography.sm.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  locAddr,
                  style: context.theme.typography.xs.copyWith(
                    color: context.theme.colors.mutedForeground,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );
          },
        ),
        _modeToggleIcon(context),
      ],
    );
  }
}

class _SingleDistrictSelect extends StatelessWidget {
  final City city;
  final District? selected;
  final void Function(District?) onChanged;

  const _SingleDistrictSelect({
    required this.city,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final allDistricts = VietnamLocationData.instance.getDistrictsByCity(city);
    final groups = <VietnamDistrictType, List<District>>{};
    for (final d in allDistricts) {
      groups.putIfAbsent(d.type, () => []).add(d);
    }

    return FSelect<District>.rich(
      hint: context.tr('createLobby.district'),
      format: (d) => d.getLocalizedFullName(context),
      autoHide: true,
      control: FSelectControl.lifted(
        value: selected,
        onChange: onChanged,
      ),
      children: [
        for (final entry in groups.entries)
          FSelectSection<District>.rich(
            label: Text(context.tr('district.${entry.key.name}')),
            children: entry.value
                .map(
                  (d) => FSelectItem<District>(
                    title: Text(d.getLocalizedFullName(context)),
                    value: d,
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}
