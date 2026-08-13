import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../auth/auth_controller.dart';
import '../core/model/user_payment_info.dart';
import '../core/payment/payment_qr_sheet.dart';
import '../ui/main.dart';
import 'conversation_controller.dart';
import 'model.dart';

/// The chat surface shared by every threaded conversation in the app.
///
/// Owns the message list, the composer, system-event rows and poll cards —
/// callers supply only what's specific to their feature (the header, and any
/// extra affordance like the freeplay host's "share payment info").
///
/// Realtime keeps this live; the `RefreshIndicator` is the manual fallback for
/// when the socket is down.
class ConversationView extends ConsumerStatefulWidget {
  final String conversationId;

  /// Shown above the composer — e.g. the freeplay host's payment-info button.
  final Widget? composerAccessory;

  /// Group threads label each bubble with its sender; 1:1 threads don't need to.
  final bool showSenderNames;

  const ConversationView({
    super.key,
    required this.conversationId,
    this.composerAccessory,
    this.showSenderNames = false,
  });

  @override
  ConsumerState<ConversationView> createState() => _ConversationViewState();
}

class _ConversationViewState extends ConsumerState<ConversationView> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // Opening the thread is what clears the unread badge — and what re-arms
    // the "first unread only" push rule for the next burst.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(conversationControllerProvider(widget.conversationId).notifier)
          .markRead();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(conversationControllerProvider(widget.conversationId).notifier)
          .send(text);
      _controller.clear();
    } catch (_) {
      if (mounted) {
        showFToast(
          context: context,
          variant: .destructive,
          title: Text('messaging.sendFailed'.tr()),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(
      conversationControllerProvider(widget.conversationId),
    );
    final me = ref.watch(currentUserIdProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: async.when(
            loading: () => const Center(child: FCircularProgress()),
            error: (_, _) => Center(child: Text('messaging.loadFailed'.tr())),
            data: (snapshot) => RefreshIndicator(
              onRefresh: () => ref
                  .read(
                    conversationControllerProvider(
                      widget.conversationId,
                    ).notifier,
                  )
                  .refresh(),
              child: snapshot.messages.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 48),
                        PEmptySectionPlaceholder(
                          subtitle: 'messaging.empty'.tr(),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: snapshot.messages.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) => _MessageRow(
                        message: snapshot.messages[index],
                        mine: snapshot.messages[index].senderId == me,
                        showSenderName: widget.showSenderNames,
                        conversationId: widget.conversationId,
                      ),
                    ),
            ),
          ),
        ),
        if (widget.composerAccessory != null) widget.composerAccessory!,
        _Composer(
          controller: _controller,
          sending: _sending,
          enabled: async.value?.canWrite ?? false,
          onSend: _send,
        ),
      ],
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final bool enabled;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.sending,
    required this.enabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'messaging.readOnly'.tr(),
          textAlign: TextAlign.center,
          style: context.theme.typography.body.sm.copyWith(
            color: context.theme.colors.mutedForeground,
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: FTextField(
            control: FTextFieldControl.managed(controller: controller),
            hint: 'messaging.messageHint'.tr(),
            maxLines: 3,
          ),
        ),
        const SizedBox(width: 8),
        FButton.icon(
          onPress: sending ? null : onSend,
          child: sending
              ? const FCircularProgress()
              : const Icon(FLucideIcons.send),
        ),
      ],
    );
  }
}

class _MessageRow extends ConsumerWidget {
  final Message message;
  final bool mine;
  final bool showSenderName;
  final String conversationId;

  const _MessageRow({
    required this.message,
    required this.mine,
    required this.showSenderName,
    required this.conversationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (message.kind) {
      case MessageKind.system:
        return _SystemRow(message: message);
      case MessageKind.paymentInfo:
        return _PaymentRow(message: message);
      case MessageKind.poll:
        return _PollCard(message: message, conversationId: conversationId);
      case MessageKind.text:
        return _TextBubble(
          message: message,
          mine: mine,
          showSenderName: showSenderName,
        );
    }
  }
}

class _TextBubble extends StatelessWidget {
  final Message message;
  final bool mine;
  final bool showSenderName;

  const _TextBubble({
    required this.message,
    required this.mine,
    required this.showSenderName,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: mine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (showSenderName && !mine && message.senderUsername != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 2),
              child: Text(
                message.senderUsername!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.theme.typography.body.xs.copyWith(
                  color: colors.mutedForeground,
                ),
              ),
            ),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * .72,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: mine ? colors.primary : colors.secondary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(message.body ?? ''),
          ),
        ],
      ),
    );
  }
}

/// System events carry a stable code, not prose — translated here so the same
/// row reads correctly in both languages. An unknown code renders nothing
/// rather than leaking a raw identifier into the thread.
class _SystemRow extends StatelessWidget {
  final Message message;

  const _SystemRow({required this.message});

  @override
  Widget build(BuildContext context) {
    final code = message.body;
    if (code == null) return const SizedBox.shrink();

    final key = 'messaging.system.$code';
    final text = key.tr(namedArgs: _args(message.payload));
    if (text == key) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: context.theme.typography.body.xs.copyWith(
          color: context.theme.colors.mutedForeground,
        ),
      ),
    );
  }

  static Map<String, String> _args(Map<String, dynamic>? payload) =>
      payload?.map((key, value) => MapEntry(key, value.toString())) ?? const {};
}

class _PaymentRow extends StatelessWidget {
  final Message message;

  const _PaymentRow({required this.message});

  @override
  Widget build(BuildContext context) {
    // A payment_info message that arrived over Realtime carries no details
    // (deliberately — see messaging_realtime.sql); the backfill fills them in
    // a moment later, so render nothing rather than a broken tile.
    if (!message.hasPaymentDetails) return const SizedBox.shrink();

    return FTile(
      prefix: const Icon(FLucideIcons.qrCode),
      title: Text('messaging.paymentInfo'.tr()),
      subtitle: Text('${message.bankCode ?? ''} · ${message.accountNumber}'),
      onPress: () => showPaymentQrSheet(
        context,
        info: UserPaymentInfo(
          id: message.id,
          bankId: message.bankCode ?? '',
          bankDisplayName:
              message.bankDisplayName ??
              message.bankCode ??
              'messaging.bank'.tr(),
          value: message.accountNumber!,
          accountName: message.accountName,
          createdAt: message.createdAt,
        ),
      ),
    );
  }
}

class _PollCard extends ConsumerWidget {
  final Message message;
  final String conversationId;

  const _PollCard({required this.message, required this.conversationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final total = message.totalVotes;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            message.pollQuestion ?? '',
            style: context.theme.typography.body.sm.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < message.pollOptions.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: FButton(
                variant: message.myVote == i ? .primary : .outline,
                size: .sm,
                onPress: () => ref
                    .read(conversationControllerProvider(conversationId).notifier)
                    .vote(message.id, i),
                child: Row(
                  children: [
                    // The label is user-authored and unbounded; the count is
                    // short and fixed. Let the label ellipsize, never the count.
                    Expanded(
                      child: Text(
                        message.pollOptions[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${message.pollVotes[i] ?? 0}'),
                  ],
                ),
              ),
            ),
          Text(
            'messaging.pollVotes'.plural(total),
            style: context.theme.typography.body.xs.copyWith(
              color: colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}
