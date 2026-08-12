import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auth/auth_controller.dart';
import '../core/model/user_payment_info.dart';
import '../core/payment/payment_qr_sheet.dart';
import '../ui/main.dart';
import 'repository.dart';

Future<void> _openZalo(BuildContext context, String zalo) async {
  var launched = false;
  try {
    final deeplink = Uri.https('zalo.me', '/$zalo');
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

Future<void> showFreeplayChatSheet(
  BuildContext context,
  String requestId, {
  bool host = false,
}) => showPSheet(
  context: context,
  maxHeightRatio: 1,
  builder: (_) => _FreeplayChat(requestId: requestId, host: host),
);

class _FreeplayChat extends ConsumerStatefulWidget {
  final String requestId;
  final bool host;
  const _FreeplayChat({required this.requestId, required this.host});

  @override
  ConsumerState<_FreeplayChat> createState() => _FreeplayChatState();
}

class _FreeplayChatState extends ConsumerState<_FreeplayChat> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_controller.text.trim().isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(freeplayRepositoryProvider)
          .sendMessage(widget.requestId, _controller.text);
      _controller.clear();
      ref.invalidate(freeplayChatProvider(widget.requestId));
    } catch (_) {
      if (mounted) {
        showFToast(
          context: context,
          variant: .destructive,
          title: Text('freeplay.chat.sendFailed'.tr()),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(freeplayChatProvider(widget.requestId));
    final me = ref.watch(currentUserIdProvider);
    final counterpartZalo = ref
        .watch(freeplayChatCounterpartZaloProvider(widget.requestId))
        .value;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .72,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PSheetTitle(
            label: widget.host
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
              child: FButton(
                variant: .outline,
                size: .sm,
                prefix: const Icon(FLucideIcons.externalLink, size: 16),
                onPress: () => _openZalo(context, counterpartZalo),
                child: Text('freeplay.chat.messageViaZalo'.tr()),
              ),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: messages.when(
              loading: () => const Center(child: FCircularProgress()),
              error: (_, _) =>
                  Center(child: Text('freeplay.chat.loadFailed'.tr())),
              data: (items) => RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(freeplayChatProvider(widget.requestId));
                  await ref.read(freeplayChatProvider(widget.requestId).future);
                },
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final message = items[index];
                    if (message.kind == 'payment_info' &&
                        message.accountNumber != null) {
                      return FTile(
                        prefix: const Icon(FLucideIcons.qrCode),
                        title: Text('freeplay.chat.paymentInfo'.tr()),
                        subtitle: Text(
                          '${message.bankCode ?? ''} · ${message.accountNumber}',
                        ),
                        onPress: () => showPaymentQrSheet(
                          context,
                          info: UserPaymentInfo(
                            id: message.id,
                            bankId: message.bankCode ?? '',
                            bankDisplayName:
                                message.bankDisplayName ??
                                message.bankCode ??
                                'freeplay.chat.bank'.tr(),
                            value: message.accountNumber!,
                            accountName: message.accountName,
                            createdAt: message.createdAt,
                          ),
                        ),
                      );
                    }
                    final mine = message.senderId == me;
                    return Align(
                      alignment: mine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * .72,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: mine
                              ? context.theme.colors.primary
                              : context.theme.colors.secondary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(message.body ?? ''),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          if (widget.host)
            Align(
              alignment: Alignment.centerRight,
              child: FButton(
                variant: .ghost,
                size: .sm,
                onPress: () async {
                  try {
                    await ref
                        .read(freeplayRepositoryProvider)
                        .sharePaymentInfo(widget.requestId);
                    ref.invalidate(freeplayChatProvider(widget.requestId));
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
            ),
          Row(
            children: [
              Expanded(
                child: FTextField(
                  control: FTextFieldControl.managed(controller: _controller),
                  hint: 'freeplay.chat.messageHint'.tr(),
                  maxLines: 3,
                  minLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              FButton.icon(
                onPress: _sending ? null : _send,
                child: const Icon(FLucideIcons.send),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
