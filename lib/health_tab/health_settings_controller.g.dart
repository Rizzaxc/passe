// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_settings_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether sync should detect standalone device workouts that have no
/// existing Passe activity (see `HealthSyncController._createStandaloneActivities`
/// in `health_sync_service.dart`) and create an unconfirmed activity for
/// review in "Detected workouts". Defaults to on; some users may not want
/// Passe reasoning about workouts they never opened the app for, even just
/// creating a row that needs a Dismiss tap.

@ProviderFor(StandaloneWorkoutSyncSetting)
final standaloneWorkoutSyncSettingProvider =
    StandaloneWorkoutSyncSettingProvider._();

/// Whether sync should detect standalone device workouts that have no
/// existing Passe activity (see `HealthSyncController._createStandaloneActivities`
/// in `health_sync_service.dart`) and create an unconfirmed activity for
/// review in "Detected workouts". Defaults to on; some users may not want
/// Passe reasoning about workouts they never opened the app for, even just
/// creating a row that needs a Dismiss tap.
final class StandaloneWorkoutSyncSettingProvider
    extends $AsyncNotifierProvider<StandaloneWorkoutSyncSetting, bool> {
  /// Whether sync should detect standalone device workouts that have no
  /// existing Passe activity (see `HealthSyncController._createStandaloneActivities`
  /// in `health_sync_service.dart`) and create an unconfirmed activity for
  /// review in "Detected workouts". Defaults to on; some users may not want
  /// Passe reasoning about workouts they never opened the app for, even just
  /// creating a row that needs a Dismiss tap.
  StandaloneWorkoutSyncSettingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'standaloneWorkoutSyncSettingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$standaloneWorkoutSyncSettingHash();

  @$internal
  @override
  StandaloneWorkoutSyncSetting create() => StandaloneWorkoutSyncSetting();
}

String _$standaloneWorkoutSyncSettingHash() =>
    r'a3712b6ab92d83ece64317b7abbc4833565039ba';

/// Whether sync should detect standalone device workouts that have no
/// existing Passe activity (see `HealthSyncController._createStandaloneActivities`
/// in `health_sync_service.dart`) and create an unconfirmed activity for
/// review in "Detected workouts". Defaults to on; some users may not want
/// Passe reasoning about workouts they never opened the app for, even just
/// creating a row that needs a Dismiss tap.

abstract class _$StandaloneWorkoutSyncSetting extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
