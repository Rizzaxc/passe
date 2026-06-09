// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_sync_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The device → Supabase sync engine. Fired once on app launch (non-blocking)
/// and on the explicit Sync button. Pull-to-refresh does NOT call this — it only
/// re-reads Supabase via the data providers.

@ProviderFor(HealthSyncController)
final healthSyncControllerProvider = HealthSyncControllerProvider._();

/// The device → Supabase sync engine. Fired once on app launch (non-blocking)
/// and on the explicit Sync button. Pull-to-refresh does NOT call this — it only
/// re-reads Supabase via the data providers.
final class HealthSyncControllerProvider
    extends $NotifierProvider<HealthSyncController, HealthSyncPhase> {
  /// The device → Supabase sync engine. Fired once on app launch (non-blocking)
  /// and on the explicit Sync button. Pull-to-refresh does NOT call this — it only
  /// re-reads Supabase via the data providers.
  HealthSyncControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'healthSyncControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$healthSyncControllerHash();

  @$internal
  @override
  HealthSyncController create() => HealthSyncController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HealthSyncPhase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HealthSyncPhase>(value),
    );
  }
}

String _$healthSyncControllerHash() =>
    r'758ff85d84407ae4419be868a73ffec5e55bb62a';

/// The device → Supabase sync engine. Fired once on app launch (non-blocking)
/// and on the explicit Sync button. Pull-to-refresh does NOT call this — it only
/// re-reads Supabase via the data providers.

abstract class _$HealthSyncController extends $Notifier<HealthSyncPhase> {
  HealthSyncPhase build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<HealthSyncPhase, HealthSyncPhase>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<HealthSyncPhase, HealthSyncPhase>,
              HealthSyncPhase,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
