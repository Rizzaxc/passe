import 'package:easy_localization/easy_localization.dart';
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_platform.dart';
import '../social/invite_to_passe.dart' show passeAppUrl;
import 'sheet.dart';

/// A mobile-only feature the web showcase build refuses. Each value carries
/// its icon; its name and a one-line "what it is" live under
/// `webGate.<name>.title` / `webGate.<name>.body`, so the sheet explains what
/// the visitor is missing rather than just saying "get the app".
enum WebGatedFeature {
  createLobby(FLucideIcons.users),
  editLobby(FLucideIcons.settings2),
  scheduleActivity(FLucideIcons.calendarPlus),
  composePost(FLucideIcons.camera),
  joinLobby(FLucideIcons.userPlus),
  challenge(FLucideIcons.swords),
  coachInquiry(FLucideIcons.graduationCap),
  freeplaySeat(FLucideIcons.ticket),
  hostFreeplay(FLucideIcons.megaphone),
  coachMode(FLucideIcons.briefcase),
  health(FLucideIcons.heartPulse);

  const WebGatedFeature(this.icon);

  final IconData icon;

  String get title => 'webGate.$name.title'.tr();
  String get body => 'webGate.$name.body'.tr();
}

/// On web, shows the get-app sheet for [feature] and returns `true` — the
/// caller should bail. A no-op returning `false` on iOS/Android. Put it at
/// the top of a gated entry point, before any other guard.
bool guardWeb(BuildContext context, WebGatedFeature feature) {
  if (!AppPlatform.isWeb) return false;
  showGetAppSheet(context, feature);
  return true;
}

Future<void> showGetAppSheet(BuildContext context, WebGatedFeature feature) =>
    showPSheet<void>(
      context: context,
      builder: (_) =>
          SingleChildScrollView(child: GetAppPanel(feature: feature)),
    );

/// The sheet's body, also used inline as the Health tab's web placeholder.
class GetAppPanel extends StatelessWidget {
  const GetAppPanel({super.key, required this.feature});

  final WebGatedFeature feature;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        Row(
          spacing: 12,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(feature.icon, size: 22, color: colors.primary),
            ),
            Expanded(child: PSheetTitle(label: feature.title)),
          ],
        ),
        Text(
          feature.body,
          style: typography.body.md.copyWith(color: colors.foreground),
        ),
        Text(
          'webGate.availableInApp'.tr(),
          style: typography.body.sm.copyWith(color: colors.mutedForeground),
        ),
        FButton(
          prefix: const Icon(FLucideIcons.smartphone),
          onPress: () => launchUrl(
            Uri.parse(passeAppUrl),
            mode: LaunchMode.externalApplication,
          ),
          child: Text('webGate.getApp'.tr()),
        ),
      ],
    );
  }
}
