import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/model/enum.dart';
import '../../../core/model/location.dart';
import '../../../ui/district_select.dart';
import '../../../ui/search_field.dart';
import 'lobby_controller.dart';

/// Typeahead + manual-entry field for selecting a named PoI, merged into one
/// continuous form — there's no mode toggle to discover. Typing in the name
/// field searches; picking a suggestion auto-fills the structured address
/// rows below and collapses to a compact summary tile. Typing without
/// picking (or editing any field after a pick) is a valid manual entry as
/// -is — there's no separate "add" button. The caller is responsible for
/// resolving the current draft (a picked [Location] id via [onChanged], or a
/// free-text draft via [onFreeAddressChanged]) into a real `location_id` at
/// its own submit time — see `lib/core/location_repository.dart`'s
/// `resolveLocationId`.
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
  late final TextEditingController _nameCtrl;
  late final TextEditingController _streetNumberCtrl;
  late final TextEditingController _streetNameCtrl;
  City? _selectedCity;
  District? _selectedDistrict;

  /// The location the current fields cleanly correspond to, if any.
  /// Non-null renders the compact summary tile; null renders the editable
  /// form. Set by picking a typeahead suggestion, cleared the moment the
  /// user actually edits a field afterward.
  Location? _selected;

  /// Guards programmatic field writes (prefilling from a picked location on
  /// edit, or hydrating from [HomeGroundField.value]) from being mistaken
  /// for a user edit — so opening the edit view and saving without changing
  /// anything keeps reusing the original location instead of silently
  /// reporting a duplicate free-text draft.
  bool _prefilling = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _streetNumberCtrl = TextEditingController();
    _streetNameCtrl = TextEditingController();
    _hydrateFromValue();
  }

  @override
  void didUpdateWidget(covariant HomeGroundField old) {
    super.didUpdateWidget(old);
    // Re-hydrate if the caller pushed a new id in (e.g. the lobby
    // controller's data landed after first build).
    if (widget.value != old.value && _selected == null) {
      _hydrateFromValue();
    }
  }

  /// Look up the location row identified by `widget.value` so the
  /// picker can render it as already-selected on first paint.
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

  @override
  void dispose() {
    _nameCtrl.dispose();
    _streetNumberCtrl.dispose();
    _streetNameCtrl.dispose();
    super.dispose();
  }

  void _clear() {
    setState(() {
      _selected = null;
      _nameCtrl.clear();
      _streetNumberCtrl.clear();
      _streetNameCtrl.clear();
      _selectedCity = null;
      _selectedDistrict = null;
    });
    widget.onChanged('');
    widget.onFreeAddressChanged(null);
  }

  void _reportDraft() {
    widget.onChanged('');
    widget.onFreeAddressChanged({
      'locationName': _nameCtrl.text,
      'streetNumber': _streetNumberCtrl.text,
      'streetName': _streetNameCtrl.text,
      'district': _selectedDistrict?.getLocalizedFullName(context),
      'city': _selectedCity?.getLocalizedName(context),
      // Stable DB identifiers for standalone features (Freeplay) that
      // persist the structured venue instead of snapshotting display text.
      'cityCluster': _selectedCity?.dbIndex.toString(),
      'ward': _selectedDistrict?.id,
    });
  }

  void _onFieldEdited() {
    if (_prefilling) return;
    if (_selected != null) {
      setState(() => _selected = null);
    }
    _reportDraft();
  }

  void _onSuggestionSelected(Location loc) {
    _prefilling = true;
    _nameCtrl.text = loc.name;
    _streetNumberCtrl.text = loc.streetNumber ?? '';
    _streetNameCtrl.text = loc.streetName ?? '';
    _prefilling = false;
    setState(() {
      _selected = loc;
      _selectedCity = null;
      _selectedDistrict = null;
    });
    widget.onFreeAddressChanged(null);
    widget.onChanged(loc.id);
  }

  /// Reveals the editable form pre-filled from the current pick, without
  /// telling the parent anything changed yet — see [_prefilling].
  void _startEditingSelected() {
    final loc = _selected;
    if (loc == null) return;
    _prefilling = true;
    _nameCtrl.text = loc.name;
    _streetNumberCtrl.text = loc.streetNumber ?? '';
    _streetNameCtrl.text = loc.streetName ?? '';
    _prefilling = false;
    // City/district aren't reverse-mapped from the location's raw strings
    // back to an enum — the user can re-pick either if they need to change
    // it; name/street number/street name (the fields most likely to just
    // need a typo fix) stay prefilled either way.
    setState(() => _selected = null);
  }

  Widget _outerLabel(BuildContext context) {
    return Text(
      'createLobby.homeGround'.tr(),
      style: context.theme.typography.body.sm.copyWith(fontWeight: .bold),
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

    if (_selected != null) {
      final loc = _selected!;
      final fieldStyle = context.theme.textFieldStyles.md;
      final locAddr = [
        loc.streetNumber?.toString(),
        loc.streetName,
        loc.district,
        loc.city,
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
                child: _outerLabel(context),
              ),
            ),
          if (_showOuterLabel) _helperText(context),
          FTileGroup(
            children: [
              FTile(
                prefix: widget.prefixIcon != null
                    ? Icon(widget.prefixIcon)
                    : null,
                title: Text(loc.name),
                subtitle: locAddr.isNotEmpty ? Text(locAddr) : null,
                suffix: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    GestureDetector(
                      onTap: _startEditingSelected,
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
      spacing: 8,
      children: [
        if (_showOuterLabel) _outerLabel(context),
        if (_showOuterLabel) _helperText(context),
        PSearchField<Location>(
          prefixIcon: widget.prefixIcon,
          hint: 'createLobby.homeGroundHint'.tr(),
          controller: _nameCtrl,
          suggestionsBuilder: lobbyFormController.searchHomeGround,
          displayStringForOption: (loc) => loc.fullAddress ?? loc.name,
          onSuggestionSelected: _onSuggestionSelected,
          onChange: (_) => _onFieldEdited(),
          dismissLabel: 'createLobby.homeGroundDismissSuggestions'.tr(),
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
        // Structured address rows — always visible, not gated behind a
        // separate "manual entry" mode. A typeahead pick fills these in;
        // typing here directly is just as valid a way to fill them.
        Row(
          spacing: 8,
          children: [
            Expanded(
              flex: 2,
              child: FTextField(
                hint: 'createLobby.streetNumber'.tr(),
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                control: FTextFieldControl.managed(
                  controller: _streetNumberCtrl,
                  onChange: (_) => _onFieldEdited(),
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: FTextField(
                hint: 'createLobby.streetName'.tr(),
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                control: FTextFieldControl.managed(
                  controller: _streetNameCtrl,
                  onChange: (_) => _onFieldEdited(),
                ),
              ),
            ),
          ],
        ),
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
                    _onFieldEdited();
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
                    _onFieldEdited();
                  },
                ),
              ),
          ],
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
