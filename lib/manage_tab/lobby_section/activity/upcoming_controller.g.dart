// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upcoming_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Soonest upcoming activity for a lobby, accounting for weekly
/// recurrence.
///
/// Strategy:
///   1. Query for any candidate — either `start_time > now` (one-off) or
///      `recurrence_day_of_week IS NOT NULL` (recurring series whose
///      first occurrence may already be in the past).
///   2. Compute the next-start instant for each candidate (recurring
///      ones get advanced forward to the next matching weekday at the
///      same time-of-day).
///   3. Return the row with the earliest computed next-start.

@ProviderFor(LobbyUpcomingActivityController)
final lobbyUpcomingActivityControllerProvider =
    LobbyUpcomingActivityControllerFamily._();

/// Soonest upcoming activity for a lobby, accounting for weekly
/// recurrence.
///
/// Strategy:
///   1. Query for any candidate — either `start_time > now` (one-off) or
///      `recurrence_day_of_week IS NOT NULL` (recurring series whose
///      first occurrence may already be in the past).
///   2. Compute the next-start instant for each candidate (recurring
///      ones get advanced forward to the next matching weekday at the
///      same time-of-day).
///   3. Return the row with the earliest computed next-start.
final class LobbyUpcomingActivityControllerProvider
    extends
        $AsyncNotifierProvider<
          LobbyUpcomingActivityController,
          UpcomingActivity?
        > {
  /// Soonest upcoming activity for a lobby, accounting for weekly
  /// recurrence.
  ///
  /// Strategy:
  ///   1. Query for any candidate — either `start_time > now` (one-off) or
  ///      `recurrence_day_of_week IS NOT NULL` (recurring series whose
  ///      first occurrence may already be in the past).
  ///   2. Compute the next-start instant for each candidate (recurring
  ///      ones get advanced forward to the next matching weekday at the
  ///      same time-of-day).
  ///   3. Return the row with the earliest computed next-start.
  LobbyUpcomingActivityControllerProvider._({
    required LobbyUpcomingActivityControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'lobbyUpcomingActivityControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$lobbyUpcomingActivityControllerHash();

  @override
  String toString() {
    return r'lobbyUpcomingActivityControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  LobbyUpcomingActivityController create() => LobbyUpcomingActivityController();

  @override
  bool operator ==(Object other) {
    return other is LobbyUpcomingActivityControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$lobbyUpcomingActivityControllerHash() =>
    r'7ceaa96d0d831e19dbf49972f113252c07e7f8ce';

/// Soonest upcoming activity for a lobby, accounting for weekly
/// recurrence.
///
/// Strategy:
///   1. Query for any candidate — either `start_time > now` (one-off) or
///      `recurrence_day_of_week IS NOT NULL` (recurring series whose
///      first occurrence may already be in the past).
///   2. Compute the next-start instant for each candidate (recurring
///      ones get advanced forward to the next matching weekday at the
///      same time-of-day).
///   3. Return the row with the earliest computed next-start.

final class LobbyUpcomingActivityControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          LobbyUpcomingActivityController,
          AsyncValue<UpcomingActivity?>,
          UpcomingActivity?,
          FutureOr<UpcomingActivity?>,
          String
        > {
  LobbyUpcomingActivityControllerFamily._()
    : super(
        retry: null,
        name: r'lobbyUpcomingActivityControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Soonest upcoming activity for a lobby, accounting for weekly
  /// recurrence.
  ///
  /// Strategy:
  ///   1. Query for any candidate — either `start_time > now` (one-off) or
  ///      `recurrence_day_of_week IS NOT NULL` (recurring series whose
  ///      first occurrence may already be in the past).
  ///   2. Compute the next-start instant for each candidate (recurring
  ///      ones get advanced forward to the next matching weekday at the
  ///      same time-of-day).
  ///   3. Return the row with the earliest computed next-start.

  LobbyUpcomingActivityControllerProvider call(String lobbyId) =>
      LobbyUpcomingActivityControllerProvider._(argument: lobbyId, from: this);

  @override
  String toString() => r'lobbyUpcomingActivityControllerProvider';
}

/// Soonest upcoming activity for a lobby, accounting for weekly
/// recurrence.
///
/// Strategy:
///   1. Query for any candidate — either `start_time > now` (one-off) or
///      `recurrence_day_of_week IS NOT NULL` (recurring series whose
///      first occurrence may already be in the past).
///   2. Compute the next-start instant for each candidate (recurring
///      ones get advanced forward to the next matching weekday at the
///      same time-of-day).
///   3. Return the row with the earliest computed next-start.

abstract class _$LobbyUpcomingActivityController
    extends $AsyncNotifier<UpcomingActivity?> {
  late final _$args = ref.$arg as String;
  String get lobbyId => _$args;

  FutureOr<UpcomingActivity?> build(String lobbyId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<UpcomingActivity?>, UpcomingActivity?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<UpcomingActivity?>, UpcomingActivity?>,
              AsyncValue<UpcomingActivity?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
