// "Đòi tiền trà đá" — any confirmed (going) attendee of a session can start
// an ancillary payment request against tagged lobby mates. Candidate/tag
// data reuses the wall composer's taggable-users infra (attendees + lobby
// members, attendees first) — same shape, different destination.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../../core/format.dart';
import '../../../feed_tab/compose_controller.dart';
import '../../../router.dart';
import '../../../ui/main.dart';
import 'feed_controller.dart';

void showPaymentRequestSheet(
  BuildContext context, {
  required String lobbyId,
  required String activityId,
}) {
  showPSheet(
    context: context,
    maxHeightRatio: 1.0,
    builder: (_) =>
        _PaymentRequestSheet(lobbyId: lobbyId, activityId: activityId),
  );
}

class _PaymentRequestSheet extends ConsumerStatefulWidget {
  final String lobbyId;
  final String activityId;
  const _PaymentRequestSheet({required this.lobbyId, required this.activityId});

  @override
  ConsumerState<_PaymentRequestSheet> createState() =>
      _PaymentRequestSheetState();
}

class _PaymentRequestSheetState extends ConsumerState<_PaymentRequestSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController(
    text: 'lobbyHub.paymentRequest.defaultNote'.tr(),
  );
  Set<String>?
  _selected; // null until candidates load, then seeded to attendees
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _seedIfNeeded(List<TaggableUser> candidates) {
    if (_selected != null) return;
    _selected = {for (final c in candidates.where((c) => c.attended)) c.userId};
  }

  Future<void> _submit() async {
    final amount = num.tryParse(_amountController.text.trim());
    final tagged = _selected ?? const <String>{};
    if (amount == null || amount <= 0) {
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleAlert),
        variant: .destructive,
        title: Text('lobbyHub.paymentRequest.invalidAmount'.tr()),
        alignment: .bottomCenter,
      );
      return;
    }
    if (tagged.isEmpty) {
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleAlert),
        variant: .destructive,
        title: Text('lobbyHub.paymentRequest.selectPerson'.tr()),
        alignment: .bottomCenter,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final note = _noteController.text.trim();
      await ref
          .read(lobbyFeedControllerProvider(widget.lobbyId).notifier)
          .createAncillaryPaymentRequest(
            activityId: widget.activityId,
            amount: amount,
            note: note.isEmpty ? null : note,
            taggedUserIds: tagged.toList(),
          );

      if (!mounted) return;
      Navigator.of(context).pop();
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.check),
        title: Text('lobbyHub.paymentRequest.sent'.tr()),
        alignment: .bottomCenter,
      );
    } catch (e, st) {
      Talker().handle(e, st, 'Create ancillary payment request failed');
      if (mounted) {
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.circleX),
          variant: .destructive,
          title: Text('lobbyHub.paymentRequest.sendFailed'.tr()),
          alignment: .bottomCenter,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final candidatesAsync = ref.watch(
      taggableUsersProvider(activityId: widget.activityId),
    );

    return SingleChildScrollView(
      primary: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          PSheetTitle(
            label: 'lobbyHub.paymentRequest.title'.tr(),
            trailing: FButton.icon(
              variant: .ghost,
              onPress: () => Navigator.of(context).pop(),
              child: const Icon(FLucideIcons.x),
            ),
          ),
          FTextField(
            label: Text('lobbyHub.common.amount'.tr()),
            hint: '50000?',
            description: AnimatedBuilder(
              animation: _amountController,
              builder: (_, _) {
                final amount = num.tryParse(_amountController.text.trim());
                return Text(
                  amount == null || amount < 0
                      ? 'lobbyHub.common.enterAmountReading'.tr()
                      : formatVndWords(amount),
                );
              },
            ),
            control: FTextFieldControl.managed(controller: _amountController),
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
          ),
          FTextField(
            label: Text('lobbyHub.common.note'.tr()),
            hint: 'lobbyHub.paymentRequest.defaultNote'.tr(),
            control: FTextFieldControl.managed(controller: _noteController),
          ),
          PSheetSectionLabel(label: 'lobbyHub.paymentRequest.splitAmong'.tr()),
          candidatesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => PEmptySectionPlaceholder(
              subtitle: 'lobbyHub.paymentRequest.loadFailed'.tr(),
            ),
            data: (candidates) {
              _seedIfNeeded(candidates);
              if (candidates.isEmpty) {
                return PEmptySectionPlaceholder(
                  subtitle: 'lobbyHub.paymentRequest.noCandidates'.tr(),
                );
              }
              final selected = _selected ?? const <String>{};
              return Column(
                children: [
                  for (final c in candidates)
                    FTile(
                      prefix: PUserAvatar(
                        userId: c.userId,
                        username: c.username,
                        generatedAvatar: c.generatedAvatar,
                        radius: 16,
                        // Own tap target nested inside the tile's
                        // selection-tap area — wins the gesture arena, so the
                        // avatar opens the profile while the rest of the
                        // tile still toggles the split selection.
                        onTap: () =>
                            UserRoute(id: c.userId, $extra: c.username)
                                .push(context),
                      ),
                      title: Text(
                        c.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        c.attended
                            ? 'lobbyHub.common.attended'.tr()
                            : 'lobbyHub.common.member'.tr(),
                      ),
                      suffix: selected.contains(c.userId)
                          ? Icon(
                              FLucideIcons.circleCheck,
                              color: context.theme.colors.primary,
                            )
                          : const Icon(FLucideIcons.circle),
                      onPress: () => setState(() {
                        final next = {...selected};
                        if (next.contains(c.userId)) {
                          next.remove(c.userId);
                        } else {
                          next.add(c.userId);
                        }
                        _selected = next;
                      }),
                    ),
                  if (selected.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    AnimatedBuilder(
                      animation: _amountController,
                      builder: (_, _) {
                        final total = num.tryParse(
                          _amountController.text.trim(),
                        );
                        if (total == null || total <= 0) {
                          return const SizedBox.shrink();
                        }
                        final perPerson =
                            (total / selected.length / 1000).ceil() * 1000;
                        return Text(
                          'lobbyHub.paymentRequest.eachApprox'.tr(
                            namedArgs: {
                              'amount': '${formatVnd(perPerson)}đ',
                              'words': formatVndWords(perPerson),
                            },
                          ),
                          style: context.theme.typography.body.xs.copyWith(
                            color: context.theme.colors.mutedForeground,
                          ),
                        );
                      },
                    ),
                  ],
                ],
              );
            },
          ),
          FButton(
            onPress: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('lobbyHub.paymentRequest.submit'.tr()),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
