import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../router.dart';
import '../../ui/main.dart';
import '../health_data_controller.dart';
import '../health_data_service.dart';
import '../model/activity_health_row.dart';
import '../model/hr_sample.dart';
import 'recap_widgets.dart';
import 'zone_bar.dart';

/// Opens the per-activity health recap with the downsampled HR curve.
void showActivityRecapSheet(BuildContext context, ActivityHealthRow row) {
  showPSheet(
    context: context,
    maxHeightRatio: 1.0,
    builder: (ctx) => _RecapSheet(row: row, rootContext: context),
  );
}

class _RecapSheet extends ConsumerStatefulWidget {
  final ActivityHealthRow row;
  // The card's own context, kept around so the lobby link can pop this
  // sheet and navigate on a context guaranteed to outlive it — reusing this
  // sheet's own context after popping races the close animation. Same
  // pattern as terms_privacy_sheet.dart's delete-account tile.
  final BuildContext rootContext;
  const _RecapSheet({required this.row, required this.rootContext});

  @override
  ConsumerState<_RecapSheet> createState() => _RecapSheetState();
}

class _RecapSheetState extends ConsumerState<_RecapSheet> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final curve = ref.watch(_hrCurveProvider(row.activityId));
    final estimated = ref.watch(hrThresholdsProvider).value?.estimated ?? true;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          Row(
            spacing: 12,
            children: [
              SourceAvatar(row: row, size: 44),
              Expanded(
                child: Text(
                  cardTitleDateLabel(context, row.startTime),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.theme.typography.body.xl2.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              FButton.icon(
                variant: .ghost,
                onPress: () => Navigator.of(context).pop(),
                child: const Icon(FLucideIcons.x),
              ),
            ],
          ),

          _SourceSubsection(row: row, rootContext: widget.rootContext),

          FTabs(
            control: FTabControl.lifted(
              index: _tab,
              onChange: (i) => setState(() => _tab = i),
            ),
            children: [
              FTabEntry(
                label: Text('health.recap.tab.stats'.tr()),
                child: _StatsTab(row: row),
              ),
              FTabEntry(
                label: Text('health.recap.tab.chart'.tr()),
                child: _ChartTab(row: row, curve: curve, estimated: estimated),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Source subsection ──────────────────────────────────────────────────────

/// The lobby/coach/host name and location, pulled out of the header into
/// their own small block instead of being crammed under the title — a long
/// lobby name and a long venue name were fighting for the same single line.
/// Tappable through to that activity's own hub — the lobby's Planner tab
/// (scrolled to and highlighting this exact activity), the course, or the
/// freeplay listing. A standalone (self) activity has no hub to link to.
class _SourceSubsection extends StatelessWidget {
  final ActivityHealthRow row;
  final BuildContext rootContext;
  const _SourceSubsection({required this.row, required this.rootContext});

  void _openHub(BuildContext context) {
    Navigator.of(context).pop();
    if (!rootContext.mounted) return;
    switch (row.source) {
      case 'lobby' when row.lobbyId != null:
        LobbyDetailRoute(
          id: row.lobbyId!,
          $extra: row.sourceName,
          tab: 1, // Planner — where activity cards live.
          highlightActivityId: row.activityId,
        ).go(rootContext);
      case 'freeplay':
        // FreeplayDetailRoute takes the activity id directly, not a host id.
        FreeplayDetailRoute(id: row.activityId).go(rootContext);
      case 'professional' when row.courseId != null:
        CourseDetailRoute(id: row.courseId!).go(rootContext);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final isLinkable = switch (row.source) {
      'lobby' => row.lobbyId != null,
      'freeplay' => true,
      'professional' => row.courseId != null,
      _ => false,
    };

    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: context.theme.style.borderRadius.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Row(
            spacing: 8,
            children: [
              Icon(
                FLucideIcons.users,
                size: 15,
                color: colors.mutedForeground,
              ),
              Expanded(
                child: Text(
                  row.sourceName ?? sourceLabelKey(row.source).tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.theme.typography.body.sm.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isLinkable)
                Icon(
                  FLucideIcons.chevronRight,
                  size: 16,
                  color: colors.mutedForeground,
                ),
            ],
          ),
          if (row.locationLabel != null)
            Row(
              spacing: 8,
              children: [
                Icon(
                  FLucideIcons.mapPin,
                  size: 15,
                  color: colors.mutedForeground,
                ),
                Expanded(
                  child: Text(
                    row.locationLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.theme.typography.body.xs.copyWith(
                      color: colors.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );

    // A standalone (self) activity has no hub to link to — plain info, no
    // tap affordance, nothing to break.
    if (!isLinkable) return content;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openHub(context),
      child: content,
    );
  }
}

// ─── Stats tab ───────────────────────────────────────────────────────────────

/// Each stat is a labeled row rather than a bordered tile — a 2-column grid
/// of cards looked bulky and left barely enough vertical room for the icon
/// and value, let alone the label underneath (which silently overflowed
/// out of the tile). A plain list gives every stat its own full-width line:
/// icon, label, value — nothing competing for space.
class _StatsTab extends StatelessWidget {
  final ActivityHealthRow row;
  const _StatsTab({required this.row});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final rows = [
      if (row.durationMinutes != null)
        _StatRow(
          icon: FLucideIcons.timer,
          label: 'health.recap.duration'.tr(),
          value: _duration(row.durationMinutes!),
        ),
      if (row.avgHeartRate != null)
        _StatRow(
          icon: FLucideIcons.heartPulse,
          label: 'health.recap.avgHr'.tr(),
          value: '${row.avgHeartRate}',
          unit: 'bpm',
        ),
      if (row.maxHeartRate != null)
        _StatRow(
          icon: FLucideIcons.trendingUp,
          label: 'health.recap.maxHr'.tr(),
          value: '${row.maxHeartRate}',
          unit: 'bpm',
        ),
      if (row.activeCalories != null)
        _StatRow(
          icon: FLucideIcons.flame,
          label: 'health.recap.calories'.tr(),
          value: '${row.activeCalories!.round()}',
          unit: 'kcal',
        ),
      if (row.steps != null && row.steps! > 0)
        _StatRow(
          icon: FLucideIcons.footprints,
          label: 'health.recap.steps'.tr(),
          value: '${row.steps}',
        ),
      if (row.distanceMeters != null && row.distanceMeters! > 0)
        _StatRow(
          icon: FLucideIcons.route,
          label: 'health.recap.distance'.tr(),
          value: _distance(row.distanceMeters!),
        ),
      if (row.effortScore != null)
        _StatRow(
          icon: FLucideIcons.zap,
          label: 'health.recap.effort'.tr(),
          value: row.effortScore!.round().toString(),
        ),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i != rows.length - 1) Divider(height: 1, color: colors.border),
          ],
        ],
      ),
    );
  }

  String _duration(int minutes) =>
      minutes >= 60 ? '${minutes ~/ 60}h ${minutes % 60}m' : '${minutes}m';

  String _distance(double meters) => meters >= 1000
      ? '${(meters / 1000).toStringAsFixed(1)} km'
      : '${meters.round()} m';
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? unit;
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        spacing: 10,
        children: [
          Icon(icon, size: 18, color: colors.primary),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.theme.typography.body.sm,
            ),
          ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: context.theme.typography.body.sm.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (unit != null)
                  TextSpan(
                    text: ' $unit',
                    style: context.theme.typography.body.xs.copyWith(
                      color: colors.mutedForeground,
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

// ─── Chart tab ───────────────────────────────────────────────────────────────

class _ChartTab extends StatelessWidget {
  final ActivityHealthRow row;
  final AsyncValue<List<HrSamplePoint>> curve;
  final bool estimated;
  const _ChartTab({
    required this.row,
    required this.curve,
    required this.estimated,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 20,
        children: [
          curve.when(
            loading: () => const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => const SizedBox.shrink(),
            data: (points) => points.length < 2
                ? const SizedBox.shrink()
                : _HrCurveCard(points: points),
          ),
          _ZoneSection(row: row, estimated: estimated),
        ],
      ),
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
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].bpm.toDouble()),
    ];

    // Fixed 10-bpm gridlines rather than a computed interval — a spacing
    // that changes with the data range (e.g. 15.67 bpm) reads as arbitrary;
    // 10 is a normal, predictable unit for heart rate. Padding the range out
    // to the nearest 10 on each side keeps the curve off the plot's edges
    // without breaking that spacing.
    const yInterval = 10.0;
    final bpmValues = points.map((p) => p.bpm).toList();
    final minBpm = bpmValues.reduce((a, b) => a < b ? a : b);
    final maxBpm = bpmValues.reduce((a, b) => a > b ? a : b);
    final minY = ((minBpm - 5) / yInterval).floorToDouble() * yInterval;
    final maxY = ((maxBpm + 5) / yInterval).ceilToDouble() * yInterval;

    final midIndex = (points.length - 1) ~/ 2;
    final lastIndex = points.length - 1;
    final locale = context.locale.toString();
    // .toLocal() — points[i].timestamp is UTC (Supabase timestamptz).
    String timeAt(int i) =>
        DateFormat.Hm(locale).format(points[i].timestamp.toLocal());

    final axisLabelStyle = context.theme.typography.body.xs.copyWith(
      color: colors.mutedForeground,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Row(
          spacing: 6,
          children: [
            Icon(FLucideIcons.activity, size: 14, color: colors.primary),
            Text(
              'health.recap.hrCurve'.tr().toUpperCase(),
              style: context.theme.typography.body.xs.copyWith(
                color: colors.mutedForeground,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: lastIndex.toDouble(),
              minY: minY,
              maxY: maxY,
              lineTouchData: const LineTouchData(enabled: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: yInterval,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: colors.border, strokeWidth: 1),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(color: colors.border),
                  left: BorderSide(color: colors.border),
                  top: BorderSide.none,
                  right: BorderSide.none,
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: yInterval,
                    getTitlesWidget: (value, meta) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        '${value.round()}',
                        style: axisLabelStyle,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final i = value.round();
                      // Only start/middle/end — labeling every point would
                      // crowd the axis for a long session.
                      if (i != 0 && i != midIndex && i != lastIndex) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(timeAt(i), style: axisLabelStyle),
                      );
                    },
                  ),
                ),
              ),
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
            Icon(FLucideIcons.layers, size: 14, color: colors.primary),
            Text(
              'health.recap.zones'.tr().toUpperCase(),
              style: context.theme.typography.body.xs.copyWith(
                color: colors.mutedForeground,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            if (estimated)
              Text(
                'health.recap.estimated'.tr(),
                style: context.theme.typography.body.xs.copyWith(
                  color: colors.mutedForeground,
                ),
              ),
          ],
        ),
        ZoneBar(easy: easy, moderate: moderate, hard: hard),
      ],
    );
  }
}

/// Loads the persisted (downsampled) HR curve for one activity.
final _hrCurveProvider = FutureProvider.family<List<HrSamplePoint>, String>((
  ref,
  activityId,
) {
  return ref.watch(healthDataServiceProvider.notifier).loadHrCurve(activityId);
});
