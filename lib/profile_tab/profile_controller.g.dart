// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ProfileController)
final profileControllerProvider = ProfileControllerProvider._();

final class ProfileControllerProvider
    extends $NotifierProvider<ProfileController, UserDetails> {
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
  Override overrideWithValue(UserDetails value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserDetails>(value),
    );
  }
}

String _$profileControllerHash() => r'f1d56da81e09b677d2c02d0e576a73deaf1d38ce';

abstract class _$ProfileController extends $Notifier<UserDetails> {
  UserDetails build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<UserDetails, UserDetails>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<UserDetails, UserDetails>,
              UserDetails,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
