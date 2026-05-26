import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'da_format.dart';
import 'da_icon.dart';
import 'data.dart';
import 'model.dart';
import 'wallet_shared.dart';

enum _PurchaseFilter { all, success, failed }

class WalletPurchaseHistoryScreen extends StatefulWidget {
  const WalletPurchaseHistoryScreen({super.key});

  @override
  State<WalletPurchaseHistoryScreen> createState() =>
      _WalletPurchaseHistoryScreenState();
}

class _WalletPurchaseHistoryScreenState
    extends State<WalletPurchaseHistoryScreen> {
  _PurchaseFilter _filter = _PurchaseFilter.all;

  static const _green = Color(0xFF959D54);

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    final filtered = switch (_filter) {
      _PurchaseFilter.success =>
        sampleDaPurchases.where((p) => p.status == DaPurchaseStatus.success).toList(),
      _PurchaseFilter.failed =>
        sampleDaPurchases.where((p) => p.status == DaPurchaseStatus.failed).toList(),
      _PurchaseFilter.all => sampleDaPurchases,
    };

    final totalDa = sampleDaPurchases
        .where((p) => p.status == DaPurchaseStatus.success)
        .fold<int>(0, (s, p) => s + p.totalDa);
    final totalPaid = sampleDaPurchases
        .where((p) => p.status == DaPurchaseStatus.success)
        .fold<int>(0, (s, p) => s + p.paid);

    final grouped = groupByDate<DaPurchase>(filtered, (p) => p.date);

    return FScaffold(
      childPad: false,
      header: const WalletStackHeader(title: 'Lịch sử nạp'),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          WalletSummaryCard(
            leftLabel: 'Tổng nạp',
            leftValue: '+${fmtVN(totalDa)}',
            leftSuffix: 'Đá',
            leftColor: _green,
            rightLabel: 'Đã thanh toán',
            rightValue: fmtVN(totalPaid),
            rightSuffix: 'đ',
            rightColor: colors.foreground,
          ),
          const SizedBox(height: 12),
          _FilterRow(
            value: _filter,
            options: const [
              (_PurchaseFilter.all, 'Tất cả'),
              (_PurchaseFilter.success, 'Thành công'),
              (_PurchaseFilter.failed, 'Thất bại'),
            ],
            onChanged: (v) => setState(() => _filter = v),
          ),
          const SizedBox(height: 14),
          if (grouped.isEmpty) const WalletEmpty(),
          for (final group in grouped) ...[
            WalletDateLabel(group.date),
            WalletCard(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < group.items.length; i++) ...[
                    _PurchaseRow(p: group.items[i]),
                    if (i < group.items.length - 1)
                      Padding(
                        padding: const EdgeInsets.only(left: 56),
                        child: Container(height: 1, color: colors.border),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final _PurchaseFilter value;
  final List<(_PurchaseFilter, String)> options;
  final ValueChanged<_PurchaseFilter> onChanged;

  const _FilterRow({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          for (final option in options) ...[
            _Chip(
              label: option.$2,
              selected: option.$1 == value,
              onTap: () => onChanged(option.$1),
              colors: colors,
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final FColors colors;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: selected ? colors.primary : colors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Bitter',
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            height: 1,
            color: selected ? colors.primaryForeground : colors.foreground,
          ),
        ),
      ),
    );
  }
}

class _PurchaseRow extends StatelessWidget {
  final DaPurchase p;

  const _PurchaseRow({required this.p});

  static const _green = Color(0xFF959D54);

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final dim = p.status == DaPurchaseStatus.failed;
    final total = p.totalDa;

    return Opacity(
      opacity: dim ? 0.55 : 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colors.greenTint,
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: const DaIcon(size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Text(
                        p.label,
                        style: TextStyle(
                          fontFamily: 'Bitter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                          color: colors.foreground,
                        ),
                      ),
                      if (p.bonus > 0)
                        WalletStatusBadge(
                          label: '+${p.bonus} thưởng',
                          color: _green,
                          background: colors.greenTint,
                        ),
                      if (p.status == DaPurchaseStatus.failed)
                        WalletStatusBadge(
                          label: 'Thất bại',
                          color: colors.destructive,
                          background: colors.destructive.withValues(alpha: 0.12),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      PayBadge(method: p.method),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '${p.method.label} · ${p.time}${p.paid > 0 ? ' · ${fmtVN(p.paid)}đ' : ''}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Bitter',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                            color: colors.mutedForeground,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '+${fmtVN(total)}',
                  style: TextStyle(
                    fontFamily: 'Bitter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    color: dim ? colors.mutedForeground : _green,
                    decoration: dim ? TextDecoration.lineThrough : null,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ĐÁ',
                  style: TextStyle(
                    fontFamily: 'Bitter',
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    height: 1,
                    letterSpacing: 0.5,
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
