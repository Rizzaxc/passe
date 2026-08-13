import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../core/icon/main.dart';
import '../core/zalo_link.dart';
import '../messaging/conversation_controller.dart';
import '../messaging/conversation_view.dart';
import '../ui/main.dart';
import 'repository.dart';

/// Freeplay seat-request chat.
///
/// The thread itself lives on the shared messaging layer (`lib/messaging/`,
/// `schema/messaging.sql`) — this sheet is just the freeplay-specific chrome
/// around it: the title, the Zalo hand-off, and the host's payment-info
/// button. It holds a *request* id, so it resolves the conversation first.
Future<void> showFreeplayChatSheet(
  BuildContext context,
  String requestId, {
  bool host = false,
}) => showPSheet(
  context: context,
  maxHeightRatio: 1,
  builder: (_) => _FreeplayChat(requestId: requestId, host: host),
);

class _FreeplayChat extends ConsumerWidget {
  final String requestId;
  final bool host;

  const _FreeplayChat({required this.requestId, required this.host});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversation = ref.watch(freeplayConversationIdProvider(requestId));
    final counterpartZalo = ref
        .watch(freeplayChatCounterpartZaloProvider(requestId))
        .value;

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .72,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PSheetTitle(
            label: host
                ? 'freeplay.chat.withPlayer'.tr()
                : 'freeplay.chat.withHost'.tr(),
            trailing: FButton.icon(
              variant: .ghost,
              onPress: () => Navigator.pop(context),
              child: const Icon(FLucideIcons.x),
            ),
          ),
          if (counterpartZalo != null)
            Align(
              alignment: Alignment.centerLeft,
              child: FButton.icon(
                variant: .outline,
                size: .sm,
                onPress: () => openZaloChat(context, counterpartZalo),
                child: const SizedBox(
                  width: 32,
                  height: 32,
                  child: PasseIcons.zaloLogo,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: conversation.when(
              loading: () => const Center(child: FCircularProgress()),
              error: (_, _) =>
                  Center(child: Text('freeplay.chat.loadFailed'.tr())),
              data: (conversationId) => ConversationView(
                conversationId: conversationId,
                composerAccessory: host
                    ? _SharePaymentInfoButton(conversationId: conversationId)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SharePaymentInfoButton extends ConsumerWidget {
  final String conversationId;

  const _SharePaymentInfoButton({required this.conversationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Align(
      alignment: Alignment.centerRight,
      child: FButton(
        variant: .ghost,
        size: .sm,
        onPress: () async {
          try {
            await ref
                .read(conversationControllerProvider(conversationId).notifier)
                .sharePaymentInfo();
          } catch (_) {
            if (context.mounted) {
              showFToast(
                context: context,
                variant: .destructive,
                title: Text('freeplay.chat.noPaymentInfo'.tr()),
              );
            }
          }
        },
        child: Text('freeplay.chat.sendPaymentInfo'.tr()),
      ),
    );
  }
}
