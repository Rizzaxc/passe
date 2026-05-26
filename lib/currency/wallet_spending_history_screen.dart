import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'da_format.dart';
import 'data.dart';
import 'model.dart';
import 'wallet_shared.dart';

enum _SpendFilter { all, venue, coach, lobby }

class WalletSpendingHistoryScreen extends StatefulWidget {
  const WalletSpendingHistoryScreen({super.key});

  @override
  State<WalletSpendingHistoryScreen> createState() =>
      _WalletSpendingHistoryScreenState();
}

class _WalletSpendingHistoryScreenState
    extends State<WalletSpendingHistoryScreen> {
  _SpendFilter _filter = _SpendFilter.all;

  static const _green = Color(0xFF959D54);

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    final filtered = switch (_filter) {
      _SpendFilter.venue =>
        sampleDaSpending.where((s) => s.kind == DaSpendKind.venue).toList(),
      _SpendFilter.coach => sampleDaSpending
          .where((s) => s.kind == DaSpendKind.coach || s.kind == DaSpendKind.fee)
          .toList(),
      _SpendFilter.lobby => sampleDaSpending
          .where((s) =>
              s.kind == DaSpendKind.confirm ||
              s.kind == DaSpendKind.split ||
              s.kind == DaSpendKind.refund)
          .toList(),
      _SpendFilter.all => sampleDaSpending,
    };

    final totalOut = sampleDaSpending
        .where((s) => s.kind != DaSpendKind.refund)
        .fold<int>(0, (s, x) => s + x.amount);
    final refunded = sampleDaSpending
        .where((s) => s.kind == DaSpendKind.refund)
        .fold<int>(0, (s, x) => s + x.amount);

    final grouped = groupByDate<DaSpending>(filtered, (s) => s.date);

    return FScaffold(
      childPad: false,
      header: const WalletStackHeader(title: 'Lịch sử chi'),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          WalletSummaryCard(
            leftLabel: 'Đã chi',
            leftValue: '−${fmtVN(totalOut)}',
            leftSuffix: 'Đá',
            leftColor: colors.foreground,
            rightLabel: 'Hoàn lại',
            rightValue: '+${fmtVN(refunded)}',
            rightSuffix: 'Đá',
            rightColor: _green,
          ),
          const SizedBox(height: 12),
          _FilterRow(
            value: _filter,
            options: const [
              (_SpendFilter.all, 'Tất cả'),
              (_SpendFilter.venue, 'Sân'),
              (_SpendFilter.coach, 'HLV & Trọng Tài'),
              (_SpendFilter.lobby, 'Lobby'),
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
                    _SpendRow(s: group.items[i]),
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
  final _SpendFilter value;
  final List<(_SpendFilter, String)> options;
  final ValueChanged<_SpendFilter> onChanged;

  const _FilterRow({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          for (final option in options) ...[
            GestureDetector(
              onTap: () => onChanged(option.$1),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: option.$1 == value ? colors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(
                    color: option.$1 == value ? colors.primary : colors.border,
                  ),
                ),
                child: Text(
                  option.$2,
                  style: TextStyle(
                    fontFamily: 'Bitter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1,
                    color: option.$1 == value
                        ? colors.primaryForeground
                        : colors.foreground,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _SpendRow extends StatelessWidget {
  final DaSpending s;

  const _SpendRow({required this.s});

  static const _green = Color(0xFF959D54);

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final isRefund = s.kind == DaSpendKind.refund;
    final pending = s.status == DaSpendStatus.pending;

    final tint = switch (s.kind) {
      DaSpendKind.confirm => colors.crimsonTint,
      DaSpendKind.venue => colors.blueTint,
      DaSpendKind.coach => colors.crimsonTint,
      DaSpendKind.split => colors.greenTint,
      DaSpendKind.fee => colors.secondary,
      DaSpendKind.refund => colors.greenTint,
    };

    return Opacity(
      opacity: pending ? 0.92 : 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: isRefund
                  ? const Icon(FIcons.arrowDown, size: 14, color: _green)
                  : SpendKindGlyph(
                      kind: s.kind,
                      color: colors.secondaryForeground,
                    ),
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
                        s.label,
                        style: TextStyle(
                          fontFamily: 'Bitter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                          color: colors.foreground,
                        ),
                      ),
                      if (pending)
                        WalletStatusBadge(
                          label: 'Chờ xác nhận',
                          color: const Color(0xFFF59E0B),
                          background: const Color(0xFFF59E0B).withValues(alpha: 0.14),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${s.detail} · ${s.time}',
                    style: TextStyle(
                      fontFamily: 'Bitter',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                      color: colors.mutedForeground,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isRefund ? '+' : '−'}${fmtVN(s.amount)}',
                  style: TextStyle(
                    fontFamily: 'Bitter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    color: isRefund ? _green : colors.foreground,
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
