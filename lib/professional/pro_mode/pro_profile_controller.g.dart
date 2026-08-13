// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pro_profile_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(myProfessionalProfile)
final myProfessionalProfileProvider = MyProfessionalProfileFamily._();

final class MyProfessionalProfileProvider
    extends
        $FunctionalProvider<
          AsyncValue<ProSelfProfile>,
          ProSelfProfile,
          FutureOr<ProSelfProfile>
        >
    with $FutureModifier<ProSelfProfile>, $FutureProvider<ProSelfProfile> {
  MyProfessionalProfileProvider._({
    required MyProfessionalProfileFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'myProfessionalProfileProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$myProfessionalProfileHash();

  @override
  String toString() {
    return r'myProfessionalProfileProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ProSelfProfile> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ProSelfProfile> create(Ref ref) {
    final argument = this.argument as String;
    return myProfessionalProfile(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MyProfessionalProfileProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$myProfessionalProfileHash() =>
    r'fc0c5ed2eaf68b03e7e0f54dd2d809a36532b1b6';

final class MyProfessionalProfileFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ProSelfProfile>, String> {
  MyProfessionalProfileFamily._()
    : super(
        retry: null,
        name: r'myProfessionalProfileProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MyProfessionalProfileProvider call(String professionalId) =>
      MyProfessionalProfileProvider._(argument: professionalId, from: this);

  @override
  String toString() => r'myProfessionalProfileProvider';
}

/// Commits public name, bio, contact, and schedule edits. RLS scopes writes to
/// the linked professional row owned by the caller.

@ProviderFor(ProProfileEditController)
final proProfileEditControllerProvider = ProProfileEditControllerFamily._();

/// Commits public name, bio, contact, and schedule edits. RLS scopes writes to
/// the linked professional row owned by the caller.
final class ProProfileEditControllerProvider
    extends $NotifierProvider<ProProfileEditController, bool> {
  /// Commits public name, bio, contact, and schedule edits. RLS scopes writes to
  /// the linked professional row owned by the caller.
  ProProfileEditControllerProvider._({
    required ProProfileEditControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'proProfileEditControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$proProfileEditControllerHash();

  @override
  String toString() {
    return r'proProfileEditControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ProProfileEditController create() => ProProfileEditController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProProfileEditControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$proProfileEditControllerHash() =>
    r'619a68baabaa3dd25d476f09b7387cd7ae1bdd2a';

/// Commits public name, bio, contact, and schedule edits. RLS scopes writes to
/// the linked professional row owned by the caller.

final class ProProfileEditControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ProProfileEditController,
          bool,
          bool,
          bool,
          String
        > {
  ProProfileEditControllerFamily._()
    : super(
        retry: null,
        name: r'proProfileEditControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Commits public name, bio, contact, and schedule edits. RLS scopes writes to
  /// the linked professional row owned by the caller.

  ProProfileEditControllerProvider call(String professionalId) =>
      ProProfileEditControllerProvider._(argument: professionalId, from: this);

  @override
  String toString() => r'proProfileEditControllerProvider';
}

/// Commits public name, bio, contact, and schedule edits. RLS scopes writes to
/// the linked professional row owned by the caller.

abstract class _$ProProfileEditController extends $Notifier<bool> {
  late final _$args = ref.$arg as String;
  String get professionalId => _$args;

  bool build(String professionalId);
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
