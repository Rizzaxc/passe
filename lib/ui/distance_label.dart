import 'package:easy_localization/easy_localization.dart';
import 'package:forui/forui.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/user_location.dart';

/// How [PDistanceLabel] sits in its surface.
enum PDistanceStyle {
  /// Bare "2,4 km" text for the trailing edge of a row that already names the
  /// place (a list card, a venue line). Never prompts — a list must not nag.
  inline,

  /// A rounded pill ("Cách bạn 2,4 km"), meant to float over a map or sit at
  /// the end of a detail row. With `promptable` it becomes a tappable
  /// "Xem khoảng cách" pill while location is unavailable.
  pill,
}

/// Distance from the user to a point.
///
/// Renders nothing when the point has no coordinates or the user's position
/// is unknown. The prompt runs the OS permission flow
/// (`UserPositionNotifier.request`) — use it on detail surfaces only.
class PDistanceLabel extends ConsumerWidget {
  final double? lat;
  final double? lon;
  final bool promptable;
  final PDistanceStyle style;

  const PDistanceLabel({
    super.key,
    required this.lat,
    required this.lon,
    this.promptable = false,
    this.style = PDistanceStyle.inline,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (lat == null || lon == null) return const SizedBox.shrink();
    final colors = context.theme.colors;
    final textStyle = context.theme.typography.body.xs.copyWith(
      color: colors.mutedForeground,
      fontWeight: FontWeight.w600,
    );
    final position = ref.watch(userPositionProvider);
    final label = watchDistanceLabel(ref, lat, lon);

    if (label != null) {
      if (style == PDistanceStyle.inline) {
        return Text(label, style: textStyle, maxLines: 1);
      }
      return _Pill(
        icon: FLucideIcons.navigation2,
        text: 'distance.away'.tr(namedArgs: {'distance': label}),
        color: colors.mutedForeground,
      );
    }
    if (!promptable ||
        position.isLoading ||
        !(ref.watch(locationNeedsPromptProvider).value ?? false)) {
      return const SizedBox.shrink();
    }

    return FTappable(
      onPress: () async {
        final permission = await ref
            .read(userPositionProvider.notifier)
            .request();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          if (!context.mounted) return;
          showFToast(
            context: context,
            icon: const Icon(FLucideIcons.mapPinOff),
            title: Text('distance.denied'.tr()),
            alignment: .bottomCenter,
          );
        }
      },
      child: _Pill(
        icon: FLucideIcons.locateFixed,
        text: 'distance.enable'.tr(),
        color: colors.primary,
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _Pill({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 5,
          children: [
            Icon(icon, size: 12, color: color),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.theme.typography.body.xs.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
