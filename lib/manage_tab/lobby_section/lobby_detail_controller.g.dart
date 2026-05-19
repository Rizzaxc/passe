// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lobby_detail_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LobbyDetailController)
final lobbyDetailControllerProvider = LobbyDetailControllerFamily._();

final class LobbyDetailControllerProvider
    extends $AsyncNotifierProvider<LobbyDetailController, LobbyDetailInfo> {
  LobbyDetailControllerProvider._({
    required LobbyDetailControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'lobbyDetailControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$lobbyDetailControllerHash();

  @override
  String toString() {
    return r'lobbyDetailControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  LobbyDetailController create() => LobbyDetailController();

  @override
  bool operator ==(Object other) {
    return other is LobbyDetailControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$lobbyDetailControllerHash() =>
    r'e641448bffd4fa332a60aa0fe72259ab64962240';

final class LobbyDetailControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          LobbyDetailController,
          AsyncValue<LobbyDetailInfo>,
          LobbyDetailInfo,
          FutureOr<LobbyDetailInfo>,
          String
        > {
  LobbyDetailControllerFamily._()
    : super(
        retry: null,
        name: r'lobbyDetailControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  LobbyDetailControllerProvider call(String lobbyId) =>
      LobbyDetailControllerProvider._(argument: lobbyId, from: this);

  @override
  String toString() => r'lobbyDetailControllerProvider';
}

abstract class _$LobbyDetailController extends $AsyncNotifier<LobbyDetailInfo> {
  late final _$args = ref.$arg as String;
  String get lobbyId => _$args;

  FutureOr<LobbyDetailInfo> build(String lobbyId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<LobbyDetailInfo>, LobbyDetailInfo>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<LobbyDetailInfo>, LobbyDetailInfo>,
              AsyncValue<LobbyDetailInfo>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
