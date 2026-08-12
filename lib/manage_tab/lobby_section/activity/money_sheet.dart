import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../../../core/format.dart';
import '../../../../core/payment/pay_recipient.dart';
import '../../../../ui/main.dart';
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
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.65,
          ),
          child: balances.when(
            loading: () => const SizedBox(
              height: 120,
              child: Center(child: FCircularProgress()),
            ),
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
      note: 'lobbyHub.feed.moneyNote'.tr(
        namedArgs: {'username': balance.username},
      ),
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
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              formatVndWords(balance.signedTotal),
              textAlign: TextAlign.right,
              style: context.theme.typography.body.xs.copyWith(
                color: colors.mutedForeground,
              ),
            ),
          ),
          const SizedBox(height: 10),
          for (final entry in balance.entries) ...[
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
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  formatVndWords(entry.signedAmount),
                  textAlign: TextAlign.right,
                  style: context.theme.typography.body.xs.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ),
            ),
          ],
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
            _SwipeToConfirm(
              loading: _settling,
              onConfirm: _settle,
              label: isEven
                  ? 'payment.swipeClearBothWays'.tr()
                  : needsToSend
                  ? 'payment.swipeSent'.tr(
                      namedArgs: {'amount': _vnd(balance.signedTotal.abs())},
                    )
                  : 'payment.swipeReceived'.tr(
                      namedArgs: {'amount': _vnd(balance.signedTotal)},
                    ),
            ),
        ],
      ),
    );
  }
}

class _SwipeToConfirm extends StatefulWidget {
  final String label;
  final bool loading;
  final Future<void> Function() onConfirm;

  const _SwipeToConfirm({
    required this.label,
    required this.loading,
    required this.onConfirm,
  });

  @override
  State<_SwipeToConfirm> createState() => _SwipeToConfirmState();
}

class _SwipeToConfirmState extends State<_SwipeToConfirm> {
  static const _height = 52.0;
  static const _inset = 4.0;
  static const _thumbSize = _height - (_inset * 2);
  static const _completionThreshold = 0.80;

  double _dragOffset = 0;
  bool _dragging = false;
  bool _committing = false;

  bool get _disabled => widget.loading || _committing;

  void _updateDrag(double delta, double maxDrag) {
    if (_disabled) return;
    final next = (_dragOffset + delta).clamp(0.0, maxDrag);
    setState(() => _dragOffset = next);
    if (next >= maxDrag * _completionThreshold) {
      _finish(maxDrag);
    }
  }

  Future<void> _finish(double maxDrag) async {
    if (_disabled) return;
    if (_dragOffset < maxDrag * _completionThreshold) {
      setState(() {
        _dragging = false;
        _dragOffset = 0;
      });
      return;
    }

    setState(() {
      _dragging = false;
      _committing = true;
      _dragOffset = maxDrag;
    });
    await widget.onConfirm();
    if (!mounted) return;
    setState(() {
      _committing = false;
      _dragOffset = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag = (constraints.maxWidth - _thumbSize - (_inset * 2))
            .clamp(0.0, double.infinity);
        final offset = _dragOffset.clamp(0.0, maxDrag);

        return Semantics(
          button: true,
          label: widget.label,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: _disabled
                ? null
                : (_) => setState(() => _dragging = true),
            onHorizontalDragUpdate: _disabled
                ? null
                : (details) => _updateDrag(details.delta.dx, maxDrag),
            onHorizontalDragEnd: _disabled ? null : (_) => _finish(maxDrag),
            onHorizontalDragCancel: _disabled
                ? null
                : () => setState(() {
                    _dragging = false;
                    _dragOffset = 0;
                  }),
            child: Container(
              height: _height,
              decoration: BoxDecoration(
                color: colors.secondary,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.border),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 58),
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: context.theme.typography.body.sm.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.foreground,
                      ),
                    ),
                  ),
                  AnimatedPositionedDirectional(
                    duration: _dragging
                        ? Duration.zero
                        : const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    start: _inset + offset,
                    top: _inset,
                    child: Container(
                      width: _thumbSize,
                      height: _thumbSize,
                      decoration: BoxDecoration(
                        color: pbBlue,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Center(
                        child: _disabled
                            ? const SizedBox(
                                width: 17,
                                height: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                FLucideIcons.chevronsRight,
                                size: 20,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MoneyEmpty extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 30),
    child: Column(
      mainAxisSize: MainAxisSize.min,
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
      mainAxisSize: MainAxisSize.min,
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
  return '${formatVnd(value.abs())}đ';
}

String _signedVnd(num value) => '${value >= 0 ? '+' : '−'}${_vnd(value)}';

Color _signColor(num value) => value >= 0 ? pbGreen : const Color(0xFFDC143C);
