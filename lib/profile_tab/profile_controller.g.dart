// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(NetworkSearchController)
final networkSearchControllerProvider = NetworkSearchControllerProvider._();

final class NetworkSearchControllerProvider
    extends $NotifierProvider<NetworkSearchController, NetworkSearchState> {
  NetworkSearchControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'networkSearchControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$networkSearchControllerHash();

  @$internal
  @override
  NetworkSearchController create() => NetworkSearchController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NetworkSearchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NetworkSearchState>(value),
    );
  }
}

String _$networkSearchControllerHash() =>
    r'7ec57b1ebe00c9bed3d01c72804515f3b8adafe0';

abstract class _$NetworkSearchController extends $Notifier<NetworkSearchState> {
  NetworkSearchState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<NetworkSearchState, NetworkSearchState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NetworkSearchState, NetworkSearchState>,
              NetworkSearchState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

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

String _$networkControllerHash() => r'4a62a9e9c7206c954c9506da9f4a206b78052869';

abstract class _$NetworkController extends $Notifier<List<Network>> {
  List<Network> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<Network>, List<Network>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<Network>, List<Network>>,
              List<Network>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
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
    r'5c48af6b0b94fc9713482229fd2e04217552a1ec';

abstract class _$IndustryController extends $Notifier<List<Industry>> {
  List<Industry> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<Industry>, List<Industry>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<Industry>, List<Industry>>,
              List<Industry>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
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

String _$profileControllerHash() => r'49c841988003f98fabc2dc952aef08dfbc7cf5d5';

abstract class _$ProfileController extends $Notifier<ProfileState> {
  ProfileState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ProfileState, ProfileState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProfileState, ProfileState>,
              ProfileState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
