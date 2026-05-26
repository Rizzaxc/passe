// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upcoming_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LobbyUpcomingActivityController)
final lobbyUpcomingActivityControllerProvider =
    LobbyUpcomingActivityControllerFamily._();

final class LobbyUpcomingActivityControllerProvider
    extends $AsyncNotifierProvider<LobbyUpcomingActivityController, Activity?> {
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
    r'upcoming-activity-hand-rolled';

final class LobbyUpcomingActivityControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          LobbyUpcomingActivityController,
          AsyncValue<Activity?>,
          Activity?,
          FutureOr<Activity?>,
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

  LobbyUpcomingActivityControllerProvider call(String lobbyId) =>
      LobbyUpcomingActivityControllerProvider._(argument: lobbyId, from: this);

  @override
  String toString() => r'lobbyUpcomingActivityControllerProvider';
}

abstract class _$LobbyUpcomingActivityController
    extends $AsyncNotifier<Activity?> {
  late final _$args = ref.$arg as String;
  String get lobbyId => _$args;

  FutureOr<Activity?> build(String lobbyId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Activity?>, Activity?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Activity?>, Activity?>,
              AsyncValue<Activity?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
