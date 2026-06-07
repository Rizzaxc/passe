// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HealthController)
final healthControllerProvider = HealthControllerProvider._();

final class HealthControllerProvider
    extends $AsyncNotifierProvider<HealthController, HealthLinkStatus> {
  HealthControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'healthControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$healthControllerHash();

  @$internal
  @override
  HealthController create() => HealthController();
}

String _$healthControllerHash() => r'1c256aa8bff6ac17ad7b81dc67921eaaad75f1f6';

abstract class _$HealthController extends $AsyncNotifier<HealthLinkStatus> {
  FutureOr<HealthLinkStatus> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<HealthLinkStatus>, HealthLinkStatus>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<HealthLinkStatus>, HealthLinkStatus>,
              AsyncValue<HealthLinkStatus>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
