import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'theme.dart';

/// A segmented button row styled after FTab:
/// muted container background, colors.background fill for the selected segment,
/// transparent for unselected. No dividers.
///
/// Example:
/// ```dart
/// PSegmentedButton<LobbyVisibility>(
///   label: Text('Visibility'),
///   values: LobbyVisibility.values,
///   selected: visibility,
///   format: (v) => Text(v.getLocalizedName(context)),
///   description: (v) => v.getDescription(context),
///   onChange: (v) => setState(() => visibility = v),
/// )
/// ```
class PSegmentedButton<T> extends StatelessWidget {
  final Widget? label;
  final List<T> values;
  final T? selected;
  final Widget Function(T) format;
  final String Function(T)? description;
  final ValueChanged<T?> onChange;

  /// When true, tapping the active segment deselects it (calls onChange(null)).
  final bool deselectable;

  const PSegmentedButton({
    super.key,
    this.label,
    required this.values,
    required this.selected,
    required this.format,
    this.description,
    required this.onChange,
    this.deselectable = false,
  });

  static const _padding = 4.0;

  FButtonStyleDelta _styleDelta(BuildContext context, bool isSelected) {
    final r = context.theme.style.borderRadius;
    final innerRadius = Radius.circular(
      (r.topLeft.x - _padding).clamp(0.0, double.infinity),
    );
    return .delta(
      decoration: .delta([
        .all(
          .delta(
            color: isSelected
                ? context.theme.colors.background
                : Colors.transparent,
            borderRadius: BorderRadius.all(innerRadius),
          ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fieldStyle = context.theme.selectStyle.fieldStyle;
    final colors = context.theme.colors;
    final style = context.theme.style;

    final buttons = <Widget>[];
    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      final isSelected = value == selected;

      buttons.add(
        Expanded(
          child: FButton(
            variant: .ghost,
            style: _styleDelta(context, isSelected),
            onPress: () =>
                onChange(deselectable && value == selected ? null : value),
            child: IconTheme(
              data: IconThemeData(
                color: isSelected ? colors.primary : context.theme.brand.blue,
                size: 20,
              ),
              child: DefaultTextStyle(
                style: context.theme.typography.sm.copyWith(
                  color: isSelected ? colors.primary : context.theme.brand.blue,
                  overflow: TextOverflow.ellipsis,
                  fontWeight: .bold,
                ),
                maxLines: 1,
                child: format(value),
              ),
            ),
          ),
        ),
      );
    }

    final track = DecoratedBox(
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: style.borderRadius,
        border: Border.all(color: colors.muted),
      ),
      child: Padding(
        padding: const EdgeInsets.all(_padding),
        child: Row(children: buttons),
      ),
    );

    final selectedDesc = selected != null
        ? (description?.call(selected as T) ?? '')
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        if (label != null)
          Padding(
            padding: fieldStyle.labelPadding,
            child: DefaultTextStyle.merge(
              style: fieldStyle.labelTextStyle.resolve({}),
              child: label!,
            ),
          ),
        track,
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 2),
          child: Text(
            selectedDesc,
            style: context.theme.typography.xs.copyWith(
              color: colors.mutedForeground,
            ),
          ),
        ),
      ],
    );
  }
}
