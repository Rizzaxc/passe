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

/// Soft availability check: existing *confirmed* bookings for this
/// professional overlapping the requested window
/// (`professional_booking_conflicts` RPC). Warns in the booking sheet UI —
/// the hard gate is `accept_professional_booking`'s atomic overlap check.

@ProviderFor(hasBookingConflict)
final hasBookingConflictProvider = HasBookingConflictFamily._();

/// Soft availability check: existing *confirmed* bookings for this
/// professional overlapping the requested window
/// (`professional_booking_conflicts` RPC). Warns in the booking sheet UI —
/// the hard gate is `accept_professional_booking`'s atomic overlap check.

final class HasBookingConflictProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Soft availability check: existing *confirmed* bookings for this
  /// professional overlapping the requested window
  /// (`professional_booking_conflicts` RPC). Warns in the booking sheet UI —
  /// the hard gate is `accept_professional_booking`'s atomic overlap check.
  HasBookingConflictProvider._({
    required HasBookingConflictFamily super.from,
    required (String, DateTime, DateTime) super.argument,
  }) : super(
         retry: null,
         name: r'hasBookingConflictProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$hasBookingConflictHash();

  @override
  String toString() {
    return r'hasBookingConflictProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as (String, DateTime, DateTime);
    return hasBookingConflict(ref, argument.$1, argument.$2, argument.$3);
  }

  @override
  bool operator ==(Object other) {
    return other is HasBookingConflictProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$hasBookingConflictHash() =>
    r'2a5ecc6b183cfc2959a1d401fdd928cf2a195a78';

/// Soft availability check: existing *confirmed* bookings for this
/// professional overlapping the requested window
/// (`professional_booking_conflicts` RPC). Warns in the booking sheet UI —
/// the hard gate is `accept_professional_booking`'s atomic overlap check.

final class HasBookingConflictFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<bool>,
          (String, DateTime, DateTime)
        > {
  HasBookingConflictFamily._()
    : super(
        retry: null,
        name: r'hasBookingConflictProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Soft availability check: existing *confirmed* bookings for this
  /// professional overlapping the requested window
  /// (`professional_booking_conflicts` RPC). Warns in the booking sheet UI —
  /// the hard gate is `accept_professional_booking`'s atomic overlap check.

  HasBookingConflictProvider call(
    String professionalId,
    DateTime start,
    DateTime end,
  ) => HasBookingConflictProvider._(
    argument: (professionalId, start, end),
    from: this,
  );

  @override
  String toString() => r'hasBookingConflictProvider';
}

/// Requests a booking through the server-side professional booking workflow.
/// The RPC derives ownership, price, package details, and the initial status;
/// the professional then accepts or rejects the request through the matching
/// action RPCs.

@ProviderFor(ProfessionalBookingController)
final professionalBookingControllerProvider =
    ProfessionalBookingControllerFamily._();

/// Requests a booking through the server-side professional booking workflow.
/// The RPC derives ownership, price, package details, and the initial status;
/// the professional then accepts or rejects the request through the matching
/// action RPCs.
final class ProfessionalBookingControllerProvider
    extends $NotifierProvider<ProfessionalBookingController, bool> {
  /// Requests a booking through the server-side professional booking workflow.
  /// The RPC derives ownership, price, package details, and the initial status;
  /// the professional then accepts or rejects the request through the matching
  /// action RPCs.
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
    r'11940e3ffb4c3146deef2ee54401f5b799b731d6';

/// Requests a booking through the server-side professional booking workflow.
/// The RPC derives ownership, price, package details, and the initial status;
/// the professional then accepts or rejects the request through the matching
/// action RPCs.

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

  /// Requests a booking through the server-side professional booking workflow.
  /// The RPC derives ownership, price, package details, and the initial status;
  /// the professional then accepts or rejects the request through the matching
  /// action RPCs.

  ProfessionalBookingControllerProvider call(String professionalId) =>
      ProfessionalBookingControllerProvider._(
        argument: professionalId,
        from: this,
      );

  @override
  String toString() => r'professionalBookingControllerProvider';
}

/// Requests a booking through the server-side professional booking workflow.
/// The RPC derives ownership, price, package details, and the initial status;
/// the professional then accepts or rejects the request through the matching
/// action RPCs.

abstract class _$ProfessionalBookingController extends $Notifier<bool> {
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
