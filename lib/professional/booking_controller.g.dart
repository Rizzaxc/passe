// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Active services offered by one professional, for the booking sheet's
/// service picker. RLS only exposes services for *verified* professionals
/// (`professional_service` "Enable read for active services..." policy),
/// so this comes back empty for an unverified pro.

@ProviderFor(professionalServices)
final professionalServicesProvider = ProfessionalServicesFamily._();

/// Active services offered by one professional, for the booking sheet's
/// service picker. RLS only exposes services for *verified* professionals
/// (`professional_service` "Enable read for active services..." policy),
/// so this comes back empty for an unverified pro.

final class ProfessionalServicesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProfessionalServiceOption>>,
          List<ProfessionalServiceOption>,
          FutureOr<List<ProfessionalServiceOption>>
        >
    with
        $FutureModifier<List<ProfessionalServiceOption>>,
        $FutureProvider<List<ProfessionalServiceOption>> {
  /// Active services offered by one professional, for the booking sheet's
  /// service picker. RLS only exposes services for *verified* professionals
  /// (`professional_service` "Enable read for active services..." policy),
  /// so this comes back empty for an unverified pro.
  ProfessionalServicesProvider._({
    required ProfessionalServicesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'professionalServicesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$professionalServicesHash();

  @override
  String toString() {
    return r'professionalServicesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ProfessionalServiceOption>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ProfessionalServiceOption>> create(Ref ref) {
    final argument = this.argument as String;
    return professionalServices(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ProfessionalServicesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$professionalServicesHash() =>
    r'78ed88e977594ea870a7b20d529f2f69656b607e';

/// Active services offered by one professional, for the booking sheet's
/// service picker. RLS only exposes services for *verified* professionals
/// (`professional_service` "Enable read for active services..." policy),
/// so this comes back empty for an unverified pro.

final class ProfessionalServicesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<ProfessionalServiceOption>>,
          String
        > {
  ProfessionalServicesFamily._()
    : super(
        retry: null,
        name: r'professionalServicesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Active services offered by one professional, for the booking sheet's
  /// service picker. RLS only exposes services for *verified* professionals
  /// (`professional_service` "Enable read for active services..." policy),
  /// so this comes back empty for an unverified pro.

  ProfessionalServicesProvider call(String professionalId) =>
      ProfessionalServicesProvider._(argument: professionalId, from: this);

  @override
  String toString() => r'professionalServicesProvider';
}

/// Creates a `professional_booking` row for one professional. RLS ("Clients
/// can manage their own bookings") scopes the insert to the caller as
/// `client_user_id`; the row starts at the default `requested` status and
/// the professional accepts/rejects it out of band (no in-app flow for the
/// professional side yet).

@ProviderFor(ProfessionalBookingController)
final professionalBookingControllerProvider =
    ProfessionalBookingControllerFamily._();

/// Creates a `professional_booking` row for one professional. RLS ("Clients
/// can manage their own bookings") scopes the insert to the caller as
/// `client_user_id`; the row starts at the default `requested` status and
/// the professional accepts/rejects it out of band (no in-app flow for the
/// professional side yet).
final class ProfessionalBookingControllerProvider
    extends $NotifierProvider<ProfessionalBookingController, bool> {
  /// Creates a `professional_booking` row for one professional. RLS ("Clients
  /// can manage their own bookings") scopes the insert to the caller as
  /// `client_user_id`; the row starts at the default `requested` status and
  /// the professional accepts/rejects it out of band (no in-app flow for the
  /// professional side yet).
  ProfessionalBookingControllerProvider._({
    required ProfessionalBookingControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'professionalBookingControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$professionalBookingControllerHash();

  @override
  String toString() {
    return r'professionalBookingControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ProfessionalBookingController create() => ProfessionalBookingController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProfessionalBookingControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$professionalBookingControllerHash() =>
    r'70a1bd46c5fab3704495c873f3b9f0b3a2743f0d';

/// Creates a `professional_booking` row for one professional. RLS ("Clients
/// can manage their own bookings") scopes the insert to the caller as
/// `client_user_id`; the row starts at the default `requested` status and
/// the professional accepts/rejects it out of band (no in-app flow for the
/// professional side yet).

final class ProfessionalBookingControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ProfessionalBookingController,
          bool,
          bool,
          bool,
          String
        > {
  ProfessionalBookingControllerFamily._()
    : super(
        retry: null,
        name: r'professionalBookingControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Creates a `professional_booking` row for one professional. RLS ("Clients
  /// can manage their own bookings") scopes the insert to the caller as
  /// `client_user_id`; the row starts at the default `requested` status and
  /// the professional accepts/rejects it out of band (no in-app flow for the
  /// professional side yet).

  ProfessionalBookingControllerProvider call(String professionalId) =>
      ProfessionalBookingControllerProvider._(
        argument: professionalId,
        from: this,
      );

  @override
  String toString() => r'professionalBookingControllerProvider';
}

/// Creates a `professional_booking` row for one professional. RLS ("Clients
/// can manage their own bookings") scopes the insert to the caller as
/// `client_user_id`; the row starts at the default `requested` status and
/// the professional accepts/rejects it out of band (no in-app flow for the
/// professional side yet).

abstract class _$ProfessionalBookingController extends $Notifier<bool> {
  late final _$args = ref.$arg as String;
  String get professionalId => _$args;

  bool build(String professionalId);
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
    element.handleCreate(ref, () => build(_$args));
  }
}
