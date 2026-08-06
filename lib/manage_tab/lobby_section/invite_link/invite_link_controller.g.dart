// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite_link_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(InviteLinkController)
final inviteLinkControllerProvider = InviteLinkControllerFamily._();

final class InviteLinkControllerProvider
    extends $AsyncNotifierProvider<InviteLinkController, LobbyInviteLink?> {
  InviteLinkControllerProvider._({
    required InviteLinkControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'inviteLinkControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$inviteLinkControllerHash();

  @override
  String toString() {
    return r'inviteLinkControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  InviteLinkController create() => InviteLinkController();

  @override
  bool operator ==(Object other) {
    return other is InviteLinkControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$inviteLinkControllerHash() =>
    r'486c2a864108cfd694d3f1265a0e2442a74c1fae';

final class InviteLinkControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          InviteLinkController,
          AsyncValue<LobbyInviteLink?>,
          LobbyInviteLink?,
          FutureOr<LobbyInviteLink?>,
          String
        > {
  InviteLinkControllerFamily._()
    : super(
        retry: null,
        name: r'inviteLinkControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  InviteLinkControllerProvider call(String lobbyId) =>
      InviteLinkControllerProvider._(argument: lobbyId, from: this);

  @override
  String toString() => r'inviteLinkControllerProvider';
}

abstract class _$InviteLinkController extends $AsyncNotifier<LobbyInviteLink?> {
  late final _$args = ref.$arg as String;
  String get lobbyId => _$args;

  FutureOr<LobbyInviteLink?> build(String lobbyId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<LobbyInviteLink?>, LobbyInviteLink?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<LobbyInviteLink?>, LobbyInviteLink?>,
              AsyncValue<LobbyInviteLink?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
