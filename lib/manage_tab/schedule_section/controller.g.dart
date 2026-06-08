// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The current user's activities (lobby sessions + coach bookings) for the
/// context sport, keyed by local date. Backed by the `my_schedule_data` RPC;
/// recurring rows are expanded across the visible window.

@ProviderFor(ScheduleEvents)
final scheduleEventsProvider = ScheduleEventsProvider._();

/// The current user's activities (lobby sessions + coach bookings) for the
/// context sport, keyed by local date. Backed by the `my_schedule_data` RPC;
/// recurring rows are expanded across the visible window.
final class ScheduleEventsProvider
    extends
        $AsyncNotifierProvider<
          ScheduleEvents,
          Map<DateTime, List<ScheduleEvent>>
        > {
  /// The current user's activities (lobby sessions + coach bookings) for the
  /// context sport, keyed by local date. Backed by the `my_schedule_data` RPC;
  /// recurring rows are expanded across the visible window.
  ScheduleEventsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scheduleEventsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scheduleEventsHash();

  @$internal
  @override
  ScheduleEvents create() => ScheduleEvents();
}

String _$scheduleEventsHash() => r'e0fc0c4bb45487b76e872885fc9867ca3a0cff92';

/// The current user's activities (lobby sessions + coach bookings) for the
/// context sport, keyed by local date. Backed by the `my_schedule_data` RPC;
/// recurring rows are expanded across the visible window.

abstract class _$ScheduleEvents
    extends $AsyncNotifier<Map<DateTime, List<ScheduleEvent>>> {
  FutureOr<Map<DateTime, List<ScheduleEvent>>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<Map<DateTime, List<ScheduleEvent>>>,
              Map<DateTime, List<ScheduleEvent>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<Map<DateTime, List<ScheduleEvent>>>,
                Map<DateTime, List<ScheduleEvent>>
              >,
              AsyncValue<Map<DateTime, List<ScheduleEvent>>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
