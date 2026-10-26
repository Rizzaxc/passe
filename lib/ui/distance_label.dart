import 'package:easy_localization/easy_localization.dart';
import 'package:forui/forui.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/user_location.dart';

/// "≈ 2,4 km" from the user to a point.
///
/// Renders nothing when the point has no coordinates or the user's position
/// is unknown. With [promptable] it instead shows a tappable "Xem khoảng
/// cách" chip while location is unavailable, which runs the OS permission
/// flow (`UserPositionNotifier.request`) — use it on detail surfaces, not on
/// every row of a list, so scrolling never nags.
class PDistanceLabel extends ConsumerWidget {
  final double? lat;
  final double? lon;
  final bool promptable;

  const PDistanceLabel({
    super.key,
    required this.lat,
    required this.lon,
    this.promptable = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (lat == null || lon == null) return const SizedBox.shrink();
    final colors = context.theme.colors;
    final style = context.theme.typography.body.xs.copyWith(
      color: colors.mutedForeground,
    );
    final position = ref.watch(userPositionProvider);
    final label = watchDistanceLabel(ref, lat, lon);

    if (label != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Icon(
            FLucideIcons.navigation2,
            size: 12,
            color: colors.mutedForeground,
          ),
          Flexible(
            child: Text(
              'distance.away'.tr(namedArgs: {'distance': label}),
              style: style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }
    if (!promptable || position.isLoading) return const SizedBox.shrink();

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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Icon(FLucideIcons.locateFixed, size: 12, color: colors.primary),
          Flexible(
            child: Text(
              'distance.enable'.tr(),
              style: style.copyWith(color: colors.primary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
