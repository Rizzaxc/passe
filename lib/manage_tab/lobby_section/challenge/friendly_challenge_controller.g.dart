// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friendly_challenge_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Live friendly challenges for a lobby, both directions.

@ProviderFor(FriendlyChallengesController)
final friendlyChallengesControllerProvider =
    FriendlyChallengesControllerFamily._();

/// Live friendly challenges for a lobby, both directions.
final class FriendlyChallengesControllerProvider
    extends
        $AsyncNotifierProvider<
          FriendlyChallengesController,
          List<FriendlyChallenge>
        > {
  /// Live friendly challenges for a lobby, both directions.
  FriendlyChallengesControllerProvider._({
    required FriendlyChallengesControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'friendlyChallengesControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$friendlyChallengesControllerHash();

  @override
  String toString() {
    return r'friendlyChallengesControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  FriendlyChallengesController create() => FriendlyChallengesController();

  @override
  bool operator ==(Object other) {
    return other is FriendlyChallengesControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$friendlyChallengesControllerHash() =>
    r'b9e5b25d0b28baad48084b606aafb44fc2b24c7a';

/// Live friendly challenges for a lobby, both directions.

final class FriendlyChallengesControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          FriendlyChallengesController,
          AsyncValue<List<FriendlyChallenge>>,
          List<FriendlyChallenge>,
          FutureOr<List<FriendlyChallenge>>,
          String
        > {
  FriendlyChallengesControllerFamily._()
    : super(
        retry: null,
        name: r'friendlyChallengesControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Live friendly challenges for a lobby, both directions.

  FriendlyChallengesControllerProvider call(String lobbyId) =>
      FriendlyChallengesControllerProvider._(argument: lobbyId, from: this);

  @override
  String toString() => r'friendlyChallengesControllerProvider';
}

/// Live friendly challenges for a lobby, both directions.

abstract class _$FriendlyChallengesController
    extends $AsyncNotifier<List<FriendlyChallenge>> {
  late final _$args = ref.$arg as String;
  String get lobbyId => _$args;

  FutureOr<List<FriendlyChallenge>> build(String lobbyId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<FriendlyChallenge>>,
              List<FriendlyChallenge>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<FriendlyChallenge>>,
                List<FriendlyChallenge>
              >,
              AsyncValue<List<FriendlyChallenge>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// One lobby's blind result report.
///
/// The opponent files separately and neither side sees the other until both
/// are in — enforced by RLS on `lobby_challenge_report`, not by this class.

@ProviderFor(ReportMatchResultController)
final reportMatchResultControllerProvider =
    ReportMatchResultControllerFamily._();

/// One lobby's blind result report.
///
/// The opponent files separately and neither side sees the other until both
/// are in — enforced by RLS on `lobby_challenge_report`, not by this class.
final class ReportMatchResultControllerProvider
    extends $NotifierProvider<ReportMatchResultController, bool> {
  /// One lobby's blind result report.
  ///
  /// The opponent files separately and neither side sees the other until both
  /// are in — enforced by RLS on `lobby_challenge_report`, not by this class.
  ReportMatchResultControllerProvider._({
    required ReportMatchResultControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'reportMatchResultControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$reportMatchResultControllerHash();

  @override
  String toString() {
    return r'reportMatchResultControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ReportMatchResultController create() => ReportMatchResultController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ReportMatchResultControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$reportMatchResultControllerHash() =>
    r'3d9faff1dd8eee7b03cfc41314c58cdc089f6237';

/// One lobby's blind result report.
///
/// The opponent files separately and neither side sees the other until both
/// are in — enforced by RLS on `lobby_challenge_report`, not by this class.

final class ReportMatchResultControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ReportMatchResultController,
          bool,
          bool,
          bool,
          String
        > {
  ReportMatchResultControllerFamily._()
    : super(
        retry: null,
        name: r'reportMatchResultControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One lobby's blind result report.
  ///
  /// The opponent files separately and neither side sees the other until both
  /// are in — enforced by RLS on `lobby_challenge_report`, not by this class.

  ReportMatchResultControllerProvider call(String lobbyId) =>
      ReportMatchResultControllerProvider._(argument: lobbyId, from: this);

  @override
  String toString() => r'reportMatchResultControllerProvider';
}

/// One lobby's blind result report.
///
/// The opponent files separately and neither side sees the other until both
/// are in — enforced by RLS on `lobby_challenge_report`, not by this class.

abstract class _$ReportMatchResultController extends $Notifier<bool> {
  late final _$args = ref.$arg as String;
  String get lobbyId => _$args;

  bool build(String lobbyId);
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

/// The in-match no-show claim, the accused's two answers, and withdrawing a
/// challenge.
///
/// The claim files the claimant's report on the spot. The accused then has the
/// ordinary reporting window (until 24h after the final whistle) — not ten
/// minutes in the middle of a match they may be playing. Countering makes it a
/// dispute, conceding settles the walkover at once, and silence settles it as
/// a walkover at the deadline.

@ProviderFor(FriendlyChallengeActionsController)
final friendlyChallengeActionsControllerProvider =
    FriendlyChallengeActionsControllerFamily._();

/// The in-match no-show claim, the accused's two answers, and withdrawing a
/// challenge.
///
/// The claim files the claimant's report on the spot. The accused then has the
/// ordinary reporting window (until 24h after the final whistle) — not ten
/// minutes in the middle of a match they may be playing. Countering makes it a
/// dispute, conceding settles the walkover at once, and silence settles it as
/// a walkover at the deadline.
final class FriendlyChallengeActionsControllerProvider
    extends $NotifierProvider<FriendlyChallengeActionsController, bool> {
  /// The in-match no-show claim, the accused's two answers, and withdrawing a
  /// challenge.
  ///
  /// The claim files the claimant's report on the spot. The accused then has the
  /// ordinary reporting window (until 24h after the final whistle) — not ten
  /// minutes in the middle of a match they may be playing. Countering makes it a
  /// dispute, conceding settles the walkover at once, and silence settles it as
  /// a walkover at the deadline.
  FriendlyChallengeActionsControllerProvider._({
    required FriendlyChallengeActionsControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'friendlyChallengeActionsControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() =>
      _$friendlyChallengeActionsControllerHash();

  @override
  String toString() {
    return r'friendlyChallengeActionsControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  FriendlyChallengeActionsController create() =>
      FriendlyChallengeActionsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FriendlyChallengeActionsControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$friendlyChallengeActionsControllerHash() =>
    r'72c558721378767ff8ff7cd334004ea7cdbdf26d';

/// The in-match no-show claim, the accused's two answers, and withdrawing a
/// challenge.
///
/// The claim files the claimant's report on the spot. The accused then has the
/// ordinary reporting window (until 24h after the final whistle) — not ten
/// minutes in the middle of a match they may be playing. Countering makes it a
/// dispute, conceding settles the walkover at once, and silence settles it as
/// a walkover at the deadline.

final class FriendlyChallengeActionsControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          FriendlyChallengeActionsController,
          bool,
          bool,
          bool,
          String
        > {
  FriendlyChallengeActionsControllerFamily._()
    : super(
        retry: null,
        name: r'friendlyChallengeActionsControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The in-match no-show claim, the accused's two answers, and withdrawing a
  /// challenge.
  ///
  /// The claim files the claimant's report on the spot. The accused then has the
  /// ordinary reporting window (until 24h after the final whistle) — not ten
  /// minutes in the middle of a match they may be playing. Countering makes it a
  /// dispute, conceding settles the walkover at once, and silence settles it as
  /// a walkover at the deadline.

  FriendlyChallengeActionsControllerProvider call(String lobbyId) =>
      FriendlyChallengeActionsControllerProvider._(
        argument: lobbyId,
        from: this,
      );

  @override
  String toString() => r'friendlyChallengeActionsControllerProvider';
}

/// The in-match no-show claim, the accused's two answers, and withdrawing a
/// challenge.
///
/// The claim files the claimant's report on the spot. The accused then has the
/// ordinary reporting window (until 24h after the final whistle) — not ten
/// minutes in the middle of a match they may be playing. Countering makes it a
/// dispute, conceding settles the walkover at once, and silence settles it as
/// a walkover at the deadline.

abstract class _$FriendlyChallengeActionsController extends $Notifier<bool> {
  late final _$args = ref.$arg as String;
  String get lobbyId => _$args;

  bool build(String lobbyId);
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
