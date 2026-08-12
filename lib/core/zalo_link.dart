import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a Zalo chat with [zalo] (phone number) via zalo.me's universal link
/// — the Zalo app intercepts it if installed and routes straight to that
/// contact. Zalo has no usable web fallback for this: hitting `zalo.me/PHONE`
/// without the app installed lands on a login wall, not a chat ("personal
/// page sharing via link is not supported, for security reasons" per Zalo's
/// own help docs) — so this checks install state first, via the `zalosdk`
/// scheme Zalo's own SDK integration requires apps to query
/// (`LSApplicationQueriesSchemes` / Android `queries`, see
/// `ios/Runner/Info.plist` and `android/app/src/main/AndroidManifest.xml`),
/// and sends the user to install Zalo instead of that broken page when it's
/// missing, rather than attempting a link that can't work.
Future<void> openZaloChat(BuildContext context, String zalo) async {
  final installed = await canLaunchUrl(Uri.parse('zalosdk://'));

  if (!installed) {
    final storeUri = Platform.isIOS
        ? Uri.parse('https://apps.apple.com/app/id579523206')
        : Uri.parse(
            'https://play.google.com/store/apps/details?id=com.zing.zalo',
          );
    try {
      await launchUrl(storeUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Best-effort — the toast below still tells the user what happened.
    }
    if (context.mounted) {
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.info),
        title: Text('zaloNotInstalled'.tr()),
        alignment: .bottomCenter,
      );
    }
    return;
  }

  var launched = false;
  try {
    final deeplink = Uri.https('zalo.me', '/$zalo');
    launched = await launchUrl(deeplink, mode: LaunchMode.externalApplication);
  } catch (_) {
    launched = false;
  }

  if (!launched && context.mounted) {
    showFToast(
      context: context,
      icon: const Icon(FLucideIcons.circleX),
      variant: .destructive,
      title: Text('payment.openInAppFailed'.tr()),
      alignment: .bottomCenter,
    );
  }
}
