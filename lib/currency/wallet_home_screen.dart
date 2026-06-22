import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../router.dart';
import 'controller.dart';
import 'da_format.dart';
import 'da_icon.dart';
import 'data.dart';
import 'model.dart';
import 'wallet_shared.dart';

class WalletHomeScreen extends ConsumerWidget {
  const WalletHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(daBalanceProvider).value ?? defaultDaBalance;
    final colors = context.theme.colors;

    final recent = _buildRecent();

    return FScaffold(
      childPad: false,
      header: WalletStackHeader(
        title: 'Đá',
        trailing: FButton.icon(
          variant: .ghost,
          onPress: () {},
          child: Icon(FLucideIcons.ellipsis, size: 20, color: colors.foreground),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          _BalanceHero(balance: balance),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _EntryTile(
                  tone: _Tone.green,
                  label: 'Lịch sử nạp',
                  sub: '${sampleDaPurchases.length} giao dịch',
                  icon: FLucideIcons.arrowDown,
                  onTap: () => const WalletPurchaseHistoryRoute().push(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _EntryTile(
                  tone: _Tone.crimson,
                  label: 'Lịch sử chi',
                  sub: '${sampleDaSpending.length} hoạt động',
                  icon: FLucideIcons.arrowUp,
                  onTap: () => const WalletSpendingHistoryRoute().push(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _IntroLink(
            onTap: () => const WalletIntroRoute().push(context),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: Row(
              children: [
                Expanded(
                  child: WalletSectionLabel(
                    'Hoạt động gần đây',
                    padding: EdgeInsets.zero,
                  ),
                ),
                GestureDetector(
                  onTap: () => const WalletSpendingHistoryRoute().push(context),
                  child: Text(
                    'Xem tất cả',
                    style: TextStyle(
                      fontFamily: 'Bitter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1,
                      color: colors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          WalletCard(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < recent.length; i++) ...[
                  _RecentRow(entry: recent[i]),
                  if (i < recent.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(left: 52),
                      child: Container(height: 1, color: colors.border),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_RecentEntry> _buildRecent() {
    final all = <_RecentEntry>[
      ...sampleDaPurchases.map((p) => _RecentEntry.purchase(p)),
      ...sampleDaSpending.map((s) => _RecentEntry.spending(s)),
    ];
    all.sort((a, b) => '${b.date}${b.time}'.compareTo('${a.date}${a.time}'));
    return all.take(5).toList();
  }
}

class _BalanceHero extends StatelessWidget {
  final int balance;

  const _BalanceHero({required this.balance});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return WalletCard(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WalletSectionLabel(
                  'Số Đá khả dụng',
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const DaIcon(size: 56),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            fmtVN(balance),
                            style: TextStyle(
                              fontFamily: 'Bitter',
                              fontSize: 44,
                              fontWeight: FontWeight.w800,
                              height: 0.95,
                              letterSpacing: -1.2,
                              color: colors.foreground,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Đá · ≈ ${fmtVN(balance * 1000)}đ',
                            style: TextStyle(
                              fontFamily: 'Bitter',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1,
                              color: colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(height: 1, color: colors.border),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _HeroAction(
                    label: 'Nạp Đá',
                    icon: FLucideIcons.plus,
                    background: colors.primary,
                    foreground: colors.primaryForeground,
                    onTap: () => const WalletTopupRoute().push(context),
                  ),
                ),
                Container(width: 1, color: colors.border),
                Expanded(
                  child: _HeroAction(
                    label: 'Cách Sử Dụng',
                    icon: null,
                    background: Colors.transparent,
                    foreground: colors.secondaryForeground,
                    onTap: () => const WalletIntroRoute().push(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroAction extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  const _HeroAction({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: background,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Bitter',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1,
                letterSpacing: 0.1,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _Tone { green, crimson }

class _EntryTile extends StatelessWidget {
  final _Tone tone;
  final String label;
  final String sub;
  final IconData icon;
  final VoidCallback onTap;

  const _EntryTile({
    required this.tone,
    required this.label,
    required this.sub,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final glyphColor = tone == _Tone.green ? const Color(0xFF959D54) : colors.primary;
    final tint = tone == _Tone.green ? colors.greenTint : colors.crimsonTint;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: WalletCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 20, color: glyphColor),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Bitter',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.2,
                color: colors.foreground,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
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
      ),
    );
  }
}

class _IntroLink extends StatelessWidget {
  final VoidCallback onTap;

  const _IntroLink({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: WalletCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.blueTint,
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: const Icon(
                FLucideIcons.info,
                size: 18,
                color: Color(0xFF3090F2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đá là gì?',
                    style: TextStyle(
                      fontFamily: 'Bitter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      color: colors.foreground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Cách dùng Đá để xác nhận buổi chơi, đặt sân, đặt lịch HLV',
                    style: TextStyle(
                      fontFamily: 'Bitter',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                      color: colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            Icon(FLucideIcons.chevronRight, size: 18, color: colors.mutedForeground),
          ],
        ),
      ),
    );
  }
}

/// Compact transaction-row view used by the home screen's "recent" card.
///
/// This intentionally collapses the two ledger shapes (purchase vs.
/// spending) into a single visual; the dedicated history screens have
/// richer per-row layouts.
class _RecentEntry {
  final String id;
  final String title;
  final String sub;
  final String delta;
  final bool incoming;
  final bool dim;
  final String? badgeLabel;
  final Color? badgeColor;
  final Color? badgeBg;
  final Widget Function(BuildContext) glyphBuilder;
  final String date;
  final String time;

  _RecentEntry({
    required this.id,
    required this.title,
    required this.sub,
    required this.delta,
    required this.incoming,
    required this.dim,
    required this.badgeLabel,
    required this.badgeColor,
    required this.badgeBg,
    required this.glyphBuilder,
    required this.date,
    required this.time,
  });

  factory _RecentEntry.purchase(DaPurchase p) {
    return _RecentEntry(
      id: p.id,
      title: p.label,
      sub: '${p.method.label} · ${p.date} ${p.time}',
      delta: '+${fmtVN(p.totalDa)}',
      incoming: true,
      dim: p.status == DaPurchaseStatus.failed,
      badgeLabel: p.status == DaPurchaseStatus.failed ? 'Thất bại' : null,
      badgeColor: const Color(0xFFF97316),
      badgeBg: const Color(0x1FF97316),
      glyphBuilder: (ctx) =>
          const Icon(FLucideIcons.arrowDown, size: 14, color: Color(0xFF959D54)),
      date: p.date,
      time: p.time,
    );
  }

  factory _RecentEntry.spending(DaSpending s) {
    final isRefund = s.kind == DaSpendKind.refund;
    return _RecentEntry(
      id: s.id,
      title: s.label,
      sub: '${s.detail} · ${s.date} ${s.time}',
      delta: isRefund ? '+${fmtVN(s.amount)}' : '−${fmtVN(s.amount)}',
      incoming: isRefund,
      dim: false,
      badgeLabel: s.status == DaSpendStatus.pending ? 'Chờ xác nhận' : null,
      badgeColor: const Color(0xFFF59E0B),
      badgeBg: const Color(0x24F59E0B),
      glyphBuilder: (ctx) {
        if (isRefund) {
          return const Icon(
            FLucideIcons.arrowDown,
            size: 14,
            color: Color(0xFF959D54),
          );
        }
        return SpendKindGlyph(
          kind: s.kind,
          color: ctx.theme.colors.secondaryForeground,
        );
      },
      date: s.date,
      time: s.time,
    );
  }
}

class _RecentRow extends StatelessWidget {
  final _RecentEntry entry;

  const _RecentRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final deltaColor = entry.incoming ? const Color(0xFF959D54) : colors.foreground;

    return Opacity(
      opacity: entry.dim ? 0.55 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: entry.incoming ? colors.greenTint : colors.secondary,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: entry.glyphBuilder(context),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          entry.title,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            fontFamily: 'Bitter',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                            color: colors.foreground,
                          ),
                        ),
                      ),
                      if (entry.badgeLabel != null) ...[
                        const SizedBox(width: 6),
                        WalletStatusBadge(
                          label: entry.badgeLabel!,
                          color: entry.badgeColor!,
                          background: entry.badgeBg!,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.sub,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'Bitter',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      height: 1.3,
                      color: colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              entry.delta,
              style: TextStyle(
                fontFamily: 'Bitter',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1,
                color: deltaColor,
                decoration: entry.dim ? TextDecoration.lineThrough : null,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
