// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_metric.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The user's chosen visible metric set, persisted locally (display state only).

@ProviderFor(DashboardMetrics)
final dashboardMetricsProvider = DashboardMetricsProvider._();

/// The user's chosen visible metric set, persisted locally (display state only).
final class DashboardMetricsProvider
    extends $AsyncNotifierProvider<DashboardMetrics, List<HealthMetric>> {
  /// The user's chosen visible metric set, persisted locally (display state only).
  DashboardMetricsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dashboardMetricsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dashboardMetricsHash();

  @$internal
  @override
  DashboardMetrics create() => DashboardMetrics();
}

String _$dashboardMetricsHash() => r'b89d7de8aa57302056b3a5392d4320b2ad996760';

/// The user's chosen visible metric set, persisted locally (display state only).

abstract class _$DashboardMetrics extends $AsyncNotifier<List<HealthMetric>> {
  FutureOr<List<HealthMetric>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<HealthMetric>>, List<HealthMetric>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<HealthMetric>>, List<HealthMetric>>,
              AsyncValue<List<HealthMetric>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
