// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommendation_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The verdict this user already cast on one match, if any.
///
/// `lobby_recommendation` is public-readable — the tallies are the point, and
/// an anonymous denouncement is a different, worse product — so this is a plain
/// select rather than an RPC.

@ProviderFor(myRecommendation)
final myRecommendationProvider = MyRecommendationFamily._();

/// The verdict this user already cast on one match, if any.
///
/// `lobby_recommendation` is public-readable — the tallies are the point, and
/// an anonymous denouncement is a different, worse product — so this is a plain
/// select rather than an RPC.

final class MyRecommendationProvider
    extends
        $FunctionalProvider<
          AsyncValue<LobbyRecommendationKind?>,
          LobbyRecommendationKind?,
          FutureOr<LobbyRecommendationKind?>
        >
    with
        $FutureModifier<LobbyRecommendationKind?>,
        $FutureProvider<LobbyRecommendationKind?> {
  /// The verdict this user already cast on one match, if any.
  ///
  /// `lobby_recommendation` is public-readable — the tallies are the point, and
  /// an anonymous denouncement is a different, worse product — so this is a plain
  /// select rather than an RPC.
  MyRecommendationProvider._({
    required MyRecommendationFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'myRecommendationProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$myRecommendationHash();

  @override
  String toString() {
    return r'myRecommendationProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<LobbyRecommendationKind?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<LobbyRecommendationKind?> create(Ref ref) {
    final argument = this.argument as String;
    return myRecommendation(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MyRecommendationProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$myRecommendationHash() => r'6070e5224003f7a8477cf0caab3452ce9299be1f';

/// The verdict this user already cast on one match, if any.
///
/// `lobby_recommendation` is public-readable — the tallies are the point, and
/// an anonymous denouncement is a different, worse product — so this is a plain
/// select rather than an RPC.

final class MyRecommendationFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<LobbyRecommendationKind?>, String> {
  MyRecommendationFamily._()
    : super(
        retry: null,
        name: r'myRecommendationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The verdict this user already cast on one match, if any.
  ///
  /// `lobby_recommendation` is public-readable — the tallies are the point, and
  /// an anonymous denouncement is a different, worse product — so this is a plain
  /// select rather than an RPC.

  MyRecommendationProvider call(String matchId) =>
      MyRecommendationProvider._(argument: matchId, from: this);

  @override
  String toString() => r'myRecommendationProvider';
}

/// Cast (or change) a post-match verdict on the opposing lobby.
///
/// Changeable inside the 24h window on purpose: a first impression written in
/// the car park is worth less than one written after the group chat has caught
/// up, and a verdict nobody can revise is one people hesitate to give at all.

@ProviderFor(RecommendLobbyController)
final recommendLobbyControllerProvider = RecommendLobbyControllerFamily._();

/// Cast (or change) a post-match verdict on the opposing lobby.
///
/// Changeable inside the 24h window on purpose: a first impression written in
/// the car park is worth less than one written after the group chat has caught
/// up, and a verdict nobody can revise is one people hesitate to give at all.
final class RecommendLobbyControllerProvider
    extends $NotifierProvider<RecommendLobbyController, bool> {
  /// Cast (or change) a post-match verdict on the opposing lobby.
  ///
  /// Changeable inside the 24h window on purpose: a first impression written in
  /// the car park is worth less than one written after the group chat has caught
  /// up, and a verdict nobody can revise is one people hesitate to give at all.
  RecommendLobbyControllerProvider._({
    required RecommendLobbyControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'recommendLobbyControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recommendLobbyControllerHash();

  @override
  String toString() {
    return r'recommendLobbyControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  RecommendLobbyController create() => RecommendLobbyController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RecommendLobbyControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recommendLobbyControllerHash() =>
    r'ca330809fac36bba688397453c36b0c659e6be68';

/// Cast (or change) a post-match verdict on the opposing lobby.
///
/// Changeable inside the 24h window on purpose: a first impression written in
/// the car park is worth less than one written after the group chat has caught
/// up, and a verdict nobody can revise is one people hesitate to give at all.

final class RecommendLobbyControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          RecommendLobbyController,
          bool,
          bool,
          bool,
          String
        > {
  RecommendLobbyControllerFamily._()
    : super(
        retry: null,
        name: r'recommendLobbyControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Cast (or change) a post-match verdict on the opposing lobby.
  ///
  /// Changeable inside the 24h window on purpose: a first impression written in
  /// the car park is worth less than one written after the group chat has caught
  /// up, and a verdict nobody can revise is one people hesitate to give at all.

  RecommendLobbyControllerProvider call(String matchId) =>
      RecommendLobbyControllerProvider._(argument: matchId, from: this);

  @override
  String toString() => r'recommendLobbyControllerProvider';
}

/// Cast (or change) a post-match verdict on the opposing lobby.
///
/// Changeable inside the 24h window on purpose: a first impression written in
/// the car park is worth less than one written after the group chat has caught
/// up, and a verdict nobody can revise is one people hesitate to give at all.

abstract class _$RecommendLobbyController extends $Notifier<bool> {
  late final _$args = ref.$arg as String;
  String get matchId => _$args;

  bool build(String matchId);
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
