// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'host_mode_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HostModeState)
final hostModeStateProvider = HostModeStateProvider._();

final class HostModeStateProvider
    extends $AsyncNotifierProvider<HostModeState, bool> {
  HostModeStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hostModeStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hostModeStateHash();

  @$internal
  @override
  HostModeState create() => HostModeState();
}

String _$hostModeStateHash() => r'33308f3016500c0cdd024d02d67bda6baab4c2a3';

abstract class _$HostModeState extends $AsyncNotifier<bool> {
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
