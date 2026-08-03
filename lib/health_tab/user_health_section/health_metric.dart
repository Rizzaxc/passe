import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/user_preferences.dart';
import '../model/daily_health_summary.dart';

part 'health_metric.g.dart';

/// A body-trend metric the dashboard can surface. Backed by a populated
/// `daily_health_summary` column. `sleep_minutes` / `sleep_quality_score` /
/// `activity_count` are intentionally excluded — sleep isn't tracked (Health
/// Connect has no reliable sleep-stage source; see health_controller.dart),
/// and `activity_count` has no reliable device source.
enum HealthMetric {
  restingHr('health.metric.restingHr', 'bpm'),
  hrv('health.metric.hrv', 'ms'),
  weight('health.metric.weight', 'kg'),
  steps('health.metric.steps', ''),
  distance('health.metric.distance', 'km'),
  activeCalories('health.metric.activeCalories', 'kcal'),
  totalCalories('health.metric.totalCalories', 'kcal');

  const HealthMetric(this.labelKey, this.unit);

  final String labelKey;
  final String unit;

  /// Recovery-leaning default set.
  static const List<HealthMetric> defaults = [restingHr, hrv, weight];

  /// The raw numeric value for charting (null when the day lacks the metric).
  double? value(DailyHealthSummary s) => switch (this) {
    restingHr => s.restingHeartRate?.toDouble(),
    hrv => s.hrvSdnnMs ?? s.hrvRmssdMs,
    weight => s.weightKg,
    steps => s.steps?.toDouble(),
    distance => s.distanceMeters,
    activeCalories => s.activeCalories,
    totalCalories => s.totalCalories,
  };

  /// Human-facing display of a value (without unit).
  String format(double v) => switch (this) {
    distance => (v / 1000).toStringAsFixed(1),
    weight => v.toStringAsFixed(1),
    hrv => v.toStringAsFixed(0),
    _ => v.round().toString(),
  };
}

/// The user's chosen visible metric set, persisted locally (display state only).
@riverpod
class DashboardMetrics extends _$DashboardMetrics {
  static const _prefKey = 'health_dashboard_metrics';

  @override
  Future<List<HealthMetric>> build() async {
    final stored = await UserPreferences.instance.getStringList(_prefKey);
    if (stored == null) return HealthMetric.defaults;
    final byName = {for (final m in HealthMetric.values) m.name: m};
    final resolved = stored
        .map((s) => byName[s])
        .whereType<HealthMetric>()
        .toList();
    return resolved.isEmpty ? HealthMetric.defaults : resolved;
  }

  Future<void> toggle(HealthMetric metric) async {
    final current = [...?state.value];
    if (current.contains(metric)) {
      // Keep at least one metric visible.
      if (current.length == 1) return;
      current.remove(metric);
    } else {
      // Preserve canonical enum order.
      current
        ..add(metric)
        ..sort((a, b) => a.index.compareTo(b.index));
    }
    await UserPreferences.instance.setStringList(
      _prefKey,
      current.map((m) => m.name).toList(),
    );
    state = AsyncData(current);
  }
}
