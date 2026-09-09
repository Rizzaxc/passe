// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'challenger_chooser_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Challengers waiting on this lobby's answer.

@ProviderFor(PendingChallengersController)
final pendingChallengersControllerProvider =
    PendingChallengersControllerFamily._();

/// Challengers waiting on this lobby's answer.
final class PendingChallengersControllerProvider
    extends
        $AsyncNotifierProvider<
          PendingChallengersController,
          List<PendingChallenger>
        > {
  /// Challengers waiting on this lobby's answer.
  PendingChallengersControllerProvider._({
    required PendingChallengersControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'pendingChallengersControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pendingChallengersControllerHash();

  @override
  String toString() {
    return r'pendingChallengersControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PendingChallengersController create() => PendingChallengersController();

  @override
  bool operator ==(Object other) {
    return other is PendingChallengersControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pendingChallengersControllerHash() =>
    r'f1f3d9d7e745d67be6631d437d485fec96e1aa0b';

/// Challengers waiting on this lobby's answer.

final class PendingChallengersControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          PendingChallengersController,
          AsyncValue<List<PendingChallenger>>,
          List<PendingChallenger>,
          FutureOr<List<PendingChallenger>>,
          String
        > {
  PendingChallengersControllerFamily._()
    : super(
        retry: null,
        name: r'pendingChallengersControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Challengers waiting on this lobby's answer.

  PendingChallengersControllerProvider call(String lobbyId) =>
      PendingChallengersControllerProvider._(argument: lobbyId, from: this);

  @override
  String toString() => r'pendingChallengersControllerProvider';
}

/// Challengers waiting on this lobby's answer.

abstract class _$PendingChallengersController
    extends $AsyncNotifier<List<PendingChallenger>> {
  late final _$args = ref.$arg as String;
  String get lobbyId => _$args;

  FutureOr<List<PendingChallenger>> build(String lobbyId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<PendingChallenger>>,
              List<PendingChallenger>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<PendingChallenger>>,
                List<PendingChallenger>
              >,
              AsyncValue<List<PendingChallenger>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// Home's answer. Accepting is not just a yes — it spends the offer slot and
/// declines every other lobby waiting on it, which is why the sheet says so
/// before the button is pressed.

@ProviderFor(RespondFriendlyChallengeController)
final respondFriendlyChallengeControllerProvider =
    RespondFriendlyChallengeControllerFamily._();

/// Home's answer. Accepting is not just a yes — it spends the offer slot and
/// declines every other lobby waiting on it, which is why the sheet says so
/// before the button is pressed.
final class RespondFriendlyChallengeControllerProvider
    extends $NotifierProvider<RespondFriendlyChallengeController, String?> {
  /// Home's answer. Accepting is not just a yes — it spends the offer slot and
  /// declines every other lobby waiting on it, which is why the sheet says so
  /// before the button is pressed.
  RespondFriendlyChallengeControllerProvider._({
    required RespondFriendlyChallengeControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'respondFriendlyChallengeControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() =>
      _$respondFriendlyChallengeControllerHash();

  @override
  String toString() {
    return r'respondFriendlyChallengeControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  RespondFriendlyChallengeController create() =>
      RespondFriendlyChallengeController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RespondFriendlyChallengeControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$respondFriendlyChallengeControllerHash() =>
    r'2986f6ea3c7b873b9154668142be1ce6c2bc336f';

/// Home's answer. Accepting is not just a yes — it spends the offer slot and
/// declines every other lobby waiting on it, which is why the sheet says so
/// before the button is pressed.

final class RespondFriendlyChallengeControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          RespondFriendlyChallengeController,
          String?,
          String?,
          String?,
          String
        > {
  RespondFriendlyChallengeControllerFamily._()
    : super(
        retry: null,
        name: r'respondFriendlyChallengeControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Home's answer. Accepting is not just a yes — it spends the offer slot and
  /// declines every other lobby waiting on it, which is why the sheet says so
  /// before the button is pressed.

  RespondFriendlyChallengeControllerProvider call(String lobbyId) =>
      RespondFriendlyChallengeControllerProvider._(
        argument: lobbyId,
        from: this,
      );

  @override
  String toString() => r'respondFriendlyChallengeControllerProvider';
}

/// Home's answer. Accepting is not just a yes — it spends the offer slot and
/// declines every other lobby waiting on it, which is why the sheet says so
/// before the button is pressed.

abstract class _$RespondFriendlyChallengeController extends $Notifier<String?> {
  late final _$args = ref.$arg as String;
  String get lobbyId => _$args;

  String? build(String lobbyId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// Badge count for the lobby detail — how many lobbies are waiting on us.

@ProviderFor(pendingChallengerCount)
final pendingChallengerCountProvider = PendingChallengerCountFamily._();

/// Badge count for the lobby detail — how many lobbies are waiting on us.

final class PendingChallengerCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Badge count for the lobby detail — how many lobbies are waiting on us.
  PendingChallengerCountProvider._({
    required PendingChallengerCountFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'pendingChallengerCountProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pendingChallengerCountHash();

  @override
  String toString() {
    return r'pendingChallengerCountProvider'
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
    return pendingChallengerCount(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PendingChallengerCountProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pendingChallengerCountHash() =>
    r'7b9264ccc9b90c8a4f3705dec205fc1cf8fe5d3f';

/// Badge count for the lobby detail — how many lobbies are waiting on us.

final class PendingChallengerCountFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<int>, String> {
  PendingChallengerCountFamily._()
    : super(
        retry: null,
        name: r'pendingChallengerCountProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Badge count for the lobby detail — how many lobbies are waiting on us.

  PendingChallengerCountProvider call(String lobbyId) =>
      PendingChallengerCountProvider._(argument: lobbyId, from: this);

  @override
  String toString() => r'pendingChallengerCountProvider';
}
