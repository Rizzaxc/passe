// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'confirmation_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Activity-level + member-level RSVP for one activity row.
///
/// The notifier reads through the `activity_confirmation_status` RPC
/// (single round-trip) and writes by upserting the caller's row in
/// `activity_confirmation` with the chosen [Attendance]. Writes flip the
/// local state **optimistically** (so the RSVP control reacts in the same
/// frame), then reconcile against the server re-read; on failure the
/// previous snapshot is restored.

@ProviderFor(ActivityConfirmationController)
final activityConfirmationControllerProvider =
    ActivityConfirmationControllerFamily._();

/// Activity-level + member-level RSVP for one activity row.
///
/// The notifier reads through the `activity_confirmation_status` RPC
/// (single round-trip) and writes by upserting the caller's row in
/// `activity_confirmation` with the chosen [Attendance]. Writes flip the
/// local state **optimistically** (so the RSVP control reacts in the same
/// frame), then reconcile against the server re-read; on failure the
/// previous snapshot is restored.
final class ActivityConfirmationControllerProvider
    extends
        $AsyncNotifierProvider<
          ActivityConfirmationController,
          ActivityConfirmationStatus
        > {
  /// Activity-level + member-level RSVP for one activity row.
  ///
  /// The notifier reads through the `activity_confirmation_status` RPC
  /// (single round-trip) and writes by upserting the caller's row in
  /// `activity_confirmation` with the chosen [Attendance]. Writes flip the
  /// local state **optimistically** (so the RSVP control reacts in the same
  /// frame), then reconcile against the server re-read; on failure the
  /// previous snapshot is restored.
  ActivityConfirmationControllerProvider._({
    required ActivityConfirmationControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'activityConfirmationControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$activityConfirmationControllerHash();

  @override
  String toString() {
    return r'activityConfirmationControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ActivityConfirmationController create() => ActivityConfirmationController();

  @override
  bool operator ==(Object other) {
    return other is ActivityConfirmationControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$activityConfirmationControllerHash() =>
    r'e9bc7ca1dcfa31ed4484a71350a23e54c00881dd';

/// Activity-level + member-level RSVP for one activity row.
///
/// The notifier reads through the `activity_confirmation_status` RPC
/// (single round-trip) and writes by upserting the caller's row in
/// `activity_confirmation` with the chosen [Attendance]. Writes flip the
/// local state **optimistically** (so the RSVP control reacts in the same
/// frame), then reconcile against the server re-read; on failure the
/// previous snapshot is restored.

final class ActivityConfirmationControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ActivityConfirmationController,
          AsyncValue<ActivityConfirmationStatus>,
          ActivityConfirmationStatus,
          FutureOr<ActivityConfirmationStatus>,
          String
        > {
  ActivityConfirmationControllerFamily._()
    : super(
        retry: null,
        name: r'activityConfirmationControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Activity-level + member-level RSVP for one activity row.
  ///
  /// The notifier reads through the `activity_confirmation_status` RPC
  /// (single round-trip) and writes by upserting the caller's row in
  /// `activity_confirmation` with the chosen [Attendance]. Writes flip the
  /// local state **optimistically** (so the RSVP control reacts in the same
  /// frame), then reconcile against the server re-read; on failure the
  /// previous snapshot is restored.

  ActivityConfirmationControllerProvider call(String activityId) =>
      ActivityConfirmationControllerProvider._(
        argument: activityId,
        from: this,
      );

  @override
  String toString() => r'activityConfirmationControllerProvider';
}

/// Activity-level + member-level RSVP for one activity row.
///
/// The notifier reads through the `activity_confirmation_status` RPC
/// (single round-trip) and writes by upserting the caller's row in
/// `activity_confirmation` with the chosen [Attendance]. Writes flip the
/// local state **optimistically** (so the RSVP control reacts in the same
/// frame), then reconcile against the server re-read; on failure the
/// previous snapshot is restored.

abstract class _$ActivityConfirmationController
    extends $AsyncNotifier<ActivityConfirmationStatus> {
  late final _$args = ref.$arg as String;
  String get activityId => _$args;

  FutureOr<ActivityConfirmationStatus> build(String activityId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<ActivityConfirmationStatus>,
              ActivityConfirmationStatus
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<ActivityConfirmationStatus>,
                ActivityConfirmationStatus
              >,
              AsyncValue<ActivityConfirmationStatus>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// Small sample of who's going / maybe, for the hero's avatar strip.
/// `activity_confirmation_status` only returns aggregate counts, so this
/// is a separate lightweight query rather than bloating that RPC.

@ProviderFor(activityAttendees)
final activityAttendeesProvider = ActivityAttendeesFamily._();

/// Small sample of who's going / maybe, for the hero's avatar strip.
/// `activity_confirmation_status` only returns aggregate counts, so this
/// is a separate lightweight query rather than bloating that RPC.

final class ActivityAttendeesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Attendee>>,
          List<Attendee>,
          FutureOr<List<Attendee>>
        >
    with $FutureModifier<List<Attendee>>, $FutureProvider<List<Attendee>> {
  /// Small sample of who's going / maybe, for the hero's avatar strip.
  /// `activity_confirmation_status` only returns aggregate counts, so this
  /// is a separate lightweight query rather than bloating that RPC.
  ActivityAttendeesProvider._({
    required ActivityAttendeesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'activityAttendeesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$activityAttendeesHash();

  @override
  String toString() {
    return r'activityAttendeesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Attendee>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Attendee>> create(Ref ref) {
    final argument = this.argument as String;
    return activityAttendees(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ActivityAttendeesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$activityAttendeesHash() => r'ca2784ce25173b618a7d0677709bddec5397a06a';

/// Small sample of who's going / maybe, for the hero's avatar strip.
/// `activity_confirmation_status` only returns aggregate counts, so this
/// is a separate lightweight query rather than bloating that RPC.

final class ActivityAttendeesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Attendee>>, String> {
  ActivityAttendeesFamily._()
    : super(
        retry: null,
        name: r'activityAttendeesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Small sample of who's going / maybe, for the hero's avatar strip.
  /// `activity_confirmation_status` only returns aggregate counts, so this
  /// is a separate lightweight query rather than bloating that RPC.

  ActivityAttendeesProvider call(String activityId) =>
      ActivityAttendeesProvider._(argument: activityId, from: this);

  @override
  String toString() => r'activityAttendeesProvider';
}
