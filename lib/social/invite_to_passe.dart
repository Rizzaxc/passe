import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../auth/auth_controller.dart';
import '../core/model/passe_user.dart';

/// The public landing page. `website/`'s index carries the store badges, so
/// it's the one link that works whether or not the recipient has the app.
const passeAppUrl = 'https://passe.vn';

/// The handle someone types into Friends ▸ search to find you.
String passeHandle(PasseUser user) => '${user.username}#${user.tagNumber}';

/// "Come play with me on Passe" — the only way to bring someone in who isn't
/// on the app yet. Carries the sender's handle so the recipient can find them
/// straight after installing (there's no deferred deep link).
Future<void> shareInviteToPasse(BuildContext context, WidgetRef ref) async {
  final user = ref.read(authControllerProvider).value;
  if (user == null || user.isGuest) return;
  final box = context.findRenderObject() as RenderBox?;
  await SharePlus.instance.share(
    ShareParams(
      text: 'social.invitePasse.shareText'.tr(
        namedArgs: {'handle': passeHandle(user), 'url': passeAppUrl},
      ),
      // iPad anchors the share popover to the caller; harmless on phones.
      sharePositionOrigin: box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size,
    ),
  );
}

/// Copy a `username#tag` handle to the clipboard with a toast.
Future<void> copyPasseHandle(BuildContext context, String handle) async {
  await Clipboard.setData(ClipboardData(text: handle));
  if (!context.mounted) return;
  showFToast(
    context: context,
    icon: const Icon(FLucideIcons.copy),
    title: Text('social.invitePasse.handleCopied'.tr()),
    alignment: .bottomCenter,
  );
}

/// A compact "invite friends to Passe" card for the Friends screen.
class InviteToPasseCard extends ConsumerWidget {
  const InviteToPasseCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    if (user == null || user.isGuest) return const SizedBox.shrink();
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        spacing: 12,
        children: [
          Icon(FLucideIcons.send, size: 20, color: colors.primary),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'social.invitePasse.title'.tr(),
                  style: typography.body.sm.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'social.invitePasse.yourHandle'.tr()),
                      TextSpan(
                        text: passeHandle(user),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.body.xs.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          FButton(
            size: .sm,
            prefix: const Icon(FLucideIcons.share2),
            onPress: () => shareInviteToPasse(context, ref),
            child: Text('social.invitePasse.share'.tr()),
          ),
        ],
      ),
    );
  }
}
