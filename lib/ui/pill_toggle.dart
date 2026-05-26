import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// A compact horizontal segmented control with one selected option.
///
/// The selected pill uses `colors.primary` with a primary-tinted drop
/// shadow; inactive pills are transparent. Background color tweens
/// smoothly; the shadow itself is binary (no lerp) so the inactive pill
/// never picks up a residual shadow during the transition.
class PPillToggle<T extends Object> extends StatelessWidget {
  final T value;
  final List<PPillOption<T>> options;
  final ValueChanged<T> onChanged;

  const PPillToggle({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        // Small gap so the active pill's drop shadow can't bleed
        // sideways onto the adjacent inactive pill.
        spacing: 2,
        children: [
          for (final option in options)
            _Pill(
              icon: option.icon,
              selected: option.value == value,
              onTap: () => onChanged(option.value),
            ),
        ],
      ),
    );
  }
}

class PPillOption<T> {
  final T value;
  final IconData icon;

  const PPillOption({required this.value, required this.icon});
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  static const _duration = Duration(milliseconds: 260);
  static const _curve = Curves.easeOutCubic;

  const _Pill({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final iconColor =
        selected ? colors.primaryForeground : colors.mutedForeground;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      // Outer DecoratedBox carries the shadow and toggles it on/off
      // instantly (no interpolation). Without this, AnimatedContainer
      // would lerp the BoxShadow list, leaving a transient half-shadow
      // on the pill being de-selected mid-transition.
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.42),
                    blurRadius: 5,
                    spreadRadius: -1,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: AnimatedContainer(
          duration: _duration,
          curve: _curve,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          // Icon doesn't lerp `color` on its own, so tween it explicitly
          // along the same curve as the background.
          child: TweenAnimationBuilder<Color?>(
            duration: _duration,
            curve: _curve,
            tween: ColorTween(end: iconColor),
            builder: (_, c, _) => Icon(icon, size: 15, color: c),
          ),
        ),
      ),
    );
  }
}
