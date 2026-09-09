// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friendly_offer_feed_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Open friendly fixtures for the context sport, ranked by how close a match
/// they'd be against the lobby the user is challenging as.

@ProviderFor(FriendlyOfferFeed)
final friendlyOfferFeedProvider = FriendlyOfferFeedProvider._();

/// Open friendly fixtures for the context sport, ranked by how close a match
/// they'd be against the lobby the user is challenging as.
final class FriendlyOfferFeedProvider
    extends $AsyncNotifierProvider<FriendlyOfferFeed, List<FriendlyOffer>> {
  /// Open friendly fixtures for the context sport, ranked by how close a match
  /// they'd be against the lobby the user is challenging as.
  FriendlyOfferFeedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'friendlyOfferFeedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$friendlyOfferFeedHash();

  @$internal
  @override
  FriendlyOfferFeed create() => FriendlyOfferFeed();
}

String _$friendlyOfferFeedHash() => r'c47d7f38b3963cf03d1588ab75eb15034e3eda5b';

/// Open friendly fixtures for the context sport, ranked by how close a match
/// they'd be against the lobby the user is challenging as.

abstract class _$FriendlyOfferFeed extends $AsyncNotifier<List<FriendlyOffer>> {
  FutureOr<List<FriendlyOffer>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<FriendlyOffer>>, List<FriendlyOffer>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<FriendlyOffer>>, List<FriendlyOffer>>,
              AsyncValue<List<FriendlyOffer>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Sends a friendly challenge against one advertised fixture.
///
/// The challenger does not propose anything — the fixture's terms are fixed
/// and the RPC snapshots them. What the challenger DOES set is their own
/// confirmation threshold: how many of their players have to commit before the
/// handshake is allowed to reach the other lobby at all. That number is theirs
/// because it is their roster, and only they know what a Saturday produces.

@ProviderFor(SendFriendlyChallengeController)
final sendFriendlyChallengeControllerProvider =
    SendFriendlyChallengeControllerFamily._();

/// Sends a friendly challenge against one advertised fixture.
///
/// The challenger does not propose anything — the fixture's terms are fixed
/// and the RPC snapshots them. What the challenger DOES set is their own
/// confirmation threshold: how many of their players have to commit before the
/// handshake is allowed to reach the other lobby at all. That number is theirs
/// because it is their roster, and only they know what a Saturday produces.
final class SendFriendlyChallengeControllerProvider
    extends $NotifierProvider<SendFriendlyChallengeController, bool> {
  /// Sends a friendly challenge against one advertised fixture.
  ///
  /// The challenger does not propose anything — the fixture's terms are fixed
  /// and the RPC snapshots them. What the challenger DOES set is their own
  /// confirmation threshold: how many of their players have to commit before the
  /// handshake is allowed to reach the other lobby at all. That number is theirs
  /// because it is their roster, and only they know what a Saturday produces.
  SendFriendlyChallengeControllerProvider._({
    required SendFriendlyChallengeControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'sendFriendlyChallengeControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sendFriendlyChallengeControllerHash();

  @override
  String toString() {
    return r'sendFriendlyChallengeControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SendFriendlyChallengeController create() => SendFriendlyChallengeController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SendFriendlyChallengeControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sendFriendlyChallengeControllerHash() =>
    r'cdf018fe67316d842d47a0cf6d35b9d74e340a52';

/// Sends a friendly challenge against one advertised fixture.
///
/// The challenger does not propose anything — the fixture's terms are fixed
/// and the RPC snapshots them. What the challenger DOES set is their own
/// confirmation threshold: how many of their players have to commit before the
/// handshake is allowed to reach the other lobby at all. That number is theirs
/// because it is their roster, and only they know what a Saturday produces.

final class SendFriendlyChallengeControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          SendFriendlyChallengeController,
          bool,
          bool,
          bool,
          String
        > {
  SendFriendlyChallengeControllerFamily._()
    : super(
        retry: null,
        name: r'sendFriendlyChallengeControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Sends a friendly challenge against one advertised fixture.
  ///
  /// The challenger does not propose anything — the fixture's terms are fixed
  /// and the RPC snapshots them. What the challenger DOES set is their own
  /// confirmation threshold: how many of their players have to commit before the
  /// handshake is allowed to reach the other lobby at all. That number is theirs
  /// because it is their roster, and only they know what a Saturday produces.

  SendFriendlyChallengeControllerProvider call(String initiatorLobbyId) =>
      SendFriendlyChallengeControllerProvider._(
        argument: initiatorLobbyId,
        from: this,
      );

  @override
  String toString() => r'sendFriendlyChallengeControllerProvider';
}

/// Sends a friendly challenge against one advertised fixture.
///
/// The challenger does not propose anything — the fixture's terms are fixed
/// and the RPC snapshots them. What the challenger DOES set is their own
/// confirmation threshold: how many of their players have to commit before the
/// handshake is allowed to reach the other lobby at all. That number is theirs
/// because it is their roster, and only they know what a Saturday produces.

abstract class _$SendFriendlyChallengeController extends $Notifier<bool> {
  late final _$args = ref.$arg as String;
  String get initiatorLobbyId => _$args;

  bool build(String initiatorLobbyId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// How many members the context lobby has — the ceiling on the threshold the
/// challenger can set, mirroring `send_friendly_challenge`'s own guard.

@ProviderFor(contextLobbyMemberCount)
final contextLobbyMemberCountProvider = ContextLobbyMemberCountFamily._();

/// How many members the context lobby has — the ceiling on the threshold the
/// challenger can set, mirroring `send_friendly_challenge`'s own guard.

final class ContextLobbyMemberCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// How many members the context lobby has — the ceiling on the threshold the
  /// challenger can set, mirroring `send_friendly_challenge`'s own guard.
  ContextLobbyMemberCountProvider._({
    required ContextLobbyMemberCountFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'contextLobbyMemberCountProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$contextLobbyMemberCountHash();

  @override
  String toString() {
    return r'contextLobbyMemberCountProvider'
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
    return contextLobbyMemberCount(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ContextLobbyMemberCountProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$contextLobbyMemberCountHash() =>
    r'd9e6c4893af430677e4e091eaf26f158055fe377';

/// How many members the context lobby has — the ceiling on the threshold the
/// challenger can set, mirroring `send_friendly_challenge`'s own guard.

final class ContextLobbyMemberCountFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<int>, String> {
  ContextLobbyMemberCountFamily._()
    : super(
        retry: null,
        name: r'contextLobbyMemberCountProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// How many members the context lobby has — the ceiling on the threshold the
  /// challenger can set, mirroring `send_friendly_challenge`'s own guard.

  ContextLobbyMemberCountProvider call(String lobbyId) =>
      ContextLobbyMemberCountProvider._(argument: lobbyId, from: this);

  @override
  String toString() => r'contextLobbyMemberCountProvider';
}
