// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite_challenge_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(InviteChallengeController)
final inviteChallengeControllerProvider =
    InviteChallengeControllerFamily._();

final class InviteChallengeControllerProvider
    extends $NotifierProvider<InviteChallengeController, bool> {
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

String _$inviteChallengeControllerHash() => r'invite-challenge-hand-rolled';

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

  InviteChallengeControllerProvider call(String initiatorLobbyId) =>
      InviteChallengeControllerProvider._(argument: initiatorLobbyId, from: this);

  @override
  String toString() => r'inviteChallengeControllerProvider';
}

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
