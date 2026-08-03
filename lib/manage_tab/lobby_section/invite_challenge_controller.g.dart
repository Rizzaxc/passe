// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite_challenge_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Send a challenge from one lobby to another (lobby-vs-lobby "Thách đấu").
///
/// Backed by the `send_challenge` RPC (schema/lobby_challenge.sql), which
/// validates that the caller manages the initiating lobby, the target is
/// `open_to_challengers` in the same sport, and enqueues a `challenge_received`
/// push to the target's managers.

@ProviderFor(InviteChallengeController)
final inviteChallengeControllerProvider = InviteChallengeControllerFamily._();

/// Send a challenge from one lobby to another (lobby-vs-lobby "Thách đấu").
///
/// Backed by the `send_challenge` RPC (schema/lobby_challenge.sql), which
/// validates that the caller manages the initiating lobby, the target is
/// `open_to_challengers` in the same sport, and enqueues a `challenge_received`
/// push to the target's managers.
final class InviteChallengeControllerProvider
    extends $NotifierProvider<InviteChallengeController, bool> {
  /// Send a challenge from one lobby to another (lobby-vs-lobby "Thách đấu").
  ///
  /// Backed by the `send_challenge` RPC (schema/lobby_challenge.sql), which
  /// validates that the caller manages the initiating lobby, the target is
  /// `open_to_challengers` in the same sport, and enqueues a `challenge_received`
  /// push to the target's managers.
  InviteChallengeControllerProvider._({
    required InviteChallengeControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'inviteChallengeControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$inviteChallengeControllerHash();

  @override
  String toString() {
    return r'inviteChallengeControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  InviteChallengeController create() => InviteChallengeController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is InviteChallengeControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$inviteChallengeControllerHash() =>
    r'0cf5c45767e351a948be73131e11a5bc658e870c';

/// Send a challenge from one lobby to another (lobby-vs-lobby "Thách đấu").
///
/// Backed by the `send_challenge` RPC (schema/lobby_challenge.sql), which
/// validates that the caller manages the initiating lobby, the target is
/// `open_to_challengers` in the same sport, and enqueues a `challenge_received`
/// push to the target's managers.

final class InviteChallengeControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          InviteChallengeController,
          bool,
          bool,
          bool,
          String
        > {
  InviteChallengeControllerFamily._()
    : super(
        retry: null,
        name: r'inviteChallengeControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Send a challenge from one lobby to another (lobby-vs-lobby "Thách đấu").
  ///
  /// Backed by the `send_challenge` RPC (schema/lobby_challenge.sql), which
  /// validates that the caller manages the initiating lobby, the target is
  /// `open_to_challengers` in the same sport, and enqueues a `challenge_received`
  /// push to the target's managers.

  InviteChallengeControllerProvider call(String initiatorLobbyId) =>
      InviteChallengeControllerProvider._(
        argument: initiatorLobbyId,
        from: this,
      );

  @override
  String toString() => r'inviteChallengeControllerProvider';
}

/// Send a challenge from one lobby to another (lobby-vs-lobby "Thách đấu").
///
/// Backed by the `send_challenge` RPC (schema/lobby_challenge.sql), which
/// validates that the caller manages the initiating lobby, the target is
/// `open_to_challengers` in the same sport, and enqueues a `challenge_received`
/// push to the target's managers.

abstract class _$InviteChallengeController extends $Notifier<bool> {
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
