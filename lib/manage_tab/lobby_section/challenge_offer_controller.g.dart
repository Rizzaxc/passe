// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'challenge_offer_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ChallengeOfferController)
final challengeOfferControllerProvider = ChallengeOfferControllerFamily._();

final class ChallengeOfferControllerProvider
    extends $AsyncNotifierProvider<ChallengeOfferController, ChallengeOffer> {
  ChallengeOfferControllerProvider._({
    required ChallengeOfferControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'challengeOfferControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$challengeOfferControllerHash();

  @override
  String toString() {
    return r'challengeOfferControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ChallengeOfferController create() => ChallengeOfferController();

  @override
  bool operator ==(Object other) {
    return other is ChallengeOfferControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$challengeOfferControllerHash() =>
    r'39cec678ba7c105c70951caed0a6a9355016c0a9';

final class ChallengeOfferControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ChallengeOfferController,
          AsyncValue<ChallengeOffer>,
          ChallengeOffer,
          FutureOr<ChallengeOffer>,
          String
        > {
  ChallengeOfferControllerFamily._()
    : super(
        retry: null,
        name: r'challengeOfferControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ChallengeOfferControllerProvider call(String lobbyId) =>
      ChallengeOfferControllerProvider._(argument: lobbyId, from: this);

  @override
  String toString() => r'challengeOfferControllerProvider';
}

abstract class _$ChallengeOfferController
    extends $AsyncNotifier<ChallengeOffer> {
  late final _$args = ref.$arg as String;
  String get lobbyId => _$args;

  FutureOr<ChallengeOffer> build(String lobbyId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ChallengeOffer>, ChallengeOffer>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ChallengeOffer>, ChallengeOffer>,
              AsyncValue<ChallengeOffer>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
