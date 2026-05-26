import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'controller.dart';
import 'da_format.dart';
import 'da_icon.dart';
import 'data.dart';
import 'model.dart';
import 'wallet_shared.dart';

class WalletTopupScreen extends ConsumerStatefulWidget {
  const WalletTopupScreen({super.key});

  @override
  ConsumerState<WalletTopupScreen> createState() => _WalletTopupScreenState();
}

class _WalletTopupScreenState extends ConsumerState<WalletTopupScreen> {
  String _pickedPackageId = 'pkg500';
  DaPayMethod _method = DaPayMethod.momo;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final picked = daPackages.firstWhere((p) => p.id == _pickedPackageId);

    return FScaffold(
      childPad: false,
      header: const WalletStackHeader(title: 'Nạp Đá'),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                const WalletSectionLabel('Chọn gói'),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 18,
                  childAspectRatio: 1.15,
                  children: [
                    for (final p in daPackages)
                      _PackageCard(
                        package: p,
                        selected: _pickedPackageId == p.id,
                        onTap: () => setState(() => _pickedPackageId = p.id),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const WalletSectionLabel('Phương thức thanh toán'),
                const SizedBox(height: 12),
                WalletCard(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (var i = 0; i < daPurchasablePayMethods.length; i++) ...[
                        _MethodRow(
                          method: daPurchasablePayMethods[i],
                          selected: _method == daPurchasablePayMethods[i],
                          onTap: () => setState(
                            () => _method = daPurchasablePayMethods[i],
                          ),
                        ),
                        if (i < daPurchasablePayMethods.length - 1)
                          Padding(
                            padding: const EdgeInsets.only(left: 48),
                            child: Container(height: 1, color: colors.border),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: colors.border)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Tổng cộng',
                            style: TextStyle(
                              fontFamily: 'Bitter',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              height: 1,
                              color: colors.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                fmtVN(picked.price),
                                style: TextStyle(
                                  fontFamily: 'Bitter',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                  letterSpacing: -0.4,
                                  color: colors.foreground,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                              Text(
                                'đ',
                                style: TextStyle(
                                  fontFamily: 'Bitter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  height: 1,
                                  color: colors.mutedForeground,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '→ +${fmtVN(picked.totalDa)} Đá',
                                style: TextStyle(
                                  fontFamily: 'Bitter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  height: 1,
                                  color: colors.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    FButton(
                      variant: .primary,
                      onPress: () async {
                        await ref
                            .read(daBalanceProvider.notifier)
                            .credit(picked.totalDa);
                        if (context.mounted &&
                            Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('Thanh Toán'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final DaPackage package;
  final bool selected;
  final VoidCallback onTap;

  const _PackageCard({
    required this.package,
    required this.selected,
    required this.onTap,
  });

  static const _green = Color(0xFF959D54);
  static const _blue = Color(0xFF3090F2);

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final tagColor = package.bonus >= 750
        ? _green
        : package.bonus >= 100
            ? colors.primary
            : _blue;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: selected ? colors.crimsonTint : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? colors.primary : colors.border,
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const DaIcon(size: 28),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            fmtVN(package.da),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Bitter',
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 1,
                              letterSpacing: -0.4,
                              color: colors.foreground,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ĐÁ',
                            style: TextStyle(
                              fontFamily: 'Bitter',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              height: 1,
                              letterSpacing: 0.5,
                              color: colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (package.bonus > 0)
                  Text(
                    '+ ${package.bonus} Đá thưởng',
                    style: const TextStyle(
                      fontFamily: 'Bitter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      color: _green,
                    ),
                  ),
                const Spacer(),
                Text(
                  '${fmtVN(package.price)}đ',
                  style: TextStyle(
                    fontFamily: 'Bitter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    color: colors.secondaryForeground,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          if (package.tag != null)
            Positioned(
              top: -8,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: tagColor,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  package.tag!.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Bitter',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    letterSpacing: 0.4,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MethodRow extends StatelessWidget {
  final DaPayMethod method;
  final bool selected;
  final VoidCallback onTap;

  const _MethodRow({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            PayBadge(method: method),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                method.label,
                style: TextStyle(
                  fontFamily: 'Bitter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: colors.foreground,
                ),
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? colors.primary : colors.border,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: selected
                  ? Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.primary,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
