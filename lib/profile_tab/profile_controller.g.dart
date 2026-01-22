// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(NetworkController)
final networkControllerProvider = NetworkControllerProvider._();

final class NetworkControllerProvider
    extends $NotifierProvider<NetworkController, List<Network>> {
  NetworkControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'networkControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$networkControllerHash();

  @$internal
  @override
  NetworkController create() => NetworkController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Network> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Network>>(value),
    );
  }
}

String _$networkControllerHash() => r'a316ed2f09511e00815247c99b7b705a6d3cbcb3';

abstract class _$NetworkController extends $Notifier<List<Network>> {
  List<Network> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<Network>, List<Network>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<Network>, List<Network>>,
              List<Network>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(IndustryController)
final industryControllerProvider = IndustryControllerProvider._();

final class IndustryControllerProvider
    extends $NotifierProvider<IndustryController, List<Industry>> {
  IndustryControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'industryControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$industryControllerHash();

  @$internal
  @override
  IndustryController create() => IndustryController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Industry> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Industry>>(value),
    );
  }
}

String _$industryControllerHash() =>
    r'3c6d1761cc4a0cb76507b99f7bde4608e6458b80';

abstract class _$IndustryController extends $Notifier<List<Industry>> {
  List<Industry> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<Industry>, List<Industry>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<Industry>, List<Industry>>,
              List<Industry>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(ProfileController)
final profileControllerProvider = ProfileControllerProvider._();

final class ProfileControllerProvider
    extends $NotifierProvider<ProfileController, ProfileState> {
  ProfileControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileControllerHash();

  @$internal
  @override
  ProfileController create() => ProfileController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileState>(value),
    );
  }
}

String _$profileControllerHash() => r'07c2410271889aaa939059dd44db6c41cf7a72c6';

abstract class _$ProfileController extends $Notifier<ProfileState> {
  ProfileState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ProfileState, ProfileState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProfileState, ProfileState>,
              ProfileState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
