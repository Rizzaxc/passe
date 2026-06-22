import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../ui/main.dart';
import '../health_data_controller.dart';
import '../model/daily_health_summary.dart';
import 'health_metric.dart';

class UserHealthSubtab extends ConsumerStatefulWidget {
  const UserHealthSubtab({super.key});

  @override
  ConsumerState<UserHealthSubtab> createState() => _UserHealthSubtabState();
}

class _UserHealthSubtabState extends ConsumerState<UserHealthSubtab> {
  HealthMetric? _chartMetric;

  @override
  Widget build(BuildContext context) {
    final trend = ref.watch(dailyHealthTrendProvider);
    final metrics = ref.watch(dashboardMetricsProvider).value ?? HealthMetric.defaults;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dailyHealthTrendProvider);
        await ref.read(dailyHealthTrendProvider.future);
      },
      child: trend.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text('health.error'.tr())),
            ),
          ],
        ),
        data: (days) {
          if (days.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [PEmptySectionPlaceholder(subtitle: 'health.userHealth.empty'.tr())],
            );
          }
          // Default the chart to the first visible metric.
          final chartMetric =
              (_chartMetric != null && metrics.contains(_chartMetric)) ? _chartMetric! : metrics.first;
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            children: [
              _HeaderRow(onCustomize: () => _showCustomizeSheet(context)),
              const SizedBox(height: 12),
              _SnapshotGrid(days: days, metrics: metrics),
              const SizedBox(height: 12),
              _TrendChartCard(
                days: days,
                metrics: metrics,
                selected: chartMetric,
                onSelect: (m) => setState(() => _chartMetric = m),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCustomizeSheet(BuildContext context) {
    showPSheet(
      context: context,
      maxHeightRatio: 0.9,
      builder: (ctx) => const _CustomizeMetricsSheet(),
    );
  }
}

// ─── Header ─────────────────────────────────────────────────────────────────

class _HeaderRow extends StatelessWidget {
  final VoidCallback onCustomize;
  const _HeaderRow({required this.onCustomize});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'health.userHealth.title'.tr(),
          style: context.theme.typography.body.lg.copyWith(fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        FButton.icon(
          variant: .ghost,
          onPress: onCustomize,
          child: Icon(FLucideIcons.slidersHorizontal, size: 18),
        ),
      ],
    );
  }
}

// ─── Snapshot cards ───────────────────────────────────────────────────────────

class _SnapshotGrid extends StatelessWidget {
  final List<DailyHealthSummary> days;
  final List<HealthMetric> metrics;
  const _SnapshotGrid({required this.days, required this.metrics});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      const spacing = 12.0;
      final cardWidth = (constraints.maxWidth - spacing) / 2;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final m in metrics)
            SizedBox(
              width: cardWidth,
              child: _SnapshotCard(metric: m, days: days),
            ),
        ],
      );
    });
  }
}

class _SnapshotCard extends StatelessWidget {
  final HealthMetric metric;
  final List<DailyHealthSummary> days;
  const _SnapshotCard({required this.metric, required this.days});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    // days are newest-first.
    final values = days.map(metric.value).whereType<double>().toList();
    final latest = values.isNotEmpty ? values.first : null;
    // Delta vs the mean of the prior (up to) 7 readings.
    double? delta;
    if (values.length >= 2) {
      final prior = values.skip(1).take(7).toList();
      if (prior.isNotEmpty) {
        final mean = prior.reduce((a, b) => a + b) / prior.length;
        delta = latest! - mean;
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.border),
        borderRadius: context.theme.style.borderRadius.md,
        boxShadow: context.theme.style.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Text(
            metric.labelKey.tr().toUpperCase(),
            style: context.theme.typography.body.xs.copyWith(
              color: colors.mutedForeground,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            spacing: 4,
            children: [
              Text(
                latest != null ? metric.format(latest) : '—',
                style: TextStyle(
                  fontFamily: context.theme.typography.body.xl2.fontFamily,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: colors.foreground,
                  height: 1,
                ),
              ),
              if (metric.unit.isNotEmpty && latest != null)
                Text(
                  metric.unit,
                  style: context.theme.typography.body.xs.copyWith(color: colors.mutedForeground),
                ),
            ],
          ),
          if (delta != null && delta.abs() >= 0.05)
            Row(
              spacing: 2,
              children: [
                Icon(
                  delta > 0 ? FLucideIcons.arrowUp : FLucideIcons.arrowDown,
                  size: 12,
                  color: colors.mutedForeground,
                ),
                Text(
                  metric.format(delta.abs()),
                  style: context.theme.typography.body.xs.copyWith(color: colors.mutedForeground),
                ),
              ],
            )
          else
            const SizedBox(height: 14),
        ],
      ),
    );
  }
}

// ─── Trend chart ──────────────────────────────────────────────────────────────

class _TrendChartCard extends StatelessWidget {
  final List<DailyHealthSummary> days;
  final List<HealthMetric> metrics;
  final HealthMetric selected;
  final ValueChanged<HealthMetric> onSelect;

  const _TrendChartCard({
    required this.days,
    required this.metrics,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    // Chronological for the x-axis.
    final chronological = days.reversed.toList();
    final spots = <FlSpot>[];
    for (var i = 0; i < chronological.length; i++) {
      final v = selected.value(chronological[i]);
      if (v != null) spots.add(FlSpot(i.toDouble(), v));
    }

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
          // Metric selector chips (only the visible metrics).
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: 6,
              children: [
                for (final m in metrics)
                  _MetricChip(
                    label: m.labelKey.tr(),
                    selected: m == selected,
                    onTap: () => onSelect(m),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 140,
            child: spots.length < 2
                ? Center(
                    child: Text(
                      'health.trend.insufficient'.tr(),
                      style: context.theme.typography.body.xs.copyWith(color: colors.mutedForeground),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineTouchData: const LineTouchData(enabled: false),
                      minX: 0,
                      maxX: (days.length - 1).toDouble(),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: colors.primary,
                          barWidth: 2,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: colors.primary.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          Text(
            'health.trend.period'.tr(),
            style: context.theme.typography.body.xs.copyWith(color: colors.mutedForeground),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _MetricChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.secondary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: context.theme.typography.body.xs.copyWith(
            color: selected ? colors.primaryForeground : colors.mutedForeground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─── Customize sheet ──────────────────────────────────────────────────────────

class _CustomizeMetricsSheet extends ConsumerWidget {
  const _CustomizeMetricsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(dashboardMetricsProvider).value ?? HealthMetric.defaults;
    final colors = context.theme.colors;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 4,
        children: [
          PSheetTitle(label: 'health.customize.title'.tr()),
          const SizedBox(height: 8),
          for (final m in HealthMetric.values)
            GestureDetector(
              onTap: () => ref.read(dashboardMetricsProvider.notifier).toggle(m),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        m.labelKey.tr(),
                        style: context.theme.typography.body.md,
                      ),
                    ),
                    Icon(
                      selected.contains(m) ? FLucideIcons.checkCheck : FLucideIcons.plus,
                      size: 18,
                      color: selected.contains(m) ? colors.primary : colors.mutedForeground,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
