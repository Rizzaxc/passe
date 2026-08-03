// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'challenges_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Open + accepted challenges for a lobby, both directions. Managers accept /
/// decline incoming ones and cancel their own outgoing ones.

@ProviderFor(LobbyChallengesController)
final lobbyChallengesControllerProvider = LobbyChallengesControllerFamily._();

/// Open + accepted challenges for a lobby, both directions. Managers accept /
/// decline incoming ones and cancel their own outgoing ones.
final class LobbyChallengesControllerProvider
    extends
        $AsyncNotifierProvider<
          LobbyChallengesController,
          List<LobbyChallenge>
        > {
  /// Open + accepted challenges for a lobby, both directions. Managers accept /
  /// decline incoming ones and cancel their own outgoing ones.
  LobbyChallengesControllerProvider._({
    required LobbyChallengesControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'lobbyChallengesControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$lobbyChallengesControllerHash();

  @override
  String toString() {
    return r'lobbyChallengesControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  LobbyChallengesController create() => LobbyChallengesController();

  @override
  bool operator ==(Object other) {
    return other is LobbyChallengesControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$lobbyChallengesControllerHash() =>
    r'0adbfafd968d2cf2b72a7dcb9104f8bbfab06fd7';

/// Open + accepted challenges for a lobby, both directions. Managers accept /
/// decline incoming ones and cancel their own outgoing ones.

final class LobbyChallengesControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          LobbyChallengesController,
          AsyncValue<List<LobbyChallenge>>,
          List<LobbyChallenge>,
          FutureOr<List<LobbyChallenge>>,
          String
        > {
  LobbyChallengesControllerFamily._()
    : super(
        retry: null,
        name: r'lobbyChallengesControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Open + accepted challenges for a lobby, both directions. Managers accept /
  /// decline incoming ones and cancel their own outgoing ones.

  LobbyChallengesControllerProvider call(String lobbyId) =>
      LobbyChallengesControllerProvider._(argument: lobbyId, from: this);

  @override
  String toString() => r'lobbyChallengesControllerProvider';
}

/// Open + accepted challenges for a lobby, both directions. Managers accept /
/// decline incoming ones and cancel their own outgoing ones.

abstract class _$LobbyChallengesController
    extends $AsyncNotifier<List<LobbyChallenge>> {
  late final _$args = ref.$arg as String;
  String get lobbyId => _$args;

  FutureOr<List<LobbyChallenge>> build(String lobbyId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<LobbyChallenge>>, List<LobbyChallenge>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<LobbyChallenge>>,
                List<LobbyChallenge>
              >,
              AsyncValue<List<LobbyChallenge>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// Count of open incoming challenges — drives the badge on the lobby detail.

@ProviderFor(incomingChallengeCount)
final incomingChallengeCountProvider = IncomingChallengeCountFamily._();

/// Count of open incoming challenges — drives the badge on the lobby detail.

final class IncomingChallengeCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Count of open incoming challenges — drives the badge on the lobby detail.
  IncomingChallengeCountProvider._({
    required IncomingChallengeCountFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'incomingChallengeCountProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$incomingChallengeCountHash();

  @override
  String toString() {
    return r'incomingChallengeCountProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    final argument = this.argument as String;
    return incomingChallengeCount(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is IncomingChallengeCountProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$incomingChallengeCountHash() =>
    r'98ee804dc1024baa25e4f7fa3922c70b04796b39';

/// Count of open incoming challenges — drives the badge on the lobby detail.

final class IncomingChallengeCountFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<int>, String> {
  IncomingChallengeCountFamily._()
    : super(
        retry: null,
        name: r'incomingChallengeCountProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Count of open incoming challenges — drives the badge on the lobby detail.

  IncomingChallengeCountProvider call(String lobbyId) =>
      IncomingChallengeCountProvider._(argument: lobbyId, from: this);

  @override
  String toString() => r'incomingChallengeCountProvider';
}
