// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Persisted onboarding status — the single source of truth `router.dart`'s
/// `redirect` gates on (`coreDone`) and the shell's coach-mark pass consumes
/// (`coachMarksDone`). See `onboarding_prefs.dart` for the underlying keys.

@ProviderFor(OnboardingState)
final onboardingStateProvider = OnboardingStateProvider._();

/// Persisted onboarding status — the single source of truth `router.dart`'s
/// `redirect` gates on (`coreDone`) and the shell's coach-mark pass consumes
/// (`coachMarksDone`). See `onboarding_prefs.dart` for the underlying keys.
final class OnboardingStateProvider
    extends $AsyncNotifierProvider<OnboardingState, OnboardingStatus> {
  /// Persisted onboarding status — the single source of truth `router.dart`'s
  /// `redirect` gates on (`coreDone`) and the shell's coach-mark pass consumes
  /// (`coachMarksDone`). See `onboarding_prefs.dart` for the underlying keys.
  OnboardingStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingStateHash();

  @$internal
  @override
  OnboardingState create() => OnboardingState();
}

String _$onboardingStateHash() => r'6447f631de595980e305e8e189c4fd91d4c52fad';

/// Persisted onboarding status — the single source of truth `router.dart`'s
/// `redirect` gates on (`coreDone`) and the shell's coach-mark pass consumes
/// (`coachMarksDone`). See `onboarding_prefs.dart` for the underlying keys.

abstract class _$OnboardingState extends $AsyncNotifier<OnboardingStatus> {
  FutureOr<OnboardingStatus> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<OnboardingStatus>, OnboardingStatus>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<OnboardingStatus>, OnboardingStatus>,
              AsyncValue<OnboardingStatus>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(OnboardingFlowController)
final onboardingFlowControllerProvider = OnboardingFlowControllerProvider._();

final class OnboardingFlowControllerProvider
    extends $NotifierProvider<OnboardingFlowController, OnboardingStep> {
  OnboardingFlowControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingFlowControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingFlowControllerHash();

  @$internal
  @override
  OnboardingFlowController create() => OnboardingFlowController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OnboardingStep value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OnboardingStep>(value),
    );
  }
}

String _$onboardingFlowControllerHash() =>
    r'b50d7d0a3de5cf63f3fc568554abc2a4dfb11ae7';

abstract class _$OnboardingFlowController extends $Notifier<OnboardingStep> {
  OnboardingStep build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<OnboardingStep, OnboardingStep>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<OnboardingStep, OnboardingStep>,
              OnboardingStep,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
