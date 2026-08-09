import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../../../core/payment/pay_recipient.dart';
import '../../../../ui/main.dart';
import 'feed_controller.dart';
import 'money_controller.dart';

Future<void> showLobbyMoneySheet(
  BuildContext context, {
  required String lobbyId,
}) => showPSheet(
  context: context,
  maxHeightRatio: 1,
  builder: (_) => _LobbyMoneySheet(lobbyId: lobbyId),
);

class _LobbyMoneySheet extends ConsumerWidget {
  final String lobbyId;

  const _LobbyMoneySheet({required this.lobbyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balances = ref.watch(lobbyMoneyControllerProvider(lobbyId));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PSheetTitle(
          label: 'payment.lobbyMoney'.tr(),
          trailing: FButton.icon(
            variant: .ghost,
            onPress: () => Navigator.of(context).pop(),
            child: const Icon(FLucideIcons.x),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'payment.moneyHint'.tr(),
          style: context.theme.typography.body.sm.copyWith(
            color: context.theme.colors.mutedForeground,
          ),
        ),
        const SizedBox(height: 10),
        _SignLegend(),
        const SizedBox(height: 12),
        Flexible(
          child: balances.when(
            loading: () => const Center(child: FCircularProgress()),
            error: (_, _) => _MoneyError(lobbyId: lobbyId),
            data: (items) => items.isEmpty
                ? _MoneyEmpty()
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, index) =>
                        _MoneyCard(lobbyId: lobbyId, balance: items[index]),
                  ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _SignLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Text(
            '+',
            style: TextStyle(color: pbGreen, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              'payment.plusMeaning'.tr(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.theme.typography.body.xs,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            '−',
            style: TextStyle(
              color: Color(0xFFDC143C),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              'payment.minusMeaning'.tr(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.theme.typography.body.xs,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoneyCard extends ConsumerStatefulWidget {
  final String lobbyId;
  final LobbyMoneyBalance balance;

  const _MoneyCard({required this.lobbyId, required this.balance});

  @override
  ConsumerState<_MoneyCard> createState() => _MoneyCardState();
}

class _MoneyCardState extends ConsumerState<_MoneyCard> {
  late final String _idempotencyKey = lobbyMoneyIdempotencyKey();
  bool _openedPayment = false;
  bool _settling = false;

  Future<void> _openPayment() async {
    final balance = widget.balance;
    await payRecipient(
      context,
      recipientUserId: balance.userId,
      amount: balance.signedTotal.abs(),
      note: 'Tiền trong lobby với ${balance.username}',
      emptyMessage: 'payment.recipientMissingInfo'.tr(),
    );
    if (mounted) setState(() => _openedPayment = true);
  }

  Future<void> _settle() async {
    if (_settling) return;
    setState(() => _settling = true);
    try {
      await ref
          .read(lobbyMoneyControllerProvider(widget.lobbyId).notifier)
          .settle(widget.balance.userId, idempotencyKey: _idempotencyKey);
      ref.invalidate(lobbyFeedControllerProvider(widget.lobbyId));
      if (mounted) {
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.check),
          title: Text('payment.moneyDone'.tr()),
          alignment: .bottomCenter,
        );
      }
    } catch (error, stackTrace) {
      Talker().handle(error, stackTrace, 'Settle lobby money failed');
      if (mounted) {
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.circleX),
          variant: .destructive,
          title: Text('payment.moneyFailed'.tr()),
          alignment: .bottomCenter,
        );
      }
    } finally {
      if (mounted) setState(() => _settling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final balance = widget.balance;
    final needsToSend = balance.signedTotal < 0;
    final isEven = balance.signedTotal == 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              PUserAvatar(
                userId: balance.userId,
                username: balance.username,
                generatedAvatar: balance.generatedAvatar,
                radius: 15,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  balance.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.theme.typography.body.sm.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                _signedVnd(balance.signedTotal),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _signColor(balance.signedTotal),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final entry in balance.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(
                    _date(entry.activityDate),
                    style: context.theme.typography.body.sm.copyWith(
                      color: colors.mutedForeground,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _signedVnd(entry.signedAmount),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _signColor(entry.signedAmount),
                    ),
                  ),
                ],
              ),
            ),
          if (needsToSend || isEven) ...[
            const SizedBox(height: 10),
            if (needsToSend && !_openedPayment)
              FButton(
                onPress: _openPayment,
                child: Text(
                  'payment.sendAmount'.tr(
                    namedArgs: {'amount': _vnd(balance.signedTotal.abs())},
                  ),
                ),
              )
            else
              FButton(
                onPress: _settling ? null : _settle,
                child: _settling
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isEven
                            ? 'payment.clearBothWays'.tr()
                            : 'payment.sentDone'.tr(),
                      ),
              ),
          ],
        ],
      ),
    );
  }
}

class _MoneyEmpty extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 30),
    child: Column(
      children: [
        const Icon(FLucideIcons.partyPopper, size: 28, color: pbGreen),
        const SizedBox(height: 9),
        Text('payment.moneyEmpty'.tr()),
      ],
    ),
  );
}

class _MoneyError extends ConsumerWidget {
  final String lobbyId;

  const _MoneyError({required this.lobbyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(
      children: [
        Text('errorGeneric'.tr()),
        const SizedBox(height: 8),
        FButton(
          variant: .outline,
          onPress: () => ref.invalidate(lobbyMoneyControllerProvider(lobbyId)),
          child: Text('payment.retry'.tr()),
        ),
      ],
    ),
  );
}

String _date(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}';

String _vnd(num value) {
  final digits = value.abs().round().toString();
  return '${digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}đ';
}

String _signedVnd(num value) => '${value >= 0 ? '+' : '−'}${_vnd(value)}';

Color _signColor(num value) => value >= 0 ? pbGreen : const Color(0xFFDC143C);
