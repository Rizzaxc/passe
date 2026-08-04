import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../core/model/user_payment_info.dart';
import '../core/payment/payment_qr_sheet.dart';
import '../core/payment/vietqr_bank.dart';
import '../ui/main.dart';
import 'payment_info_controller.dart';

class PaymentInfoSelectionScreen extends ConsumerWidget {
  const PaymentInfoSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(paymentInfoControllerProvider);

    return FScaffold(
      header: FHeader(
        title: Text('profile.paymentInfo'.tr()),
        suffixes: [
          FHeaderAction.back(onPress: () => Navigator.of(context).pop()),
        ],
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                'profile.paymentInfoExplanation'.tr(),
                style: context.theme.typography.body.sm.copyWith(
                  color: context.theme.colors.mutedForeground,
                ),
              ),
            ),
            const SizedBox(height: 16),
            entriesAsync.when(
              data: (entries) => entries.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(
                              FLucideIcons.landmark,
                              size: 64,
                              color: context.theme.colors.mutedForeground,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'profile.paymentInfoEmpty'.tr(),
                              textAlign: TextAlign.center,
                              style: context.theme.typography.body.sm.copyWith(
                                color: context.theme.colors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: FTileGroup(
                        children: entries
                            .map((entry) => _buildTile(context, ref, entry))
                            .toList(),
                      ),
                    ),
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: FCircularProgress()),
              ),
              error: (error, stack) => Padding(
                padding: const EdgeInsets.all(32),
                child: Center(child: Text('errorGeneric'.tr())),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FButton(
                variant: .outline,
                onPress: () => _showAddPaymentInfoSheet(context, ref),
                prefix: const Icon(FLucideIcons.plus, size: 16),
                child: Text('profile.addPaymentInfo'.tr()),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showAddPaymentInfoSheet(BuildContext context, WidgetRef ref) {
    showPSheet(
      context: context,
      builder: (context) => const _AddPaymentInfoSheet(),
    );
  }

  FTile _buildTile(BuildContext context, WidgetRef ref, UserPaymentInfo entry) {
    return FTile(
      prefix: const Icon(FLucideIcons.landmark),
      title: Text(entry.bankDisplayName),
      subtitle: Text(
        entry.accountName != null ? '${entry.value} • ${entry.accountName}' : entry.value,
      ),
      suffix: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FButton.icon(
            variant: .ghost,
            onPress: () async {
              await Clipboard.setData(ClipboardData(text: entry.value));
              if (!context.mounted) return;
              showFToast(
                context: context,
                icon: const Icon(FLucideIcons.copy),
                title: Text('payment.copied'.tr()),
                alignment: .bottomCenter,
              );
            },
            child: const Icon(FLucideIcons.copy, size: 14),
          ),
          FButton.icon(
            variant: .ghost,
            onPress: () async {
              final confirmed = await showAdaptiveDialog<bool>(
                context: context,
                builder: (context) => AlertDialog.adaptive(
                  title: Text('profile.paymentInfoDeleteConfirmTitle'.tr()),
                  content: Text('profile.paymentInfoDeleteConfirmBody'.tr()),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('profile.paymentInfoDeleteCancel'.tr()),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text('profile.paymentInfoDeleteConfirmAction'.tr()),
                    ),
                  ],
                ),
              );
              if (confirmed != true) return;

              try {
                await ref.read(paymentInfoControllerProvider.notifier).delete(entry);
              } catch (e) {
                if (!context.mounted) return;
                showFToast(
                  context: context,
                  icon: const Icon(FLucideIcons.circleX),
                  variant: .destructive,
                  title: Text('error'.tr()),
                  description: Text('errorGeneric'.tr()),
                  alignment: .bottomCenter,
                );
              }
            },
            child: Icon(
              FLucideIcons.trash,
              size: 14,
              color: context.theme.colors.destructive,
            ),
          ),
        ],
      ),
      onPress: () => showPaymentQrSheet(context, info: entry),
    );
  }
}

class _AddPaymentInfoSheet extends ConsumerStatefulWidget {
  const _AddPaymentInfoSheet();

  @override
  ConsumerState<_AddPaymentInfoSheet> createState() => _AddPaymentInfoSheetState();
}

final _kVietqrBankItems = {for (final bank in kVietqrBanks) bank.shortName: bank};

class _AddPaymentInfoSheetState extends ConsumerState<_AddPaymentInfoSheet> {
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();
  VietqrBank? _selectedBank;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Rebuild on every keystroke so the submit button's enabled state
    // (gated on a non-empty account number) stays in sync.
    _accountNumberController.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _accountNumberController.removeListener(_rebuild);
    _accountNumberController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final bank = _selectedBank;
    final accountNumber = _accountNumberController.text.trim();
    if (bank == null || accountNumber.isEmpty) return;

    setState(() => _saving = true);
    try {
      await ref.read(paymentInfoControllerProvider.notifier).add(
            bank: bank,
            accountNumber: accountNumber,
            accountName: _accountNameController.text.trim().isEmpty
                ? null
                : _accountNameController.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleX),
        variant: .destructive,
        title: Text('profile.uploadFailed'.tr()),
        alignment: .bottomCenter,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      primary: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          PSheetTitle(
            label: 'profile.addPaymentInfo'.tr(),
            trailing: FButton.icon(
              variant: .ghost,
              onPress: () => Navigator.of(context).pop(),
              child: const Icon(FLucideIcons.x),
            ),
          ),
          FSelect<VietqrBank>.search(
            items: _kVietqrBankItems,
            hint: 'payment.bankOrWallet'.tr(),
            prefixBuilder: (context, style, states) => Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 0, 4),
              child: Icon(FLucideIcons.landmark),
            ),
            control: FSelectControl.lifted(
              value: _selectedBank,
              onChange: (bank) => setState(() => _selectedBank = bank),
            ),
          ),
          FTextField(
            hint: 'payment.accountNumber'.tr(),
            keyboardType: TextInputType.text,
            control: FTextFieldControl.managed(controller: _accountNumberController),
          ),
          FTextField(
            hint: 'payment.accountHolderName'.tr(),
            control: FTextFieldControl.managed(controller: _accountNameController),
          ),
          FButton(
            onPress: (_selectedBank == null || _accountNumberController.text.trim().isEmpty || _saving)
                ? null
                : _submit,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text('profile.commit'.tr()),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
