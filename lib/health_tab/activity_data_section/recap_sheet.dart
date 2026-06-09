import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../ui/main.dart';
import '../health_data_controller.dart';
import '../health_data_service.dart';
import '../model/activity_health_row.dart';
import '../model/hr_sample.dart';
import 'zone_bar.dart';

/// Opens the per-activity health recap with the downsampled HR curve.
void showActivityRecapSheet(BuildContext context, ActivityHealthRow row) {
  showPSheet(
    context: context,
    maxHeightRatio: 1.0,
    builder: (ctx) => _RecapSheet(row: row),
  );
}

class _RecapSheet extends ConsumerWidget {
  final ActivityHealthRow row;
  const _RecapSheet({required this.row});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final curve = ref.watch(_hrCurveProvider(row.activityId));
    final estimated = ref.watch(hrThresholdsProvider).value?.estimated ?? true;
    final dateLabel = DateFormat.MMMEd(context.locale.toString()).add_jm().format(row.startTime);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          PSheetTitle(label: dateLabel),
          if (row.locationLabel != null)
            Text(
              row.locationLabel!,
              style: context.theme.typography.sm.copyWith(color: colors.mutedForeground),
            ),

          // Headline metrics (max-HR-independent).
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (row.durationMinutes != null)
                _Stat(label: 'health.recap.duration'.tr(), value: _duration(row.durationMinutes!)),
              if (row.avgHeartRate != null)
                _Stat(label: 'health.recap.avgHr'.tr(), value: '${row.avgHeartRate} bpm'),
              if (row.activeCalories != null)
                _Stat(label: 'health.recap.calories'.tr(), value: '${row.activeCalories!.round()} kcal'),
              if (row.distanceMeters != null && row.distanceMeters! > 0)
                _Stat(label: 'health.recap.distance'.tr(), value: '${(row.distanceMeters! / 1000).toStringAsFixed(1)} km'),
              if (row.maxHeartRate != null)
                _Stat(label: 'health.recap.maxHr'.tr(), value: '${row.maxHeartRate} bpm'),
              if (row.effortScore != null)
                _Stat(label: 'health.recap.effort'.tr(), value: row.effortScore!.round().toString()),
            ],
          ),

          // HR curve.
          curve.when(
            loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
            error: (_, _) => const SizedBox.shrink(),
            data: (points) => points.length < 2
                ? const SizedBox.shrink()
                : _HrCurveCard(points: points),
          ),

          // 3-zone breakdown.
          _ZoneSection(row: row, estimated: estimated),
        ],
      ),
    );
  }

  String _duration(int minutes) =>
      minutes >= 60 ? '${minutes ~/ 60}h ${minutes % 60}m' : '${minutes}m';
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: context.theme.typography.xl.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.foreground,
            height: 1,
          ),
        ),
        Text(
          label.toUpperCase(),
          style: context.theme.typography.xs.copyWith(
            color: colors.mutedForeground,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

class _HrCurveCard extends StatelessWidget {
  final List<HrSamplePoint> points;
  const _HrCurveCard({required this.points});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final spots = [
      for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].bpm.toDouble()),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(
          'health.recap.hrCurve'.tr(),
          style: context.theme.typography.sm.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(
          height: 120,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineTouchData: const LineTouchData(enabled: false),
              minX: 0,
              maxX: (points.length - 1).toDouble(),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: colors.primary,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: true, color: colors.primary.withValues(alpha: 0.1)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ZoneSection extends StatelessWidget {
  final ActivityHealthRow row;
  final bool estimated;
  const _ZoneSection({required this.row, required this.estimated});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final easy = row.hrZoneEasySeconds ?? 0;
    final moderate = row.hrZoneModerateSeconds ?? 0;
    final hard = row.hrZoneHardSeconds ?? 0;
    if (easy + moderate + hard == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Row(
          spacing: 6,
          children: [
            Text(
              'health.recap.zones'.tr(),
              style: context.theme.typography.sm.copyWith(fontWeight: FontWeight.w700),
            ),
            if (estimated)
              Text(
                'health.recap.estimated'.tr(),
                style: context.theme.typography.xs.copyWith(color: colors.mutedForeground),
              ),
          ],
        ),
        ZoneBar(easy: easy, moderate: moderate, hard: hard),
      ],
    );
  }
}

/// Loads the persisted (downsampled) HR curve for one activity.
final _hrCurveProvider = FutureProvider.family<List<HrSamplePoint>, String>((ref, activityId) {
  return ref.watch(healthDataServiceProvider.notifier).loadHrCurve(activityId);
});
