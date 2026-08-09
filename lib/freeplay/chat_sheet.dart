import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../auth/auth_controller.dart';
import '../core/model/user_payment_info.dart';
import '../core/payment/payment_qr_sheet.dart';
import '../ui/main.dart';
import 'repository.dart';

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
          title: const Text('Không gửi được tin nhắn'),
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
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .72,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PSheetTitle(
            label: 'Trao đổi với ${widget.host ? 'người chơi' : 'Host'}',
            trailing: FButton.icon(
              variant: .ghost,
              onPress: () => Navigator.pop(context),
              child: const Icon(FLucideIcons.x),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: messages.when(
              loading: () => const Center(child: FCircularProgress()),
              error: (_, _) =>
                  const Center(child: Text('Không tải được cuộc trò chuyện')),
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
                        title: const Text('Thông tin chuyển khoản'),
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
                                'Ngân hàng',
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
                        title: const Text(
                          'Chưa có thông tin thanh toán để gửi',
                        ),
                      );
                    }
                  }
                },
                child: const Text('Gửi thông tin thanh toán'),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: FTextField(
                  control: FTextFieldControl.managed(controller: _controller),
                  hint: 'Nhắn tin…',
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
