// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// ignore_for_file: type=lint, type=warning

@ProviderFor(LobbyHistoryController)
final lobbyHistoryControllerProvider = LobbyHistoryControllerFamily._();

final class LobbyHistoryControllerProvider
    extends $AsyncNotifierProvider<LobbyHistoryController, List<Activity>> {
  LobbyHistoryControllerProvider._({
    required LobbyHistoryControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'lobbyHistoryControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$lobbyHistoryControllerHash();

  @override
  String toString() => r'lobbyHistoryControllerProvider($argument)';

  @$internal
  @override
  LobbyHistoryController create() => LobbyHistoryController();
}

String _$lobbyHistoryControllerHash() =>
    r'0000000000000000000000000000000000000000';

final class LobbyHistoryControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          LobbyHistoryController,
          AsyncValue<List<Activity>>,
          List<Activity>,
          List<Activity>,
          String
        > {
  LobbyHistoryControllerFamily._()
    : super(
        retry: null,
        name: r'lobbyHistoryControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  LobbyHistoryControllerProvider call(String lobbyId) =>
      LobbyHistoryControllerProvider._(argument: lobbyId, from: this);

  @override
  String toString() => r'lobbyHistoryControllerProvider';
}

abstract class _$LobbyHistoryController extends $AsyncNotifier<List<Activity>> {
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
