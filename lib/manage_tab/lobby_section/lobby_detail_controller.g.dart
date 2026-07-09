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
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<LobbyDetailInfo>, LobbyDetailInfo>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<LobbyDetailInfo>, LobbyDetailInfo>,
              AsyncValue<LobbyDetailInfo>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(myLobbyPermission)
final myLobbyPermissionProvider = MyLobbyPermissionFamily._();

final class MyLobbyPermissionProvider
    extends
        $FunctionalProvider<
          AsyncValue<LobbyPermission>,
          LobbyPermission,
          FutureOr<LobbyPermission>
        >
    with $FutureModifier<LobbyPermission>, $FutureProvider<LobbyPermission> {
  MyLobbyPermissionProvider._({
    required MyLobbyPermissionFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'myLobbyPermissionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$myLobbyPermissionHash();

  @override
  String toString() {
    return r'myLobbyPermissionProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<LobbyPermission> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<LobbyPermission> create(Ref ref) {
    final argument = this.argument as String;
    return myLobbyPermission(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MyLobbyPermissionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$myLobbyPermissionHash() => r'2ce0fffa8b24e44a3b1a1f60a14397825b7e130b';

final class MyLobbyPermissionFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<LobbyPermission>, String> {
  MyLobbyPermissionFamily._()
    : super(
        retry: null,
        name: r'myLobbyPermissionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MyLobbyPermissionProvider call(String lobbyId) =>
      MyLobbyPermissionProvider._(argument: lobbyId, from: this);

  @override
  String toString() => r'myLobbyPermissionProvider';
}
