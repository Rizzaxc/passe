import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/model/enum.dart';
import '../../../core/model/location.dart';
import '../../../ui/district_select.dart';
import '../../../ui/pill_toggle.dart';
import '../../../ui/search_field.dart';
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

  /// When set, the picker hides its outer "Sân Nhà" label and shows
  /// this glyph as the in-field prefix instead. Use this when the
  /// surrounding sheet already has a section title (e.g. "Khi nào & ở
  /// đâu" on the activity-scheduling sheet), so a separate label
  /// would be redundant.
  final IconData? prefixIcon;

  const HomeGroundField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onFreeAddressChanged,
    this.lobbyId,
    this.prefixIcon,
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
    _controller = TextEditingController()..addListener(_onControllerChanged);
    _nameCtrl = TextEditingController()..addListener(_onControllerChanged);
    _streetNumberCtrl = TextEditingController();
    _streetNameCtrl = TextEditingController();
    _hydrateFromValue();
  }

  @override
  void didUpdateWidget(covariant HomeGroundField old) {
    super.didUpdateWidget(old);
    // Re-hydrate if the caller pushed a new id in (e.g. the lobby
    // controller's data landed after first build).
    if (widget.value != old.value && _selected == null && !_freeTextMode) {
      _hydrateFromValue();
    }
  }

  /// Look up the location row identified by `widget.value` so the
  /// picker can render it as already-selected on first paint. The
  /// previous behavior was to ignore the prop entirely and force the
  /// user to re-search even when they were just defaulting to the
  /// lobby's existing home ground.
  Future<void> _hydrateFromValue() async {
    final id = widget.value;
    if (id == null || id.isEmpty) return;

    try {
      final row = await Supabase.instance.client
          .from('location')
          .select()
          .eq('id', id)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));
      if (!mounted || row == null) return;
      setState(() => _selected = Location.fromJson(row));
    } catch (_) {
      // Soft-fail — the picker just stays in its search state, the
      // user can re-pick. We don't want this to crash the host sheet.
    }
  }

  /// Whether the picker renders its own "Sân Nhà" label above the
  /// field. False when the caller has supplied a [prefixIcon], on the
  /// assumption the surrounding section title is doing the labelling.
  bool get _showOuterLabel => widget.prefixIcon == null;

  void _onControllerChanged() => setState(() {});

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

  Widget _modeToggle(BuildContext context) {
    return PPillToggle<bool>(
      value: _freeTextMode,
      options: const [
        PPillOption(value: false, icon: FLucideIcons.search),
        PPillOption(value: true, icon: FLucideIcons.pencil),
      ],
      onChanged: (freeText) {
        if (freeText != _freeTextMode) _toggleMode();
      },
    );
  }

  Widget _labelRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_showOuterLabel)
          Text(
            'createLobby.homeGround'.tr(),
            style: context.theme.typography.body.sm.copyWith(fontWeight: .bold),
          )
        else
          const SizedBox.shrink(),
        _modeToggle(context),
      ],
    );
  }

  Widget _helperText(BuildContext context) {
    return Text(
      'createLobby.homeGroundDescription'.tr(),
      style: context.theme.typography.body.xs.copyWith(
        color: context.theme.colors.mutedForeground,
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
          _labelRow(context),
          if (_showOuterLabel) _helperText(context),
          // Row 1: Location name (required)
          FTextField(
            hint: 'createLobby.homeGroundFreeHint'.tr(),
            prefixBuilder: (context, style, states) => Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 0, 4),
              child: Icon(widget.prefixIcon ?? FLucideIcons.pencil),
            ),
            control: FTextFieldControl.managed(
              controller: _nameCtrl,
              onChange: notify,
            ),
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
      final fieldStyle = context.theme.textFieldStyles.md;
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
          if (_showOuterLabel)
            Padding(
              padding: fieldStyle.labelPadding,
              child: DefaultTextStyle.merge(
                style: fieldStyle.labelTextStyle.resolve({}),
                child: Text(
                  'createLobby.homeGround'.tr(),
                  style: context.theme.typography.body.sm.copyWith(
                    fontWeight: .bold,
                  ),
                ),
              ),
            ),
          if (_showOuterLabel) _helperText(context),
          FTileGroup(
            children: [
              FTile(
                prefix: widget.prefixIcon != null
                    ? Icon(widget.prefixIcon)
                    : null,
                title: Text(_selected!.name),
                subtitle: locAddr.isNotEmpty ? Text(locAddr) : null,
                suffix: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    GestureDetector(
                      onTap: _toggleMode,
                      child: Icon(
                        FLucideIcons.pencil,
                        size: 16,
                        color: context.theme.colors.mutedForeground,
                      ),
                    ),
                    GestureDetector(
                      onTap: _clear,
                      child: const Icon(FLucideIcons.x, size: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        _labelRow(context),
        if (_showOuterLabel) _helperText(context),
        PSearchField<Location>(
          prefixIcon: widget.prefixIcon,
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
                  style: context.theme.typography.body.sm.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  locAddr,
                  style: context.theme.typography.body.xs.copyWith(
                    color: context.theme.colors.mutedForeground,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );
          },
        ),
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
    // 102-126 flat wards per city is too long to scroll — .searchBuilder adds
    // a search field, still grouped by legacy quận/huyện via districtSections.
    return FSelect<District>.searchBuilder(
      hint: context.tr('createLobby.district'),
      format: (d) => d.getLocalizedFullName(context),
      autoHide: true,
      control: FSelectControl.lifted(value: selected, onChange: onChanged),
      searchFieldProperties: districtSearchFieldProperties(context),
      contentEmptyBuilder: (context, _) => districtEmptyBuilder(context),
      filter: (query) =>
          VietnamLocationData.instance.searchDistricts(city, query),
      contentBuilder: (context, query, values) => districtSections<District>(
        context: context,
        values: values,
        toDistrict: (d) => d,
        isSelected: (d) => d == selected,
      ),
    );
  }
}
