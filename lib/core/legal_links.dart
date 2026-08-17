import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> _openLegalPage(BuildContext context, String path) async {
  var launched = false;
  try {
    launched = await launchUrl(
      Uri.https('passe.vn', path),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {
    launched = false;
  }

  if (!launched && context.mounted) {
    showFToast(
      context: context,
      icon: const Icon(FLucideIcons.circleX),
      variant: .destructive,
      title: Text('errorGeneric'.tr()),
      alignment: .bottomCenter,
    );
  }
}

/// Opens the marketing site's Terms of Service page in the device browser.
Future<void> openTermsOfService(BuildContext context) =>
    _openLegalPage(context, '/terms');

/// Opens the marketing site's Privacy Notice page in the device browser.
Future<void> openPrivacyNotice(BuildContext context) =>
    _openLegalPage(context, '/privacy');
