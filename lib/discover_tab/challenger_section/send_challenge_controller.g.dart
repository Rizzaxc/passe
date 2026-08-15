// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'send_challenge_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Sends a lobby-vs-lobby challenge from the user's "challenging as" context
/// lobby to a lobby they picked off the challenger feed.
///
/// Backed by the `send_challenge` RPC (schema/challenge_flow.sql). The
/// challenger does **not** propose a time or venue: the target published an
/// offer (when / where / cost per team) and this is a taker, so the RPC
/// snapshots that offer onto the challenge row. All the caller adds is an
/// optional note.
///
/// Lived in `manage_tab/lobby_section/invite_challenge_controller.dart` while a
/// lobby could also start a challenge by SearchID; that entry point is retired
/// (challenges start from Discover, against a lobby that actually opted in), so
/// this now sits with its only consumer.

@ProviderFor(SendChallengeController)
final sendChallengeControllerProvider = SendChallengeControllerFamily._();

/// Sends a lobby-vs-lobby challenge from the user's "challenging as" context
/// lobby to a lobby they picked off the challenger feed.
///
/// Backed by the `send_challenge` RPC (schema/challenge_flow.sql). The
/// challenger does **not** propose a time or venue: the target published an
/// offer (when / where / cost per team) and this is a taker, so the RPC
/// snapshots that offer onto the challenge row. All the caller adds is an
/// optional note.
///
/// Lived in `manage_tab/lobby_section/invite_challenge_controller.dart` while a
/// lobby could also start a challenge by SearchID; that entry point is retired
/// (challenges start from Discover, against a lobby that actually opted in), so
/// this now sits with its only consumer.
final class SendChallengeControllerProvider
    extends $NotifierProvider<SendChallengeController, bool> {
  /// Sends a lobby-vs-lobby challenge from the user's "challenging as" context
  /// lobby to a lobby they picked off the challenger feed.
  ///
  /// Backed by the `send_challenge` RPC (schema/challenge_flow.sql). The
  /// challenger does **not** propose a time or venue: the target published an
  /// offer (when / where / cost per team) and this is a taker, so the RPC
  /// snapshots that offer onto the challenge row. All the caller adds is an
  /// optional note.
  ///
  /// Lived in `manage_tab/lobby_section/invite_challenge_controller.dart` while a
  /// lobby could also start a challenge by SearchID; that entry point is retired
  /// (challenges start from Discover, against a lobby that actually opted in), so
  /// this now sits with its only consumer.
  SendChallengeControllerProvider._({
    required SendChallengeControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'sendChallengeControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sendChallengeControllerHash();

  @override
  String toString() {
    return r'sendChallengeControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SendChallengeController create() => SendChallengeController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SendChallengeControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sendChallengeControllerHash() =>
    r'903a1bb9c230f92b57ee4e4b98d8269614fff33c';

/// Sends a lobby-vs-lobby challenge from the user's "challenging as" context
/// lobby to a lobby they picked off the challenger feed.
///
/// Backed by the `send_challenge` RPC (schema/challenge_flow.sql). The
/// challenger does **not** propose a time or venue: the target published an
/// offer (when / where / cost per team) and this is a taker, so the RPC
/// snapshots that offer onto the challenge row. All the caller adds is an
/// optional note.
///
/// Lived in `manage_tab/lobby_section/invite_challenge_controller.dart` while a
/// lobby could also start a challenge by SearchID; that entry point is retired
/// (challenges start from Discover, against a lobby that actually opted in), so
/// this now sits with its only consumer.

final class SendChallengeControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          SendChallengeController,
          bool,
          bool,
          bool,
          String
        > {
  SendChallengeControllerFamily._()
    : super(
        retry: null,
        name: r'sendChallengeControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Sends a lobby-vs-lobby challenge from the user's "challenging as" context
  /// lobby to a lobby they picked off the challenger feed.
  ///
  /// Backed by the `send_challenge` RPC (schema/challenge_flow.sql). The
  /// challenger does **not** propose a time or venue: the target published an
  /// offer (when / where / cost per team) and this is a taker, so the RPC
  /// snapshots that offer onto the challenge row. All the caller adds is an
  /// optional note.
  ///
  /// Lived in `manage_tab/lobby_section/invite_challenge_controller.dart` while a
  /// lobby could also start a challenge by SearchID; that entry point is retired
  /// (challenges start from Discover, against a lobby that actually opted in), so
  /// this now sits with its only consumer.

  SendChallengeControllerProvider call(String initiatorLobbyId) =>
      SendChallengeControllerProvider._(argument: initiatorLobbyId, from: this);

  @override
  String toString() => r'sendChallengeControllerProvider';
}

/// Sends a lobby-vs-lobby challenge from the user's "challenging as" context
/// lobby to a lobby they picked off the challenger feed.
///
/// Backed by the `send_challenge` RPC (schema/challenge_flow.sql). The
/// challenger does **not** propose a time or venue: the target published an
/// offer (when / where / cost per team) and this is a taker, so the RPC
/// snapshots that offer onto the challenge row. All the caller adds is an
/// optional note.
///
/// Lived in `manage_tab/lobby_section/invite_challenge_controller.dart` while a
/// lobby could also start a challenge by SearchID; that entry point is retired
/// (challenges start from Discover, against a lobby that actually opted in), so
/// this now sits with its only consumer.

abstract class _$SendChallengeController extends $Notifier<bool> {
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
