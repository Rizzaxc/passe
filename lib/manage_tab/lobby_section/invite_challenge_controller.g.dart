// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite_challenge_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Send a challenge invite from one lobby to another.
///
/// TODO(challenger-system): the `lobby_challenge` table hasn't been
/// designed yet (see CLAUDE.md ▸ Challenger System). Today this is a
/// no-op so the empty-hero CTA flow runs end-to-end. Once the table
/// + handshake RPC land, wire the insert here.

@ProviderFor(InviteChallengeController)
final inviteChallengeControllerProvider = InviteChallengeControllerFamily._();

/// Send a challenge invite from one lobby to another.
///
/// TODO(challenger-system): the `lobby_challenge` table hasn't been
/// designed yet (see CLAUDE.md ▸ Challenger System). Today this is a
/// no-op so the empty-hero CTA flow runs end-to-end. Once the table
/// + handshake RPC land, wire the insert here.
final class InviteChallengeControllerProvider
    extends $NotifierProvider<InviteChallengeController, bool> {
  /// Send a challenge invite from one lobby to another.
  ///
  /// TODO(challenger-system): the `lobby_challenge` table hasn't been
  /// designed yet (see CLAUDE.md ▸ Challenger System). Today this is a
  /// no-op so the empty-hero CTA flow runs end-to-end. Once the table
  /// + handshake RPC land, wire the insert here.
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
    r'c9d73aecfccc1077b571449878286f9ecaada12c';

/// Send a challenge invite from one lobby to another.
///
/// TODO(challenger-system): the `lobby_challenge` table hasn't been
/// designed yet (see CLAUDE.md ▸ Challenger System). Today this is a
/// no-op so the empty-hero CTA flow runs end-to-end. Once the table
/// + handshake RPC land, wire the insert here.

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

  /// Send a challenge invite from one lobby to another.
  ///
  /// TODO(challenger-system): the `lobby_challenge` table hasn't been
  /// designed yet (see CLAUDE.md ▸ Challenger System). Today this is a
  /// no-op so the empty-hero CTA flow runs end-to-end. Once the table
  /// + handshake RPC land, wire the insert here.

  InviteChallengeControllerProvider call(String initiatorLobbyId) =>
      InviteChallengeControllerProvider._(
        argument: initiatorLobbyId,
        from: this,
      );

  @override
  String toString() => r'inviteChallengeControllerProvider';
}

/// Send a challenge invite from one lobby to another.
///
/// TODO(challenger-system): the `lobby_challenge` table hasn't been
/// designed yet (see CLAUDE.md ▸ Challenger System). Today this is a
/// no-op so the empty-hero CTA flow runs end-to-end. Once the table
/// + handshake RPC land, wire the insert here.

abstract class _$InviteChallengeController extends $Notifier<bool> {
  late final _$args = ref.$arg as String;
  String get initiatorLobbyId => _$args;

  bool build(String initiatorLobbyId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
