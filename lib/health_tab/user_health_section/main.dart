import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../ui/theme.dart';

class UserHealthSubtab extends StatelessWidget {
  const UserHealthSubtab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: const [
        _TrendCard(),
        SizedBox(height: 12),
        _ActivityLinkCard(),
      ],
    );
  }
}

// ─── Trend card ───────────────────────────────────────────────────────────────

class _TrendCard extends StatelessWidget {
  const _TrendCard();

  // 14 data points — calories burned per session over the last 30 days
  static const _points = <double>[
    22, 28, 24, 32, 30, 38, 34, 42, 40, 48, 44, 52, 50, 56,
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final crimson = colors.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.border),
        borderRadius: context.theme.style.borderRadius.md,
        boxShadow: context.theme.style.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Row(
            children: [
              Text(
                'health.trend.title'.tr(),
                style: context.theme.typography.sm.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                'health.trend.period'.tr(),
                style: context.theme.typography.xs.copyWith(
                  color: colors.mutedForeground,
                ),
              ),
            ],
          ),

          // Sparkline
          SizedBox(
            height: 80,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                minX: 0,
                maxX: (_points.length - 1).toDouble(),
                minY: 0,
                maxY: 60,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      _points.length,
                      (i) => FlSpot(i.toDouble(), _points[i]),
                    ),
                    isCurved: true,
                    color: crimson,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: crimson.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Stats row
          Row(
            children: [
              _StatItem(value: '612', label: 'health.trend.statCalories'.tr()),
              _Divider(),
              _StatItem(value: '148', label: 'health.trend.statHeartRate'.tr()),
              _Divider(),
              _StatItem(value: '6.4km', label: 'health.trend.statDistance'.tr()),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2,
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: context.theme.typography.xl2.fontFamily,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: context.theme.colors.foreground,
              letterSpacing: -0.3,
              height: 1,
            ),
          ),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: context.theme.typography.xs.fontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: context.theme.colors.mutedForeground,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: context.theme.colors.border,
      margin: const EdgeInsets.symmetric(horizontal: 12),
    );
  }
}

// ─── Activity link card ───────────────────────────────────────────────────────

class _ActivityLinkCard extends StatelessWidget {
  const _ActivityLinkCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.border),
        borderRadius: context.theme.style.borderRadius.md,
        boxShadow: context.theme.style.shadow,
      ),
      child: Row(
        spacing: 10,
        children: [
          Icon(FIcons.heartPulse, size: 22, color: colors.primary),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  'health.activity.title'.tr(),
                  style: context.theme.typography.sm.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'health.activity.summary'.tr(),
                  style: context.theme.typography.xs.copyWith(
                    color: colors.mutedForeground,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          _PlatformBadge(),
        ],
      ),
    );
  }
}

class _PlatformBadge extends StatelessWidget {
  const _PlatformBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: pbBlue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Apple Health',
        style: TextStyle(
          fontFamily: context.theme.typography.xs.fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: pbBlue,
        ),
      ),
    );
  }
}
