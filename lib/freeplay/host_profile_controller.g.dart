// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'host_profile_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Reads the self-editable Host name through the same narrow table surface
/// used for saving it. The linked-Host RPC remains the source of identity and
/// the rest of the Host profile.

@ProviderFor(myHostDisplayName)
final myHostDisplayNameProvider = MyHostDisplayNameFamily._();

/// Reads the self-editable Host name through the same narrow table surface
/// used for saving it. The linked-Host RPC remains the source of identity and
/// the rest of the Host profile.

final class MyHostDisplayNameProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// Reads the self-editable Host name through the same narrow table surface
  /// used for saving it. The linked-Host RPC remains the source of identity and
  /// the rest of the Host profile.
  MyHostDisplayNameProvider._({
    required MyHostDisplayNameFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'myHostDisplayNameProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$myHostDisplayNameHash();

  @override
  String toString() {
    return r'myHostDisplayNameProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    final argument = this.argument as String;
    return myHostDisplayName(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MyHostDisplayNameProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$myHostDisplayNameHash() => r'b1880514b5e695def31951a19f48ccf59cc4a15c';

/// Reads the self-editable Host name through the same narrow table surface
/// used for saving it. The linked-Host RPC remains the source of identity and
/// the rest of the Host profile.

final class MyHostDisplayNameFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String>, String> {
  MyHostDisplayNameFamily._()
    : super(
        retry: null,
        name: r'myHostDisplayNameProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Reads the self-editable Host name through the same narrow table surface
  /// used for saving it. The linked-Host RPC remains the source of identity and
  /// the rest of the Host profile.

  MyHostDisplayNameProvider call(String hostId) =>
      MyHostDisplayNameProvider._(argument: hostId, from: this);

  @override
  String toString() => r'myHostDisplayNameProvider';
}

/// Commits the Host's public name independently from their account username.
/// RLS and column privileges limit the write to the caller's own Host row and
/// to `display_name` only.

@ProviderFor(HostProfileEditController)
final hostProfileEditControllerProvider = HostProfileEditControllerFamily._();

/// Commits the Host's public name independently from their account username.
/// RLS and column privileges limit the write to the caller's own Host row and
/// to `display_name` only.
final class HostProfileEditControllerProvider
    extends $NotifierProvider<HostProfileEditController, bool> {
  /// Commits the Host's public name independently from their account username.
  /// RLS and column privileges limit the write to the caller's own Host row and
  /// to `display_name` only.
  HostProfileEditControllerProvider._({
    required HostProfileEditControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'hostProfileEditControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$hostProfileEditControllerHash();

  @override
  String toString() {
    return r'hostProfileEditControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  HostProfileEditController create() => HostProfileEditController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is HostProfileEditControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$hostProfileEditControllerHash() =>
    r'0ef63d984f2a15cbf45b041b35601d9f2fe80099';

/// Commits the Host's public name independently from their account username.
/// RLS and column privileges limit the write to the caller's own Host row and
/// to `display_name` only.

final class HostProfileEditControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          HostProfileEditController,
          bool,
          bool,
          bool,
          String
        > {
  HostProfileEditControllerFamily._()
    : super(
        retry: null,
        name: r'hostProfileEditControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Commits the Host's public name independently from their account username.
  /// RLS and column privileges limit the write to the caller's own Host row and
  /// to `display_name` only.

  HostProfileEditControllerProvider call(String hostId) =>
      HostProfileEditControllerProvider._(argument: hostId, from: this);

  @override
  String toString() => r'hostProfileEditControllerProvider';
}

/// Commits the Host's public name independently from their account username.
/// RLS and column privileges limit the write to the caller's own Host row and
/// to `display_name` only.

abstract class _$HostProfileEditController extends $Notifier<bool> {
  late final _$args = ref.$arg as String;
  String get hostId => _$args;

  bool build(String hostId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
