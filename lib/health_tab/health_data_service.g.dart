// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_data_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Service for reading health data and syncing to backend.

@ProviderFor(HealthDataService)
final healthDataServiceProvider = HealthDataServiceProvider._();

/// Service for reading health data and syncing to backend.
final class HealthDataServiceProvider
    extends $NotifierProvider<HealthDataService, void> {
  /// Service for reading health data and syncing to backend.
  HealthDataServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'healthDataServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$healthDataServiceHash();

  @$internal
  @override
  HealthDataService create() => HealthDataService();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$healthDataServiceHash() => r'0aefa59aab035b2eabac825a5d2573c0d8cc0798';

/// Service for reading health data and syncing to backend.

abstract class _$HealthDataService extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
