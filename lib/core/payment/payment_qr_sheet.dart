import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../ui/main.dart';
import '../model/user_payment_info.dart';
import 'preferred_sending_bank_state.dart';
import 'vietqr_bank.dart';
import 'vietqr_link_builder.dart';

/// Shows a bottom sheet with a transfer target's VietQR code, a copy button,
/// a share button, and — once the sender has picked their own banking app
/// (see [PreferredSendingBankState]) — an "open app" button that opens
/// *that* app prefilled to pay this target, not the recipient's own bank.
/// The QR itself is a universal interbank code, scannable by any app, so
/// that stays the primary way to pay regardless.
///
/// [amount]/[note] prefill the QR/deeplink for a specific payment (e.g. an
/// activity deposit or a coaching fee); omit both for a plain static display
/// of the owner's own payment info.
Future<void> showPaymentQrSheet(
  BuildContext context, {
  required UserPaymentInfo info,
  num? amount,
  String? note,
}) {
  return showPSheet(
    context: context,
    builder: (context) => _PaymentQrSheetContent(info: info, amount: amount, note: note),
  );
}

class _PaymentQrSheetContent extends ConsumerWidget {
  final UserPaymentInfo info;
  final num? amount;
  final String? note;

  const _PaymentQrSheetContent({required this.info, this.amount, this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final beneficiaryBank = vietqrBankByBin(info.bankId);
    final preferredBank = ref.watch(preferredSendingBankStateProvider).value;
    final imageUrl = buildVietqrImageUrl(
      bankId: info.bankId,
      accountNo: info.value,
      accountName: info.accountName,
      amount: amount,
      note: note,
    );
    final appDeeplink = (beneficiaryBank == null || preferredBank == null)
        ? null
        : buildVietqrAppDeeplink(
            openWith: preferredBank,
            beneficiaryBank: beneficiaryBank,
            accountNo: info.value,
            accountName: info.accountName,
            amount: amount,
            note: note,
          );

    return SingleChildScrollView(
      primary: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          PSheetTitle(
            label: info.bankDisplayName,
            trailing: FButton.icon(
              variant: .ghost,
              onPress: () => Navigator.of(context).pop(),
              child: const Icon(FLucideIcons.x),
            ),
          ),
          Text(
            '${info.value}${info.accountName != null ? ' • ${info.accountName}' : ''}',
            textAlign: TextAlign.center,
            style: context.theme.typography.body.md,
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              imageUrl,
              width: 260,
              height: 260,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : const SizedBox(
                      width: 260,
                      height: 260,
                      child: Center(child: FCircularProgress()),
                    ),
              errorBuilder: (context, error, stack) => SizedBox(
                width: 260,
                height: 260,
                child: Center(
                  child: Icon(FLucideIcons.imageOff, color: colors.mutedForeground),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 12,
            children: [
              FButton(
                variant: .outline,
                onPress: () => _copy(context),
                prefix: const Icon(FLucideIcons.copy, size: 16),
                child: Text('payment.copy'.tr()),
              ),
              FButton(
                variant: .outline,
                onPress: () => _share(context, imageUrl),
                prefix: const Icon(FLucideIcons.share2, size: 16),
                child: Text('payment.share'.tr()),
              ),
            ],
          ),
          if (appDeeplink != null) ...[
            FButton(
              onPress: () => _openApp(context, appDeeplink),
              prefix: const Icon(FLucideIcons.externalLink, size: 16),
              child: Text('payment.openInApp'.tr(args: [preferredBank!.shortName])),
            ),
            if (preferredBank.autofill)
              Text(
                'payment.autofillHint'.tr(),
                textAlign: TextAlign.center,
                style: context.theme.typography.body.xs.copyWith(
                  color: colors.mutedForeground,
                ),
              ),
          ] else if (preferredBank == null)
            FButton(
              variant: .ghost,
              onPress: () => _choosePreferredBank(context, ref),
              prefix: const Icon(FLucideIcons.landmark, size: 16),
              child: Text('payment.setPreferredBank'.tr()),
            ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: [
              Icon(FLucideIcons.triangleAlert, size: 14, color: colors.mutedForeground),
              Expanded(
                child: Text(
                  'payment.disclaimer'.tr(),
                  style: context.theme.typography.body.xs.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: info.value));
    if (!context.mounted) return;
    showFToast(
      context: context,
      icon: const Icon(FLucideIcons.copy),
      title: Text('payment.copied'.tr()),
      alignment: .bottomCenter,
    );
  }

  Future<void> _share(BuildContext context, String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl)).timeout(const Duration(seconds: 5));
      final file = XFile.fromData(
        response.bodyBytes,
        name: '${info.bankDisplayName}_qr.png',
        mimeType: 'image/png',
      );
      await SharePlus.instance.share(ShareParams(files: [file], text: info.value));
    } catch (_) {
      // Fall back to sharing the plain text/link — still useful, just no image.
      await SharePlus.instance.share(ShareParams(text: '${info.bankDisplayName}: ${info.value}\n$imageUrl'));
    }
  }

  Future<void> _openApp(BuildContext context, Uri deeplink) async {
    var launched = false;
    try {
      if (await canLaunchUrl(deeplink)) {
        launched = await launchUrl(deeplink, mode: LaunchMode.externalApplication);
      }
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

  Future<void> _choosePreferredBank(BuildContext context, WidgetRef ref) async {
    final chosen = await showPreferredSendingBankPicker(context);
    if (chosen != null) {
      ref.read(preferredSendingBankStateProvider.notifier).set(chosen);
    }
  }
}

/// Bottom sheet listing every [VietqrBank] that can be deep-linked into
/// (i.e. has an [VietqrBank.appId]), for picking a "preferred sending bank".
/// Shared by the QR sheet's inline prompt and the payment-info settings screen.
Future<VietqrBank?> showPreferredSendingBankPicker(BuildContext context) {
  final openableBanks = kVietqrBanks.where((bank) => bank.appId != null).toList();
  return showPSheet<VietqrBank>(
    context: context,
    builder: (context) => SingleChildScrollView(
      primary: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          PSheetTitle(label: 'payment.choosePreferredBank'.tr()),
          FTileGroup(
            children: openableBanks
                .map(
                  (bank) => FTile(
                    prefix: const Icon(FLucideIcons.landmark),
                    title: Text(bank.shortName),
                    onPress: () => Navigator.of(context).pop(bank),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
