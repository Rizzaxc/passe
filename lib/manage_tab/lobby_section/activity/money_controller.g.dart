// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'money_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LobbyMoneyController)
final lobbyMoneyControllerProvider = LobbyMoneyControllerFamily._();

final class LobbyMoneyControllerProvider
    extends
        $AsyncNotifierProvider<LobbyMoneyController, List<LobbyMoneyBalance>> {
  LobbyMoneyControllerProvider._({
    required LobbyMoneyControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'lobbyMoneyControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$lobbyMoneyControllerHash();

  @override
  String toString() {
    return r'lobbyMoneyControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  LobbyMoneyController create() => LobbyMoneyController();

  @override
  bool operator ==(Object other) {
    return other is LobbyMoneyControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$lobbyMoneyControllerHash() =>
    r'b55580d9d876528fb35a7bf86be75bdfbff6bf6c';

final class LobbyMoneyControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          LobbyMoneyController,
          AsyncValue<List<LobbyMoneyBalance>>,
          List<LobbyMoneyBalance>,
          FutureOr<List<LobbyMoneyBalance>>,
          String
        > {
  LobbyMoneyControllerFamily._()
    : super(
        retry: null,
        name: r'lobbyMoneyControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  LobbyMoneyControllerProvider call(String lobbyId) =>
      LobbyMoneyControllerProvider._(argument: lobbyId, from: this);

  @override
  String toString() => r'lobbyMoneyControllerProvider';
}

abstract class _$LobbyMoneyController
    extends $AsyncNotifier<List<LobbyMoneyBalance>> {
  late final _$args = ref.$arg as String;
  String get lobbyId => _$args;

  FutureOr<List<LobbyMoneyBalance>> build(String lobbyId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<LobbyMoneyBalance>>,
              List<LobbyMoneyBalance>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<LobbyMoneyBalance>>,
                List<LobbyMoneyBalance>
              >,
              AsyncValue<List<LobbyMoneyBalance>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
