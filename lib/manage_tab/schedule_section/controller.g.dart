// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The current user's activities (lobby sessions + coach bookings) for the
/// all sports, keyed by local date. Backed by the `my_schedule_data` RPC —
/// every row, including each occurrence of a recurring series, is its own
/// dated activity, so no client-side expansion is needed.

@ProviderFor(ScheduleEvents)
final scheduleEventsProvider = ScheduleEventsProvider._();

/// The current user's activities (lobby sessions + coach bookings) for the
/// all sports, keyed by local date. Backed by the `my_schedule_data` RPC —
/// every row, including each occurrence of a recurring series, is its own
/// dated activity, so no client-side expansion is needed.
final class ScheduleEventsProvider
    extends
        $AsyncNotifierProvider<
          ScheduleEvents,
          Map<DateTime, List<ScheduleEvent>>
        > {
  /// The current user's activities (lobby sessions + coach bookings) for the
  /// all sports, keyed by local date. Backed by the `my_schedule_data` RPC —
  /// every row, including each occurrence of a recurring series, is its own
  /// dated activity, so no client-side expansion is needed.
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

String _$scheduleEventsHash() => r'cf71048f6f249fc9e81594c744fc4b07ac28bf71';

/// The current user's activities (lobby sessions + coach bookings) for the
/// all sports, keyed by local date. Backed by the `my_schedule_data` RPC —
/// every row, including each occurrence of a recurring series, is its own
/// dated activity, so no client-side expansion is needed.

abstract class _$ScheduleEvents
    extends $AsyncNotifier<Map<DateTime, List<ScheduleEvent>>> {
  FutureOr<Map<DateTime, List<ScheduleEvent>>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
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
    return element.handleCreate(ref, build);
  }
}
