// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pro_bookings_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Pending requests for the linked professional — `status = requested`.

@ProviderFor(proPendingRequests)
final proPendingRequestsProvider = ProPendingRequestsFamily._();

/// Pending requests for the linked professional — `status = requested`.

final class ProPendingRequestsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProBookingItem>>,
          List<ProBookingItem>,
          FutureOr<List<ProBookingItem>>
        >
    with
        $FutureModifier<List<ProBookingItem>>,
        $FutureProvider<List<ProBookingItem>> {
  /// Pending requests for the linked professional — `status = requested`.
  ProPendingRequestsProvider._({
    required ProPendingRequestsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'proPendingRequestsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$proPendingRequestsHash();

  @override
  String toString() {
    return r'proPendingRequestsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ProBookingItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ProBookingItem>> create(Ref ref) {
    final argument = this.argument as String;
    return proPendingRequests(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ProPendingRequestsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$proPendingRequestsHash() =>
    r'504f2e6621195243be4cb3e3ac784fa4adbf4e85';

/// Pending requests for the linked professional — `status = requested`.

final class ProPendingRequestsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<ProBookingItem>>, String> {
  ProPendingRequestsFamily._()
    : super(
        retry: null,
        name: r'proPendingRequestsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Pending requests for the linked professional — `status = requested`.

  ProPendingRequestsProvider call(String professionalId) =>
      ProPendingRequestsProvider._(argument: professionalId, from: this);

  @override
  String toString() => r'proPendingRequestsProvider';
}

/// Confirmed upcoming sessions — the pro-mode "schedule" surface.

@ProviderFor(proUpcomingBookings)
final proUpcomingBookingsProvider = ProUpcomingBookingsFamily._();

/// Confirmed upcoming sessions — the pro-mode "schedule" surface.

final class ProUpcomingBookingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProBookingItem>>,
          List<ProBookingItem>,
          FutureOr<List<ProBookingItem>>
        >
    with
        $FutureModifier<List<ProBookingItem>>,
        $FutureProvider<List<ProBookingItem>> {
  /// Confirmed upcoming sessions — the pro-mode "schedule" surface.
  ProUpcomingBookingsProvider._({
    required ProUpcomingBookingsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'proUpcomingBookingsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$proUpcomingBookingsHash();

  @override
  String toString() {
    return r'proUpcomingBookingsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ProBookingItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ProBookingItem>> create(Ref ref) {
    final argument = this.argument as String;
    return proUpcomingBookings(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ProUpcomingBookingsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$proUpcomingBookingsHash() =>
    r'4047472969d54c4ba0b87e0deb290313a3a32df3';

/// Confirmed upcoming sessions — the pro-mode "schedule" surface.

final class ProUpcomingBookingsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<ProBookingItem>>, String> {
  ProUpcomingBookingsFamily._()
    : super(
        retry: null,
        name: r'proUpcomingBookingsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Confirmed upcoming sessions — the pro-mode "schedule" surface.

  ProUpcomingBookingsProvider call(String professionalId) =>
      ProUpcomingBookingsProvider._(argument: professionalId, from: this);

  @override
  String toString() => r'proUpcomingBookingsProvider';
}

/// Past bookings — completed, rejected, or cancelled, most recent first.

@ProviderFor(proBookingHistory)
final proBookingHistoryProvider = ProBookingHistoryFamily._();

/// Past bookings — completed, rejected, or cancelled, most recent first.

final class ProBookingHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProBookingItem>>,
          List<ProBookingItem>,
          FutureOr<List<ProBookingItem>>
        >
    with
        $FutureModifier<List<ProBookingItem>>,
        $FutureProvider<List<ProBookingItem>> {
  /// Past bookings — completed, rejected, or cancelled, most recent first.
  ProBookingHistoryProvider._({
    required ProBookingHistoryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'proBookingHistoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$proBookingHistoryHash();

  @override
  String toString() {
    return r'proBookingHistoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ProBookingItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ProBookingItem>> create(Ref ref) {
    final argument = this.argument as String;
    return proBookingHistory(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ProBookingHistoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$proBookingHistoryHash() => r'6d6e2aa8d9849b7822208d49736f159ea0e62170';

/// Past bookings — completed, rejected, or cancelled, most recent first.

final class ProBookingHistoryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<ProBookingItem>>, String> {
  ProBookingHistoryFamily._()
    : super(
        retry: null,
        name: r'proBookingHistoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Past bookings — completed, rejected, or cancelled, most recent first.

  ProBookingHistoryProvider call(String professionalId) =>
      ProBookingHistoryProvider._(argument: professionalId, from: this);

  @override
  String toString() => r'proBookingHistoryProvider';
}

/// Records the result of a refereed challenge match.
///
/// Only the booked referee can call this (`record_challenge_match` checks the
/// caller against the booking's professional), and only after the match has
/// ended. The insert it performs also flips the booking to `completed` through
/// the existing `lobby_match_complete_referee_booking` trigger and moves both
/// lobbies' Elo — which is why the entry is final and has no edit affordance.

@ProviderFor(RecordChallengeResultController)
final recordChallengeResultControllerProvider =
    RecordChallengeResultControllerFamily._();

/// Records the result of a refereed challenge match.
///
/// Only the booked referee can call this (`record_challenge_match` checks the
/// caller against the booking's professional), and only after the match has
/// ended. The insert it performs also flips the booking to `completed` through
/// the existing `lobby_match_complete_referee_booking` trigger and moves both
/// lobbies' Elo — which is why the entry is final and has no edit affordance.
final class RecordChallengeResultControllerProvider
    extends $NotifierProvider<RecordChallengeResultController, bool> {
  /// Records the result of a refereed challenge match.
  ///
  /// Only the booked referee can call this (`record_challenge_match` checks the
  /// caller against the booking's professional), and only after the match has
  /// ended. The insert it performs also flips the booking to `completed` through
  /// the existing `lobby_match_complete_referee_booking` trigger and moves both
  /// lobbies' Elo — which is why the entry is final and has no edit affordance.
  RecordChallengeResultControllerProvider._({
    required RecordChallengeResultControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'recordChallengeResultControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recordChallengeResultControllerHash();

  @override
  String toString() {
    return r'recordChallengeResultControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  RecordChallengeResultController create() => RecordChallengeResultController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RecordChallengeResultControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recordChallengeResultControllerHash() =>
    r'e280cc095830388b0ca1ff3ffa7a20d173d2879d';

/// Records the result of a refereed challenge match.
///
/// Only the booked referee can call this (`record_challenge_match` checks the
/// caller against the booking's professional), and only after the match has
/// ended. The insert it performs also flips the booking to `completed` through
/// the existing `lobby_match_complete_referee_booking` trigger and moves both
/// lobbies' Elo — which is why the entry is final and has no edit affordance.

final class RecordChallengeResultControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          RecordChallengeResultController,
          bool,
          bool,
          bool,
          String
        > {
  RecordChallengeResultControllerFamily._()
    : super(
        retry: null,
        name: r'recordChallengeResultControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Records the result of a refereed challenge match.
  ///
  /// Only the booked referee can call this (`record_challenge_match` checks the
  /// caller against the booking's professional), and only after the match has
  /// ended. The insert it performs also flips the booking to `completed` through
  /// the existing `lobby_match_complete_referee_booking` trigger and moves both
  /// lobbies' Elo — which is why the entry is final and has no edit affordance.

  RecordChallengeResultControllerProvider call(String professionalId) =>
      RecordChallengeResultControllerProvider._(
        argument: professionalId,
        from: this,
      );

  @override
  String toString() => r'recordChallengeResultControllerProvider';
}

/// Records the result of a refereed challenge match.
///
/// Only the booked referee can call this (`record_challenge_match` checks the
/// caller against the booking's professional), and only after the match has
/// ended. The insert it performs also flips the booking to `completed` through
/// the existing `lobby_match_complete_referee_booking` trigger and moves both
/// lobbies' Elo — which is why the entry is final and has no edit affordance.

abstract class _$RecordChallengeResultController extends $Notifier<bool> {
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

/// Accept/reject/mark-complete actions for the professional side, backed by
/// the validated `accept_professional_booking`/`reject_professional_booking`
/// RPCs (accept needs an atomic overlap check a bare UPDATE can't express).

@ProviderFor(ProBookingActionController)
final proBookingActionControllerProvider = ProBookingActionControllerFamily._();

/// Accept/reject/mark-complete actions for the professional side, backed by
/// the validated `accept_professional_booking`/`reject_professional_booking`
/// RPCs (accept needs an atomic overlap check a bare UPDATE can't express).
final class ProBookingActionControllerProvider
    extends $NotifierProvider<ProBookingActionController, bool> {
  /// Accept/reject/mark-complete actions for the professional side, backed by
  /// the validated `accept_professional_booking`/`reject_professional_booking`
  /// RPCs (accept needs an atomic overlap check a bare UPDATE can't express).
  ProBookingActionControllerProvider._({
    required ProBookingActionControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'proBookingActionControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$proBookingActionControllerHash();

  @override
  String toString() {
    return r'proBookingActionControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ProBookingActionController create() => ProBookingActionController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProBookingActionControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$proBookingActionControllerHash() =>
    r'73d72dbb120bbc10ecb75f5768ce1e26533c7f94';

/// Accept/reject/mark-complete actions for the professional side, backed by
/// the validated `accept_professional_booking`/`reject_professional_booking`
/// RPCs (accept needs an atomic overlap check a bare UPDATE can't express).

final class ProBookingActionControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ProBookingActionController,
          bool,
          bool,
          bool,
          String
        > {
  ProBookingActionControllerFamily._()
    : super(
        retry: null,
        name: r'proBookingActionControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Accept/reject/mark-complete actions for the professional side, backed by
  /// the validated `accept_professional_booking`/`reject_professional_booking`
  /// RPCs (accept needs an atomic overlap check a bare UPDATE can't express).

  ProBookingActionControllerProvider call(String professionalId) =>
      ProBookingActionControllerProvider._(
        argument: professionalId,
        from: this,
      );

  @override
  String toString() => r'proBookingActionControllerProvider';
}

/// Accept/reject/mark-complete actions for the professional side, backed by
/// the validated `accept_professional_booking`/`reject_professional_booking`
/// RPCs (accept needs an atomic overlap check a bare UPDATE can't express).

abstract class _$ProBookingActionController extends $Notifier<bool> {
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
