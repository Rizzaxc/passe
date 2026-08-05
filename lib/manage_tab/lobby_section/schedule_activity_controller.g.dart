// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_activity_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ScheduleActivityController)
final scheduleActivityControllerProvider = ScheduleActivityControllerFamily._();

final class ScheduleActivityControllerProvider
    extends $NotifierProvider<ScheduleActivityController, bool> {
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
    r'021551cd96093e0ca5f36ac2433b764d88bc896e';

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

  ScheduleActivityControllerProvider call(String lobbyId) =>
      ScheduleActivityControllerProvider._(argument: lobbyId, from: this);

  @override
  String toString() => r'scheduleActivityControllerProvider';
}

abstract class _$ScheduleActivityController extends $Notifier<bool> {
  late final _$args = ref.$arg as String;
  String get lobbyId => _$args;

  bool build(String lobbyId);
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
