// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LobbyMembersController)
final lobbyMembersControllerProvider = LobbyMembersControllerFamily._();

final class LobbyMembersControllerProvider
    extends
        $AsyncNotifierProvider<LobbyMembersController, List<LobbyMemberInfo>> {
  LobbyMembersControllerProvider._({
    required LobbyMembersControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'lobbyMembersControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$lobbyMembersControllerHash();

  @override
  String toString() {
    return r'lobbyMembersControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  LobbyMembersController create() => LobbyMembersController();

  @override
  bool operator ==(Object other) {
    return other is LobbyMembersControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$lobbyMembersControllerHash() =>
    r'6c1d723bc663d53adcd3b2a98ff50bbddc5698b9';

final class LobbyMembersControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          LobbyMembersController,
          AsyncValue<List<LobbyMemberInfo>>,
          List<LobbyMemberInfo>,
          FutureOr<List<LobbyMemberInfo>>,
          String
        > {
  LobbyMembersControllerFamily._()
    : super(
        retry: null,
        name: r'lobbyMembersControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  LobbyMembersControllerProvider call(String lobbyId) =>
      LobbyMembersControllerProvider._(argument: lobbyId, from: this);

  @override
  String toString() => r'lobbyMembersControllerProvider';
}

abstract class _$LobbyMembersController
    extends $AsyncNotifier<List<LobbyMemberInfo>> {
  late final _$args = ref.$arg as String;
  String get lobbyId => _$args;

  FutureOr<List<LobbyMemberInfo>> build(String lobbyId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<LobbyMemberInfo>>, List<LobbyMemberInfo>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<LobbyMemberInfo>>,
                List<LobbyMemberInfo>
              >,
              AsyncValue<List<LobbyMemberInfo>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
