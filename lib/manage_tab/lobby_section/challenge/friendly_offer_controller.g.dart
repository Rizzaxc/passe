// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friendly_offer_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FriendlyOfferController)
final friendlyOfferControllerProvider = FriendlyOfferControllerFamily._();

final class FriendlyOfferControllerProvider
    extends
        $AsyncNotifierProvider<FriendlyOfferController, ChallengeOfferBoard> {
  FriendlyOfferControllerProvider._({
    required FriendlyOfferControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'friendlyOfferControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$friendlyOfferControllerHash();

  @override
  String toString() {
    return r'friendlyOfferControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  FriendlyOfferController create() => FriendlyOfferController();

  @override
  bool operator ==(Object other) {
    return other is FriendlyOfferControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$friendlyOfferControllerHash() =>
    r'55e43d4131fd7e5613f94c9b855093de5faf710b';

final class FriendlyOfferControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          FriendlyOfferController,
          AsyncValue<ChallengeOfferBoard>,
          ChallengeOfferBoard,
          FutureOr<ChallengeOfferBoard>,
          String
        > {
  FriendlyOfferControllerFamily._()
    : super(
        retry: null,
        name: r'friendlyOfferControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FriendlyOfferControllerProvider call(String lobbyId) =>
      FriendlyOfferControllerProvider._(argument: lobbyId, from: this);

  @override
  String toString() => r'friendlyOfferControllerProvider';
}

abstract class _$FriendlyOfferController
    extends $AsyncNotifier<ChallengeOfferBoard> {
  late final _$args = ref.$arg as String;
  String get lobbyId => _$args;

  FutureOr<ChallengeOfferBoard> build(String lobbyId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ChallengeOfferBoard>, ChallengeOfferBoard>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ChallengeOfferBoard>, ChallengeOfferBoard>,
              AsyncValue<ChallengeOfferBoard>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
