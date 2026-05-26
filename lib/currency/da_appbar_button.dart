import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../router.dart';
import 'controller.dart';
import 'da_format.dart';
import 'da_icon.dart';

/// Crimson-tinted pill in the appbar showing the user's Đá balance.
///
/// Tapping opens the wallet stack. While the balance is loading we show
/// just the gem so the pill width doesn't pop when the number arrives.
class DaAppbarButton extends ConsumerWidget {
  const DaAppbarButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(daBalanceProvider);
    final colors = context.theme.colors;

    return GestureDetector(
      onTap: () => const WalletHomeRoute().push(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 30,
        padding: const EdgeInsets.fromLTRB(6, 0, 10, 0),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DaIcon(size: 18),
            const SizedBox(width: 6),
            if (balance.value != null)
              Text(
                fmtVN(balance.value!),
                style: TextStyle(
                  fontFamily: 'Bitter',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  height: 1,
                  letterSpacing: 0.1,
                  color: colors.primary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
