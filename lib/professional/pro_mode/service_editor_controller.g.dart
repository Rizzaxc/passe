// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_editor_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(myServices)
final myServicesProvider = MyServicesFamily._();

final class MyServicesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProfessionalServiceRow>>,
          List<ProfessionalServiceRow>,
          FutureOr<List<ProfessionalServiceRow>>
        >
    with
        $FutureModifier<List<ProfessionalServiceRow>>,
        $FutureProvider<List<ProfessionalServiceRow>> {
  MyServicesProvider._({
    required MyServicesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'myServicesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$myServicesHash();

  @override
  String toString() {
    return r'myServicesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ProfessionalServiceRow>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ProfessionalServiceRow>> create(Ref ref) {
    final argument = this.argument as String;
    return myServices(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MyServicesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$myServicesHash() => r'aadad6860ad021499c169e55646b66d3d4bbae93';

final class MyServicesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<ProfessionalServiceRow>>,
          String
        > {
  MyServicesFamily._()
    : super(
        retry: null,
        name: r'myServicesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MyServicesProvider call(String professionalId) =>
      MyServicesProvider._(argument: professionalId, from: this);

  @override
  String toString() => r'myServicesProvider';
}

/// Create/edit/(de)activate the linked professional's own services. RLS
/// ("Linked professionals can manage their own services") already scopes
/// writes to the caller's own `professional_id`.

@ProviderFor(ServiceEditorController)
final serviceEditorControllerProvider = ServiceEditorControllerFamily._();

/// Create/edit/(de)activate the linked professional's own services. RLS
/// ("Linked professionals can manage their own services") already scopes
/// writes to the caller's own `professional_id`.
final class ServiceEditorControllerProvider
    extends $NotifierProvider<ServiceEditorController, bool> {
  /// Create/edit/(de)activate the linked professional's own services. RLS
  /// ("Linked professionals can manage their own services") already scopes
  /// writes to the caller's own `professional_id`.
  ServiceEditorControllerProvider._({
    required ServiceEditorControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'serviceEditorControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$serviceEditorControllerHash();

  @override
  String toString() {
    return r'serviceEditorControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ServiceEditorController create() => ServiceEditorController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ServiceEditorControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$serviceEditorControllerHash() =>
    r'7efda13e84e2cbb77c5832e3af8d202b1700437c';

/// Create/edit/(de)activate the linked professional's own services. RLS
/// ("Linked professionals can manage their own services") already scopes
/// writes to the caller's own `professional_id`.

final class ServiceEditorControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ServiceEditorController,
          bool,
          bool,
          bool,
          String
        > {
  ServiceEditorControllerFamily._()
    : super(
        retry: null,
        name: r'serviceEditorControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Create/edit/(de)activate the linked professional's own services. RLS
  /// ("Linked professionals can manage their own services") already scopes
  /// writes to the caller's own `professional_id`.

  ServiceEditorControllerProvider call(String professionalId) =>
      ServiceEditorControllerProvider._(argument: professionalId, from: this);

  @override
  String toString() => r'serviceEditorControllerProvider';
}

/// Create/edit/(de)activate the linked professional's own services. RLS
/// ("Linked professionals can manage their own services") already scopes
/// writes to the caller's own `professional_id`.

abstract class _$ServiceEditorController extends $Notifier<bool> {
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
