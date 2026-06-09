// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievements_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Per-badge progress for the signed-in user (read-only; the evaluator runs on
/// sync, not here). Pull-to-refresh invalidates this.

@ProviderFor(achievementProgressList)
final achievementProgressListProvider = AchievementProgressListProvider._();

/// Per-badge progress for the signed-in user (read-only; the evaluator runs on
/// sync, not here). Pull-to-refresh invalidates this.

final class AchievementProgressListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AchievementProgress>>,
          List<AchievementProgress>,
          FutureOr<List<AchievementProgress>>
        >
    with
        $FutureModifier<List<AchievementProgress>>,
        $FutureProvider<List<AchievementProgress>> {
  /// Per-badge progress for the signed-in user (read-only; the evaluator runs on
  /// sync, not here). Pull-to-refresh invalidates this.
  AchievementProgressListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'achievementProgressListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$achievementProgressListHash();

  @$internal
  @override
  $FutureProviderElement<List<AchievementProgress>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AchievementProgress>> create(Ref ref) {
    return achievementProgressList(ref);
  }
}

String _$achievementProgressListHash() =>
    r'7d4bb04df788409bcf404557c350917eb22390dc';

/// The user's global fitness level + XP floors for the header bar.

@ProviderFor(levelSummary)
final levelSummaryProvider = LevelSummaryProvider._();

/// The user's global fitness level + XP floors for the header bar.

final class LevelSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<LevelSummary>,
          LevelSummary,
          FutureOr<LevelSummary>
        >
    with $FutureModifier<LevelSummary>, $FutureProvider<LevelSummary> {
  /// The user's global fitness level + XP floors for the header bar.
  LevelSummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'levelSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$levelSummaryHash();

  @$internal
  @override
  $FutureProviderElement<LevelSummary> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<LevelSummary> create(Ref ref) {
    return levelSummary(ref);
  }
}

String _$levelSummaryHash() => r'544eff1a0979f69fe5768eedfb8e6b9fac2b2994';

/// Holds the most recent unlock/level-up payload from a sync, consumed and
/// cleared by the achievements subtab to show the celebration sheet.

@ProviderFor(AchievementCelebrationController)
final achievementCelebrationControllerProvider =
    AchievementCelebrationControllerProvider._();

/// Holds the most recent unlock/level-up payload from a sync, consumed and
/// cleared by the achievements subtab to show the celebration sheet.
final class AchievementCelebrationControllerProvider
    extends
        $NotifierProvider<
          AchievementCelebrationController,
          AchievementCelebration?
        > {
  /// Holds the most recent unlock/level-up payload from a sync, consumed and
  /// cleared by the achievements subtab to show the celebration sheet.
  AchievementCelebrationControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'achievementCelebrationControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$achievementCelebrationControllerHash();

  @$internal
  @override
  AchievementCelebrationController create() =>
      AchievementCelebrationController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AchievementCelebration? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AchievementCelebration?>(value),
    );
  }
}

String _$achievementCelebrationControllerHash() =>
    r'874fcaeeb4cbf6a1ead965d3d5306211d6ea83d5';

/// Holds the most recent unlock/level-up payload from a sync, consumed and
/// cleared by the achievements subtab to show the celebration sheet.

abstract class _$AchievementCelebrationController
    extends $Notifier<AchievementCelebration?> {
  AchievementCelebration? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AchievementCelebration?, AchievementCelebration?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AchievementCelebration?, AchievementCelebration?>,
              AchievementCelebration?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Whether there are unlocked-but-unseen achievements (drives the trophy-tab
/// dot). Persisted so it survives an app close before the user looks.

@ProviderFor(UnseenAchievements)
final unseenAchievementsProvider = UnseenAchievementsProvider._();

/// Whether there are unlocked-but-unseen achievements (drives the trophy-tab
/// dot). Persisted so it survives an app close before the user looks.
final class UnseenAchievementsProvider
    extends $AsyncNotifierProvider<UnseenAchievements, bool> {
  /// Whether there are unlocked-but-unseen achievements (drives the trophy-tab
  /// dot). Persisted so it survives an app close before the user looks.
  UnseenAchievementsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unseenAchievementsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unseenAchievementsHash();

  @$internal
  @override
  UnseenAchievements create() => UnseenAchievements();
}

String _$unseenAchievementsHash() =>
    r'1550753fd95e63b40c565f16334286c7afc0d5e2';

/// Whether there are unlocked-but-unseen achievements (drives the trophy-tab
/// dot). Persisted so it survives an app close before the user looks.

abstract class _$UnseenAchievements extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
