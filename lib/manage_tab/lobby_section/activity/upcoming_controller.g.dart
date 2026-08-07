// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upcoming_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every current/future activity for a lobby, accounting for weekly
/// recurrence, sorted soonest-first.
///
/// Strategy:
///   1. Query for any candidate — either `start_time > now` (one-off) or
///      `recurrence_day_of_week IS NOT NULL` (recurring series whose
///      first occurrence may already be in the past).
///   2. Compute the next-start instant for each candidate (recurring
///      ones get advanced forward to the next matching weekday at the
///      same time-of-day), dropping any whose next occurrence can't be
///      resolved (a one-off already in the past).
///   3. Sort by that next-start instant, soonest first — a lobby can
///      legitimately have several activities live at once (an organic
///      session and a challenge match, two different weekly slots, …).

@ProviderFor(LobbyUpcomingActivitiesController)
final lobbyUpcomingActivitiesControllerProvider =
    LobbyUpcomingActivitiesControllerFamily._();

/// Every current/future activity for a lobby, accounting for weekly
/// recurrence, sorted soonest-first.
///
/// Strategy:
///   1. Query for any candidate — either `start_time > now` (one-off) or
///      `recurrence_day_of_week IS NOT NULL` (recurring series whose
///      first occurrence may already be in the past).
///   2. Compute the next-start instant for each candidate (recurring
///      ones get advanced forward to the next matching weekday at the
///      same time-of-day), dropping any whose next occurrence can't be
///      resolved (a one-off already in the past).
///   3. Sort by that next-start instant, soonest first — a lobby can
///      legitimately have several activities live at once (an organic
///      session and a challenge match, two different weekly slots, …).
final class LobbyUpcomingActivitiesControllerProvider
    extends
        $AsyncNotifierProvider<
          LobbyUpcomingActivitiesController,
          List<UpcomingActivity>
        > {
  /// Every current/future activity for a lobby, accounting for weekly
  /// recurrence, sorted soonest-first.
  ///
  /// Strategy:
  ///   1. Query for any candidate — either `start_time > now` (one-off) or
  ///      `recurrence_day_of_week IS NOT NULL` (recurring series whose
  ///      first occurrence may already be in the past).
  ///   2. Compute the next-start instant for each candidate (recurring
  ///      ones get advanced forward to the next matching weekday at the
  ///      same time-of-day), dropping any whose next occurrence can't be
  ///      resolved (a one-off already in the past).
  ///   3. Sort by that next-start instant, soonest first — a lobby can
  ///      legitimately have several activities live at once (an organic
  ///      session and a challenge match, two different weekly slots, …).
  LobbyUpcomingActivitiesControllerProvider._({
    required LobbyUpcomingActivitiesControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'lobbyUpcomingActivitiesControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() =>
      _$lobbyUpcomingActivitiesControllerHash();

  @override
  String toString() {
    return r'lobbyUpcomingActivitiesControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  LobbyUpcomingActivitiesController create() =>
      LobbyUpcomingActivitiesController();

  @override
  bool operator ==(Object other) {
    return other is LobbyUpcomingActivitiesControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$lobbyUpcomingActivitiesControllerHash() =>
    r'd1cf07b0446e12bbb353ab7d081ffa9e654990c1';

/// Every current/future activity for a lobby, accounting for weekly
/// recurrence, sorted soonest-first.
///
/// Strategy:
///   1. Query for any candidate — either `start_time > now` (one-off) or
///      `recurrence_day_of_week IS NOT NULL` (recurring series whose
///      first occurrence may already be in the past).
///   2. Compute the next-start instant for each candidate (recurring
///      ones get advanced forward to the next matching weekday at the
///      same time-of-day), dropping any whose next occurrence can't be
///      resolved (a one-off already in the past).
///   3. Sort by that next-start instant, soonest first — a lobby can
///      legitimately have several activities live at once (an organic
///      session and a challenge match, two different weekly slots, …).

final class LobbyUpcomingActivitiesControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          LobbyUpcomingActivitiesController,
          AsyncValue<List<UpcomingActivity>>,
          List<UpcomingActivity>,
          FutureOr<List<UpcomingActivity>>,
          String
        > {
  LobbyUpcomingActivitiesControllerFamily._()
    : super(
        retry: null,
        name: r'lobbyUpcomingActivitiesControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Every current/future activity for a lobby, accounting for weekly
  /// recurrence, sorted soonest-first.
  ///
  /// Strategy:
  ///   1. Query for any candidate — either `start_time > now` (one-off) or
  ///      `recurrence_day_of_week IS NOT NULL` (recurring series whose
  ///      first occurrence may already be in the past).
  ///   2. Compute the next-start instant for each candidate (recurring
  ///      ones get advanced forward to the next matching weekday at the
  ///      same time-of-day), dropping any whose next occurrence can't be
  ///      resolved (a one-off already in the past).
  ///   3. Sort by that next-start instant, soonest first — a lobby can
  ///      legitimately have several activities live at once (an organic
  ///      session and a challenge match, two different weekly slots, …).

  LobbyUpcomingActivitiesControllerProvider call(String lobbyId) =>
      LobbyUpcomingActivitiesControllerProvider._(
        argument: lobbyId,
        from: this,
      );

  @override
  String toString() => r'lobbyUpcomingActivitiesControllerProvider';
}

/// Every current/future activity for a lobby, accounting for weekly
/// recurrence, sorted soonest-first.
///
/// Strategy:
///   1. Query for any candidate — either `start_time > now` (one-off) or
///      `recurrence_day_of_week IS NOT NULL` (recurring series whose
///      first occurrence may already be in the past).
///   2. Compute the next-start instant for each candidate (recurring
///      ones get advanced forward to the next matching weekday at the
///      same time-of-day), dropping any whose next occurrence can't be
///      resolved (a one-off already in the past).
///   3. Sort by that next-start instant, soonest first — a lobby can
///      legitimately have several activities live at once (an organic
///      session and a challenge match, two different weekly slots, …).

abstract class _$LobbyUpcomingActivitiesController
    extends $AsyncNotifier<List<UpcomingActivity>> {
  late final _$args = ref.$arg as String;
  String get lobbyId => _$args;

  FutureOr<List<UpcomingActivity>> build(String lobbyId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<UpcomingActivity>>, List<UpcomingActivity>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<UpcomingActivity>>,
                List<UpcomingActivity>
              >,
              AsyncValue<List<UpcomingActivity>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
