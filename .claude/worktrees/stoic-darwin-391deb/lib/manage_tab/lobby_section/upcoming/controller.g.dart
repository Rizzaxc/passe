// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// ignore_for_file: type=lint, type=warning

@ProviderFor(LobbyUpcomingController)
final lobbyUpcomingControllerProvider = LobbyUpcomingControllerFamily._();

final class LobbyUpcomingControllerProvider
    extends $AsyncNotifierProvider<LobbyUpcomingController, List<Activity>> {
  LobbyUpcomingControllerProvider._({
    required LobbyUpcomingControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'lobbyUpcomingControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$lobbyUpcomingControllerHash();

  @override
  String toString() => r'lobbyUpcomingControllerProvider($argument)';

  @$internal
  @override
  LobbyUpcomingController create() => LobbyUpcomingController();
}

String _$lobbyUpcomingControllerHash() =>
    r'0000000000000000000000000000000000000000';

final class LobbyUpcomingControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          LobbyUpcomingController,
          AsyncValue<List<Activity>>,
          List<Activity>,
          List<Activity>,
          String
        > {
  LobbyUpcomingControllerFamily._()
    : super(
        retry: null,
        name: r'lobbyUpcomingControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  LobbyUpcomingControllerProvider call(String lobbyId) =>
      LobbyUpcomingControllerProvider._(argument: lobbyId, from: this);

  @override
  String toString() => r'lobbyUpcomingControllerProvider';
}

abstract class _$LobbyUpcomingController extends $AsyncNotifier<List<Activity>> {
  late final _$args = ref.$arg as String;
  String get lobbyId => _$args;

  FutureOr<List<Activity>> build(String lobbyId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Activity>>, List<Activity>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<Activity>>, List<Activity>>,
        AsyncValue<List<Activity>>,
        Object?,
        Object?>;
    element.handleCreate(ref, () => build(_$args));
  }
}
