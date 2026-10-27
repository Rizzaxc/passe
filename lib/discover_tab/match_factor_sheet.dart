import 'package:easy_localization/easy_localization.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../auth/guest_prompt.dart';
import '../core/model/enum.dart';
import '../profile_tab/age_group_selection_screen.dart';
import '../profile_tab/industry_selection_screen.dart';
import '../profile_tab/location_selection_screen.dart';
import '../profile_tab/network_selection_screen.dart';
import '../profile_tab/playtime_selection_screen.dart';
import '../profile_tab/sport_profile/sport_profile_screen.dart';
import '../router.dart';
import '../ui/main.dart';
import 'lobby_feed_card.dart' show matchFactorSpec;

/// Signature of the FitScore vibe-tag tap hook — `code` is one of
/// `LobbyFeedItem.matchFactors` (`skill|network|industry|age|gender|
/// playtime|location`), [sport] the lobby's sport (only `skill` uses it).
typedef MatchFactorTap =
    void Function(BuildContext context, String code, {Sport? sport});

/// What a lobby card's FitScore vibe tag should call when tapped.
///
/// The tags ("Chung mạng lưới", "Lịch chơi khớp"…) are the only place the app
/// shows that a profile field changes who you're matched with, and nothing
/// connected them back to the field. This explains the one factor and links
/// to the Profile screen that edits it.
const MatchFactorTap onMatchFactorTap = showMatchFactorSheet;

void showMatchFactorSheet(BuildContext context, String code, {Sport? sport}) {
  if (matchFactorSpec(code) == null) return;
  showPSheet(
    context: context,
    builder: (_) => _MatchFactorSheet(code: code, sport: sport),
  );
}

class _MatchFactorSheet extends ConsumerWidget {
  final String code;
  final Sport? sport;

  const _MatchFactorSheet({required this.code, this.sport});

  /// The Profile screen that edits the field behind [code]. Gender is an
  /// inline toggle on Profile itself, with no screen of its own; skill needs
  /// a sport to open its per-sport profile, so without one it falls back to
  /// Profile too.
  Widget? _destination() => switch (code) {
    'skill' =>
      sport == null || sport == Sport.others
          ? null
          : SportProfileScreen(sport: sport!),
    'network' => const NetworkSelectionScreen(),
    'industry' => const IndustrySelectionScreen(),
    'age' => const AgeGroupSelectionScreen(),
    'playtime' => const PlaytimeSelectionScreen(),
    'location' => const LocationSelectionScreen(),
    _ => null,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (label, icon) = matchFactorSpec(code)!;
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    void openProfile() {
      if (!ensureSignedIn(context, ref)) return;
      final screen = _destination();
      Navigator.of(context).pop();
      if (screen == null) {
        const ProfileRoute().go(context);
      } else {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
      }
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          PSheetTitle(label: 'lobby.matchFactorSheet.title'.tr()),
          Row(
            spacing: 12,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.secondary,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: colors.primary),
              ),
              Expanded(
                child: Text(
                  label,
                  style: typography.body.lg.copyWith(fontWeight: .w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            'lobby.matchFactorSheet.why.$code'.tr(),
            style: typography.body.md,
          ),
          Text(
            'lobby.matchFactorSheet.footer'.tr(),
            style: typography.body.sm.copyWith(color: colors.mutedForeground),
          ),
          const SizedBox(height: 4),
          FButton(
            prefix: const Icon(FLucideIcons.userCog),
            onPress: openProfile,
            child: Text('lobby.matchFactorSheet.cta'.tr()),
          ),
        ],
      ),
    );
  }
}
