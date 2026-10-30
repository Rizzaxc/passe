import 'package:auto_size_text/auto_size_text.dart';
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';

/// The small bordered icon + label chip in a session card's action strip
/// (Ghi chú, Chỉ đường, Thay đổi, …). Shared by the lobby's activity card and
/// the course session card so the two strips can't drift apart. Lay several
/// out in a horizontally scrolling `Row` with 6-px gaps, as both cards do.
class PQuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const PQuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: colors.mutedForeground),
            const SizedBox(width: 5),
            AutoSizeText(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: colors.secondaryForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
