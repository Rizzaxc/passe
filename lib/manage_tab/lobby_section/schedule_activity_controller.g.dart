// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_activity_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Captain-side "schedule a play session" mutation for a lobby.
///
/// TODO(activity-schedule): currently a no-op so the captain-side
/// CTA flow completes without persisting. Wire to a Supabase insert
/// into `activity` (with all the prepayment / confirmation / recurrence
/// columns added by `schema/activity_scheduling.sql`) once the captain-
/// only RLS policy lands.

@ProviderFor(ScheduleActivityController)
final scheduleActivityControllerProvider = ScheduleActivityControllerFamily._();

/// Captain-side "schedule a play session" mutation for a lobby.
///
/// TODO(activity-schedule): currently a no-op so the captain-side
/// CTA flow completes without persisting. Wire to a Supabase insert
/// into `activity` (with all the prepayment / confirmation / recurrence
/// columns added by `schema/activity_scheduling.sql`) once the captain-
/// only RLS policy lands.
final class ScheduleActivityControllerProvider
    extends $NotifierProvider<ScheduleActivityController, bool> {
  /// Captain-side "schedule a play session" mutation for a lobby.
  ///
  /// TODO(activity-schedule): currently a no-op so the captain-side
  /// CTA flow completes without persisting. Wire to a Supabase insert
  /// into `activity` (with all the prepayment / confirmation / recurrence
  /// columns added by `schema/activity_scheduling.sql`) once the captain-
  /// only RLS policy lands.
  ScheduleActivityControllerProvider._({
    required ScheduleActivityControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'scheduleActivityControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$scheduleActivityControllerHash();

  @override
  String toString() {
    return r'scheduleActivityControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ScheduleActivityController create() => ScheduleActivityController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ScheduleActivityControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$scheduleActivityControllerHash() =>
    r'1a98c057f1e4eda39bef5bb036cd8098c885e79c';

/// Captain-side "schedule a play session" mutation for a lobby.
///
/// TODO(activity-schedule): currently a no-op so the captain-side
/// CTA flow completes without persisting. Wire to a Supabase insert
/// into `activity` (with all the prepayment / confirmation / recurrence
/// columns added by `schema/activity_scheduling.sql`) once the captain-
/// only RLS policy lands.

final class ScheduleActivityControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ScheduleActivityController,
          bool,
          bool,
          bool,
          String
        > {
  ScheduleActivityControllerFamily._()
    : super(
        retry: null,
        name: r'scheduleActivityControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Captain-side "schedule a play session" mutation for a lobby.
  ///
  /// TODO(activity-schedule): currently a no-op so the captain-side
  /// CTA flow completes without persisting. Wire to a Supabase insert
  /// into `activity` (with all the prepayment / confirmation / recurrence
  /// columns added by `schema/activity_scheduling.sql`) once the captain-
  /// only RLS policy lands.

  ScheduleActivityControllerProvider call(String lobbyId) =>
      ScheduleActivityControllerProvider._(argument: lobbyId, from: this);

  @override
  String toString() => r'scheduleActivityControllerProvider';
}

/// Captain-side "schedule a play session" mutation for a lobby.
///
/// TODO(activity-schedule): currently a no-op so the captain-side
/// CTA flow completes without persisting. Wire to a Supabase insert
/// into `activity` (with all the prepayment / confirmation / recurrence
/// columns added by `schema/activity_scheduling.sql`) once the captain-
/// only RLS policy lands.

abstract class _$ScheduleActivityController extends $Notifier<bool> {
  late final _$args = ref.$arg as String;
  String get lobbyId => _$args;

  bool build(String lobbyId);
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
