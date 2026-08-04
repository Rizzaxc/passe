import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../ui/main.dart';
import '../model/user_payment_info.dart';
import 'payment_info_repository.dart';
import 'payment_qr_sheet.dart';

/// Fetches [recipientUserId]'s payment info and shows the right thing:
/// a toast if they haven't set any up, straight to [showPaymentQrSheet] if
/// they have exactly one, or a small picker sheet first if they have more
/// than one. Shared by the activity hero's "pay host" and the coaching
/// section's "pay coach" — both look up someone else's payment info (RLS/the
/// `get_payment_info` RPC already allows this for a friend/lobby mate — see
/// `schema/user_payment_info.sql`) and prefill a specific amount/note.
Future<void> payRecipient(
  BuildContext context, {
  required String recipientUserId,
  required num amount,
  required String note,
  required String emptyMessage,
}) async {
  List<UserPaymentInfo> entries;
  try {
    entries = await fetchUserPaymentInfo(recipientUserId);
  } catch (_) {
    if (!context.mounted) return;
    showFToast(
      context: context,
      icon: const Icon(FLucideIcons.circleX),
      variant: .destructive,
      title: Text('errorGeneric'.tr()),
      alignment: .bottomCenter,
    );
    return;
  }

  if (!context.mounted) return;

  if (entries.isEmpty) {
    showFToast(
      context: context,
      icon: const Icon(FLucideIcons.info),
      title: Text(emptyMessage),
      alignment: .bottomCenter,
    );
    return;
  }

  if (entries.length == 1) {
    await showPaymentQrSheet(context, info: entries.first, amount: amount, note: note);
    return;
  }

  final chosen = await showPSheet<UserPaymentInfo>(
    context: context,
    builder: (context) => SingleChildScrollView(
      primary: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          PSheetTitle(label: 'payment.chooseAccount'.tr()),
          FTileGroup(
            children: entries
                .map(
                  (entry) => FTile(
                    prefix: const Icon(FLucideIcons.landmark),
                    title: Text(entry.bankDisplayName),
                    subtitle: Text(entry.value),
                    onPress: () => Navigator.of(context).pop(entry),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );

  if (chosen != null && context.mounted) {
    await showPaymentQrSheet(context, info: chosen, amount: amount, note: note);
  }
}
