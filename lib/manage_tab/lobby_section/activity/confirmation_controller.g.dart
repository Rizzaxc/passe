// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'confirmation_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Activity-level + member-level confirmation for one activity row.
///
/// The notifier reads through the `activity_confirmation_status` RPC
/// (single round-trip) and writes by inserting / deleting the caller's
/// row in `activity_confirmation`. After every write it re-reads — the
/// status flip from "X of Y confirmed" → "official" needs to land in
/// the same render frame, so we don't bother with optimistic local
/// math.

@ProviderFor(ActivityConfirmationController)
final activityConfirmationControllerProvider =
    ActivityConfirmationControllerFamily._();

/// Activity-level + member-level confirmation for one activity row.
///
/// The notifier reads through the `activity_confirmation_status` RPC
/// (single round-trip) and writes by inserting / deleting the caller's
/// row in `activity_confirmation`. After every write it re-reads — the
/// status flip from "X of Y confirmed" → "official" needs to land in
/// the same render frame, so we don't bother with optimistic local
/// math.
final class ActivityConfirmationControllerProvider
    extends
        $AsyncNotifierProvider<
          ActivityConfirmationController,
          ActivityConfirmationStatus
        > {
  /// Activity-level + member-level confirmation for one activity row.
  ///
  /// The notifier reads through the `activity_confirmation_status` RPC
  /// (single round-trip) and writes by inserting / deleting the caller's
  /// row in `activity_confirmation`. After every write it re-reads — the
  /// status flip from "X of Y confirmed" → "official" needs to land in
  /// the same render frame, so we don't bother with optimistic local
  /// math.
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
    r'1ab61d2bf6b45bd77ebf45b3c75f95b218b6b70a';

/// Activity-level + member-level confirmation for one activity row.
///
/// The notifier reads through the `activity_confirmation_status` RPC
/// (single round-trip) and writes by inserting / deleting the caller's
/// row in `activity_confirmation`. After every write it re-reads — the
/// status flip from "X of Y confirmed" → "official" needs to land in
/// the same render frame, so we don't bother with optimistic local
/// math.

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

  /// Activity-level + member-level confirmation for one activity row.
  ///
  /// The notifier reads through the `activity_confirmation_status` RPC
  /// (single round-trip) and writes by inserting / deleting the caller's
  /// row in `activity_confirmation`. After every write it re-reads — the
  /// status flip from "X of Y confirmed" → "official" needs to land in
  /// the same render frame, so we don't bother with optimistic local
  /// math.

  ActivityConfirmationControllerProvider call(String activityId) =>
      ActivityConfirmationControllerProvider._(
        argument: activityId,
        from: this,
      );

  @override
  String toString() => r'activityConfirmationControllerProvider';
}

/// Activity-level + member-level confirmation for one activity row.
///
/// The notifier reads through the `activity_confirmation_status` RPC
/// (single round-trip) and writes by inserting / deleting the caller's
/// row in `activity_confirmation`. After every write it re-reads — the
/// status flip from "X of Y confirmed" → "official" needs to land in
/// the same render frame, so we don't bother with optimistic local
/// math.

abstract class _$ActivityConfirmationController
    extends $AsyncNotifier<ActivityConfirmationStatus> {
  late final _$args = ref.$arg as String;
  String get activityId => _$args;

  FutureOr<ActivityConfirmationStatus> build(String activityId);
  @$mustCallSuper
  @override
  void runBuild() {
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
    element.handleCreate(ref, () => build(_$args));
  }
}
