// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_history_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LobbyMatchHistoryController)
final lobbyMatchHistoryControllerProvider =
    LobbyMatchHistoryControllerFamily._();

final class LobbyMatchHistoryControllerProvider
    extends
        $AsyncNotifierProvider<
          LobbyMatchHistoryController,
          List<LobbyMatch>
        > {
  LobbyMatchHistoryControllerProvider._({
    required LobbyMatchHistoryControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'lobbyMatchHistoryControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$lobbyMatchHistoryControllerHash();

  @override
  String toString() {
    return r'lobbyMatchHistoryControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  LobbyMatchHistoryController create() => LobbyMatchHistoryController();

  @override
  bool operator ==(Object other) {
    return other is LobbyMatchHistoryControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$lobbyMatchHistoryControllerHash() =>
    r'match-history-hand-rolled';

final class LobbyMatchHistoryControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          LobbyMatchHistoryController,
          AsyncValue<List<LobbyMatch>>,
          List<LobbyMatch>,
          FutureOr<List<LobbyMatch>>,
          String
        > {
  LobbyMatchHistoryControllerFamily._()
    : super(
        retry: null,
        name: r'lobbyMatchHistoryControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  LobbyMatchHistoryControllerProvider call(String lobbyId) =>
      LobbyMatchHistoryControllerProvider._(argument: lobbyId, from: this);

  @override
  String toString() => r'lobbyMatchHistoryControllerProvider';
}

abstract class _$LobbyMatchHistoryController
    extends $AsyncNotifier<List<LobbyMatch>> {
  late final _$args = ref.$arg as String;
  String get lobbyId => _$args;

  FutureOr<List<LobbyMatch>> build(String lobbyId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<LobbyMatch>>, List<LobbyMatch>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<LobbyMatch>>, List<LobbyMatch>>,
              AsyncValue<List<LobbyMatch>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
