import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';

import '../core/model/enum.dart';

/// One tap-to-pick pill per real sport (never [Sport.others]). Used wherever
/// a sport has to be chosen on the spot — Discover's filter, creating a lobby,
/// putting up a freeplay listing — now that there's no app-wide context
/// sport to inherit one from silently.
class PSportPicker extends StatelessWidget {
  final Sport? value;
  final ValueChanged<Sport>? onChanged;

  /// Limit the choice (e.g. to the sports a coach teaches). Defaults to all.
  final List<Sport>? options;

  const PSportPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.options,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final sports =
        options ?? Sport.values.where((s) => s != Sport.others).toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final sport in sports)
          Semantics(
            button: true,
            selected: sport == value,
            child: FTappable(
              onPress: onChanged == null ? null : () => onChanged!(sport),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                height: 36,
                padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 12, 0),
                decoration: BoxDecoration(
                  color: sport == value ? colors.primary : colors.card,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: sport == value ? colors.primary : colors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 6,
                  children: [
                    sport.getIcon(size: 10),
                    Text(
                      sport.getLocalizedName(context),
                      style: context.theme.typography.body.sm.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.0,
                        color: sport == value
                            ? colors.primaryForeground
                            : colors.foreground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
