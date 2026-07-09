// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
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
  String toString() {
    return r'lobbyHistoryControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  LobbyHistoryController create() => LobbyHistoryController();

  @override
  bool operator ==(Object other) {
    return other is LobbyHistoryControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$lobbyHistoryControllerHash() =>
    r'bcd7d94b70acd5f262d8934953fbf8604a73f1a3';

final class LobbyHistoryControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          LobbyHistoryController,
          AsyncValue<List<Activity>>,
          List<Activity>,
          FutureOr<List<Activity>>,
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
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Activity>>, List<Activity>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Activity>>, List<Activity>>,
              AsyncValue<List<Activity>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
