import 'dart:async';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// A forui-styled search field with optional typeahead dropdown.
///
/// When [suggestionsBuilder] is provided, the field queries suggestions as
/// the user types and shows them in an overlay styled like FSelect.rich —
/// no Material widgets involved.
///
/// For plain search (no typeahead), omit [suggestionsBuilder].
class PSearchField<T> extends StatefulWidget {
  final String? hint;
  final Widget? label;
  final TextEditingController controller;
  final ValueChanged<String>? onChange;

  /// Optional override for the prefix icon. Defaults to a magnifier
  /// (the "this is a search field" affordance). Callers that want the
  /// field to read as a typed picker (location, person, …) can pass
  /// their own glyph here.
  final IconData? prefixIcon;

  // Typeahead
  final Future<List<T>> Function(String query)? suggestionsBuilder;
  final Widget Function(BuildContext context, T item) formatSuggestion;
  final String Function(T item)? displayStringForOption;
  final ValueChanged<T>? onSuggestionSelected;

  const PSearchField({
    super.key,
    this.hint,
    this.label,
    required this.controller,
    this.onChange,
    this.prefixIcon,
    this.suggestionsBuilder,
    this.formatSuggestion = _defaultFormat,
    this.displayStringForOption,
    this.onSuggestionSelected,
  });

  static Widget _defaultFormat(BuildContext context, dynamic item) =>
      Text(item.toString());

  @override
  State<PSearchField<T>> createState() => _PSearchFieldState<T>();
}

class _PSearchFieldState<T> extends State<PSearchField<T>> {
  final _layerLink = LayerLink();
  final _overlayController = OverlayPortalController();
  final _fieldKey = GlobalKey();

  List<T> _suggestions = [];
  bool _loading = false;
  Timer? _debounce;

  double get _fieldWidth {
    final box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    return box?.size.width ?? 0;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String text) {
    widget.onChange?.call(text);

    if (widget.suggestionsBuilder == null) return;

    _debounce?.cancel();
    if (text.trim().isEmpty) {
      _overlayController.hide();
      setState(() => _suggestions = []);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _loading = true);
      try {
        final results = await widget.suggestionsBuilder!(text.trim());
        if (!mounted) return;
        setState(() => _suggestions = results);
        if (results.isNotEmpty) {
          _overlayController.show();
        } else {
          _overlayController.hide();
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  void _select(T item) {
    _overlayController.hide();
    setState(() => _suggestions = []);
    if (widget.displayStringForOption != null) {
      widget.controller.text = widget.displayStringForOption!(item);
    }
    widget.onSuggestionSelected?.call(item);
  }

  @override
  Widget build(BuildContext context) {
    final hasTypeahead = widget.suggestionsBuilder != null;

    final field = FTextField(
      hint: widget.hint,
      label: widget.label,
      autocorrect: false,
      prefixBuilder: (context, style, states) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 0, 4),
        child: Icon(_loading
            ? Icons.hourglass_empty
            : (widget.prefixIcon ?? Icons.search)),
      ),
      suffixBuilder: (context, style, states) {
        if (widget.controller.text.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 4, 8, 4),
          child: GestureDetector(
            onTap: () {
              widget.controller.clear();
              widget.onChange?.call('');
              if (hasTypeahead) {
                _overlayController.hide();
                setState(() => _suggestions = []);
              }
            },
            child: const Icon(FLucideIcons.x),
          ),
        );
      },
      control: FTextFieldControl.managed(
        controller: widget.controller,
        onChange: (value) => _onChanged(value.text),
      ),
    );

    if (!hasTypeahead) return field;

    return OverlayPortal(
      controller: _overlayController,
      overlayChildBuilder: (context) => CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        targetAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
        offset: const Offset(0, 4),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: _fieldWidth,
            child: _SuggestionDropdown<T>(
              suggestions: _suggestions,
              formatSuggestion: widget.formatSuggestion,
              onSelected: _select,
            ),
          ),
        ),
      ),
      child: CompositedTransformTarget(
        key: _fieldKey,
        link: _layerLink,
        child: field,
      ),
    );
  }
}

class _SuggestionDropdown<T> extends StatelessWidget {
  final List<T> suggestions;
  final Widget Function(BuildContext, T) formatSuggestion;
  final ValueChanged<T> onSelected;

  const _SuggestionDropdown({
    required this.suggestions,
    required this.formatSuggestion,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final style = context.theme.style;
    final colors = context.theme.colors;

    return DecoratedBox(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: style.borderRadius.md,
          border: Border.all(color: colors.border, width: style.borderWidth),
          boxShadow: style.shadow,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: suggestions.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: colors.border,
            ),
            itemBuilder: (context, i) {
              final item = suggestions[i];
              return FTappable(
                onPress: () => onSelected(item),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  child: formatSuggestion(context, item),
                ),
              );
            },
          ),
        ),
    );
  }
}
