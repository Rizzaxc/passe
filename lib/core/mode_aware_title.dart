import 'package:easy_localization/easy_localization.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../freeplay/repository.dart';
import '../professional/controller.dart';
import '../router.dart';
import '../ui/theme.dart';
import 'state/host_mode_state.dart';
import 'state/pro_mode_state.dart';

/// Header title that says which mode Manage/Profile are rendering in.
///
/// Host and pro mode swap whole tab contents (Manage's rail, Profile's view)
/// with nothing else on screen saying so — a coach who flipped the switch
/// last week opens Manage to a "Khoá học" rail and no lobbies, with no clue
/// why. Player mode renders the plain title. Mirrors the mode resolution in
/// `ManageTab` / `ProfileTab`: a mode only counts while its account link
/// exists, and host wins if both flags are somehow set.
class ModeAwareTitle extends ConsumerWidget {
  final String title;

  const ModeAwareTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hostLinked =
        ref.watch(linkedFreeplayHostProvider).asData?.value != null;
    final hostMode = ref.watch(hostModeStateProvider).asData?.value ?? false;
    final proLinked =
        ref.watch(linkedProfessionalIdProvider).asData?.value != null;
    final proMode = ref.watch(proModeStateProvider).asData?.value ?? false;

    final String? modeKey;
    if (hostLinked && hostMode) {
      modeKey = 'mode.host';
    } else if (proLinked && proMode) {
      final isCoach = ref.watch(isLinkedCoachProvider).asData?.value ?? false;
      modeKey = isCoach ? 'mode.coach' : 'mode.referee';
    } else {
      modeKey = null;
    }

    if (modeKey == null) return Text(title);

    return Row(
      spacing: 8,
      children: [
        Flexible(
          child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        // The switches live in Profile — tapping the chip is the way out.
        FTappable(
          onPress: () => const ProfileRoute().go(context),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: pbBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text(
                modeKey.tr(),
                maxLines: 1,
                style: context.theme.typography.body.xs.copyWith(
                  color: pbBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
