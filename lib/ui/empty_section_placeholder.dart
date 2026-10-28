import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';

class PEmptySectionPlaceholder extends StatelessWidget {
  final Widget? hero;
  final String? title;
  final String subtitle;

  /// Optional next steps under the copy (e.g. "Chỉnh bộ lọc", "Thử lại") —
  /// an empty state should point somewhere, not just describe the void.
  final List<Widget> actions;

  const PEmptySectionPlaceholder({
    super.key,
    this.hero,
    this.title,
    required this.subtitle,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hero != null) ...[hero!, const SizedBox(height: 16)],
          if (title != null) ...[
            Text(
              title!,
              style: context.theme.typography.body.xl2.copyWith(
                fontWeight: .bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
          Text(
            subtitle,
            style: context.theme.typography.body.sm.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }
}
