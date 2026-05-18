// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selected_sport_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SelectedSportState)
final selectedSportStateProvider = SelectedSportStateProvider._();

final class SelectedSportStateProvider
    extends $AsyncNotifierProvider<SelectedSportState, Sport> {
  SelectedSportStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedSportStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedSportStateHash();

  @$internal
  @override
  SelectedSportState create() => SelectedSportState();
}

String _$selectedSportStateHash() =>
    r'd4ac244175180406c97369e48d2342738b5af2b1';

abstract class _$SelectedSportState extends $AsyncNotifier<Sport> {
  FutureOr<Sport> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Sport>, Sport>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Sport>, Sport>,
              AsyncValue<Sport>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(OthersAlertShown)
final othersAlertShownProvider = OthersAlertShownProvider._();

final class OthersAlertShownProvider
    extends $NotifierProvider<OthersAlertShown, bool> {
  OthersAlertShownProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'othersAlertShownProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$othersAlertShownHash();

  @$internal
  @override
  OthersAlertShown create() => OthersAlertShown();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$othersAlertShownHash() => r'bea7fda8a522db124b780b9199d29219f22c2618';

abstract class _$OthersAlertShown extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
