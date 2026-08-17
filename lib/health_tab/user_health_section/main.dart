import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../ui/main.dart';
import '../activity_data_section/zone_bar.dart';
import '../health_data_controller.dart';
import '../health_data_service.dart';
import '../model/daily_health_summary.dart';
import '../vitality_score_controller.dart';
import 'health_metric.dart';
import 'vitality_score_card.dart';

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
    final metrics =
        ref.watch(dashboardMetricsProvider).value ?? HealthMetric.defaults;
    final vitalityScore = ref.watch(vitalityScoreSummaryProvider).value;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dailyHealthTrendProvider);
        ref.invalidate(vitalityScoreSummaryProvider);
        await Future.wait([
          ref.read(dailyHealthTrendProvider.future),
          ref.read(vitalityScoreSummaryProvider.future),
        ]);
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
          // Default the chart to the first visible metric. Renders the real
          // dashboard shell (dashes + "not enough data") even with zero days,
          // rather than swapping in a generic empty state.
          final chartMetric =
              (_chartMetric != null && metrics.contains(_chartMetric))
              ? _chartMetric!
              : metrics.first;
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              VitalityScoreCard(score: vitalityScore),
              const SizedBox(height: 12),
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
              const SizedBox(height: 12),
              const _HrZoneSection(),
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
          style: context.theme.typography.body.lg.copyWith(
            fontWeight: FontWeight.w700,
          ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
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
      },
    );
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
                  style: context.theme.typography.body.xs.copyWith(
                    color: colors.mutedForeground,
                  ),
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
                  style: context.theme.typography.body.xs.copyWith(
                    color: colors.mutedForeground,
                  ),
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

    // The chart always renders — an empty axis reads worse than a flag. With
    // fewer than 2 real points there's nothing to draw a real trend from, so
    // fall back to a flat, muted, dashed line (at the one known value, or 0)
    // and surface a "not enough data" chip instead of blanking the card.
    final reliable = spots.length >= 2;
    final maxX = (days.length - 1).clamp(1, double.infinity).toDouble();
    final displaySpots = reliable
        ? spots
        : [
            FlSpot(0, spots.isNotEmpty ? spots.first.y : 0),
            FlSpot(maxX, spots.isNotEmpty ? spots.first.y : 0),
          ];

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
            child: Stack(
              children: [
                LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineTouchData: const LineTouchData(enabled: false),
                    minX: 0,
                    maxX: maxX,
                    lineBarsData: [
                      LineChartBarData(
                        spots: displaySpots,
                        isCurved: reliable,
                        color: reliable ? colors.primary : colors.border,
                        barWidth: 2,
                        dashArray: reliable ? null : [6, 4],
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: reliable,
                          color: colors.primary.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!reliable)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: _UnreliableDataChip(
                      label: 'health.trend.insufficient'.tr(),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            'health.trend.period'.tr(),
            style: context.theme.typography.body.xs.copyWith(
              color: colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

/// Flags a fallback flat/dashed trend line as not a real reading, rather
/// than blanking the chart entirely — an empty state never looks good, but
/// a fabricated-looking line without a flag would be misleading.
class _UnreliableDataChip extends StatelessWidget {
  final String label;
  const _UnreliableDataChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Icon(
            FLucideIcons.triangleAlert,
            size: 11,
            color: colors.mutedForeground,
          ),
          Text(
            label,
            style: context.theme.typography.body.xs.copyWith(
              color: colors.mutedForeground,
              fontWeight: FontWeight.w600,
            ),
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
  const _MetricChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

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
    final selected =
        ref.watch(dashboardMetricsProvider).value ?? HealthMetric.defaults;
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
              onTap: () =>
                  ref.read(dashboardMetricsProvider.notifier).toggle(m),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 4,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        m.labelKey.tr(),
                        style: context.theme.typography.body.md,
                      ),
                    ),
                    Icon(
                      selected.contains(m)
                          ? FLucideIcons.checkCheck
                          : FLucideIcons.plus,
                      size: 18,
                      color: selected.contains(m)
                          ? colors.primary
                          : colors.mutedForeground,
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

// ─── HR Zone ────────────────────────────────────────────────────────────────

class _HrZoneSection extends ConsumerWidget {
  const _HrZoneSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final thresholds = ref.watch(hrThresholdsProvider).value;

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
        spacing: 16,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 3,
                  children: [
                    Row(
                      children: [
                        Text(
                          'health.hrZone.title'.tr(),
                          style: context.theme.typography.body.sm.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (thresholds?.estimated ?? false) ...[
                          const SizedBox(width: 6),
                          Text(
                            'health.recap.estimated'.tr(),
                            style: context.theme.typography.body.xs.copyWith(
                              color: colors.mutedForeground,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (thresholds != null)
                      Text(
                        'health.hrZone.maxHrLine'.tr(
                          namedArgs: {'value': '${thresholds.maxHr}'},
                        ),
                        style: context.theme.typography.body.xs.copyWith(
                          color: colors.mutedForeground,
                        ),
                      ),
                  ],
                ),
              ),
              FButton.icon(
                variant: .ghost,
                onPress: () => _showEditSheet(context, thresholds),
                child: Icon(FLucideIcons.pencil, size: 16),
              ),
            ],
          ),
          if (thresholds != null) ...[
            _ZoneRow(
              color: zoneEasyColor,
              name: 'health.zone.easy'.tr(),
              range: '< ${thresholds.lt1} bpm',
              description: 'health.hrZone.zoneDesc.easy'.tr(),
            ),
            _ZoneRow(
              color: zoneModerateColor,
              name: 'health.zone.moderate'.tr(),
              range: '${thresholds.lt1}–${thresholds.lt2} bpm',
              description: 'health.hrZone.zoneDesc.moderate'.tr(),
            ),
            _ZoneRow(
              color: colors.primary,
              name: 'health.zone.hard'.tr(),
              range: '> ${thresholds.lt2} bpm',
              description: 'health.hrZone.zoneDesc.hard'.tr(),
            ),
          ],
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context, HrThresholds? current) {
    showPSheet(
      context: context,
      builder: (_) => _HrZoneEditSheet(current: current),
    );
  }
}

class _ZoneRow extends StatelessWidget {
  final Color color;
  final String name;
  final String range;
  final String description;

  const _ZoneRow({
    required this.color,
    required this.name,
    required this.range,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Row(
          spacing: 6,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            Text(
              name,
              style: context.theme.typography.body.sm.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              range,
              style: context.theme.typography.body.xs.copyWith(
                color: colors.mutedForeground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Text(
            description,
            style: context.theme.typography.body.xs.copyWith(
              color: colors.mutedForeground,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _HrZoneEditSheet extends ConsumerStatefulWidget {
  final HrThresholds? current;
  const _HrZoneEditSheet({required this.current});

  @override
  ConsumerState<_HrZoneEditSheet> createState() => _HrZoneEditSheetState();
}

class _HrZoneEditSheetState extends ConsumerState<_HrZoneEditSheet> {
  late final TextEditingController _maxHrController;
  late final TextEditingController _lt1Controller;
  late final TextEditingController _lt2Controller;

  @override
  void initState() {
    super.initState();
    final c = widget.current;
    _maxHrController = TextEditingController(text: c?.maxHr.toString() ?? '');
    _lt1Controller = TextEditingController(text: c?.lt1.toString() ?? '');
    _lt2Controller = TextEditingController(text: c?.lt2.toString() ?? '');
  }

  @override
  void dispose() {
    _maxHrController.dispose();
    _lt1Controller.dispose();
    _lt2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(hrThresholdControllerProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          PSheetTitle(label: 'health.hrZone.edit.title'.tr()),
          Text(
            'health.hrZone.edit.description'.tr(),
            style: context.theme.typography.body.sm.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
          ),
          FTextField(
            label: Text('health.hrZone.edit.maxHrLabel'.tr()),
            hint: '190',
            control: FTextFieldControl.managed(controller: _maxHrController),
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
          ),
          FTextField(
            label: Text('health.hrZone.edit.lt1Label'.tr()),
            hint: '150',
            control: FTextFieldControl.managed(controller: _lt1Controller),
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
          ),
          FTextField(
            label: Text('health.hrZone.edit.lt2Label'.tr()),
            hint: '165',
            control: FTextFieldControl.managed(controller: _lt2Controller),
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
          ),
          FButton(
            onPress: saving ? null : _submit,
            child: saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('health.hrZone.edit.save'.tr()),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final lt1 = int.tryParse(_lt1Controller.text.trim());
    final lt2 = int.tryParse(_lt2Controller.text.trim());
    final maxHrText = _maxHrController.text.trim();
    final maxHr = maxHrText.isEmpty ? null : int.tryParse(maxHrText);

    final valid =
        lt1 != null &&
        lt2 != null &&
        lt1 > 0 &&
        lt2 > lt1 &&
        lt1 <= 250 &&
        lt2 <= 250 &&
        (maxHr == null || (maxHr > lt2 && maxHr <= 250));
    if (!valid) {
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleAlert),
        variant: .destructive,
        title: Text('health.hrZone.edit.invalid'.tr()),
        alignment: .bottomCenter,
      );
      return;
    }

    await ref
        .read(hrThresholdControllerProvider.notifier)
        .save(lt1Bpm: lt1, lt2Bpm: lt2, maxHeartRate: maxHr);

    if (!mounted) return;
    Navigator.of(context).pop();
    showFToast(
      context: context,
      icon: const Icon(FLucideIcons.check),
      title: Text('health.hrZone.edit.saved'.tr()),
      alignment: .bottomCenter,
    );
  }
}
