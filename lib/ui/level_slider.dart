import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';

/// A discrete level bar: [count] segments, the first `value + 1` filled in
/// brand red. Tap or drag across it to pick when [onChanged] is set; without
/// it, it's the read-only meter (the MMR tile). One component so the level a
/// player declares and the level a lobby is rated at look like the same scale.
class PLevelSlider extends StatelessWidget {
  final int count;

  /// 0-based selected level; null = nothing chosen yet (all segments empty).
  final int? value;
  final ValueChanged<int>? onChanged;

  /// Visual bar thickness. The touch target is always at least 36 pt tall.
  final double thickness;

  const PLevelSlider({
    super.key,
    required this.count,
    required this.value,
    this.onChanged,
    this.thickness = 6,
  });

  int _indexAt(double dx, double width) =>
      (dx / width * count).floor().clamp(0, count - 1);

  void _pick(int index) {
    if (index == value) return;
    HapticFeedback.selectionClick();
    onChanged!(index);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final bar = Row(
      spacing: 4,
      children: [
        for (var i = 0; i < count; i++)
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              height: thickness,
              decoration: BoxDecoration(
                color: value != null && i <= value!
                    ? colors.primary
                    : colors.secondary,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
      ],
    );

    if (onChanged == null) return bar;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Semantics(
          slider: true,
          value: value == null ? null : '${value! + 1}/$count',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => _pick(_indexAt(d.localPosition.dx, width)),
            onHorizontalDragUpdate: (d) =>
                _pick(_indexAt(d.localPosition.dx, width)),
            child: SizedBox(
              height: 36,
              child: Align(alignment: Alignment.center, child: bar),
            ),
          ),
        );
      },
    );
  }
}
