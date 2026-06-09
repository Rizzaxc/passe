// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_data_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Resolves the caller's HR thresholds: user-declared values from
/// `user_health_link`, else estimated from an age-bucket max HR. `estimated`
/// stays true until the user declares both LT thresholds.

@ProviderFor(hrThresholds)
final hrThresholdsProvider = HrThresholdsProvider._();

/// Resolves the caller's HR thresholds: user-declared values from
/// `user_health_link`, else estimated from an age-bucket max HR. `estimated`
/// stays true until the user declares both LT thresholds.

final class HrThresholdsProvider
    extends
        $FunctionalProvider<
          AsyncValue<HrThresholds>,
          HrThresholds,
          FutureOr<HrThresholds>
        >
    with $FutureModifier<HrThresholds>, $FutureProvider<HrThresholds> {
  /// Resolves the caller's HR thresholds: user-declared values from
  /// `user_health_link`, else estimated from an age-bucket max HR. `estimated`
  /// stays true until the user declares both LT thresholds.
  HrThresholdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hrThresholdsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hrThresholdsHash();

  @$internal
  @override
  $FutureProviderElement<HrThresholds> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<HrThresholds> create(Ref ref) {
    return hrThresholds(ref);
  }
}

String _$hrThresholdsHash() => r'e711bacfbb8e6e4d8666bfe91129dbfa9206e5e7';

/// Whole-body daily summaries for the last [healthBackfillDays] (direct select).
/// Sport-agnostic. Newest first.

@ProviderFor(dailyHealthTrend)
final dailyHealthTrendProvider = DailyHealthTrendProvider._();

/// Whole-body daily summaries for the last [healthBackfillDays] (direct select).
/// Sport-agnostic. Newest first.

final class DailyHealthTrendProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DailyHealthSummary>>,
          List<DailyHealthSummary>,
          FutureOr<List<DailyHealthSummary>>
        >
    with
        $FutureModifier<List<DailyHealthSummary>>,
        $FutureProvider<List<DailyHealthSummary>> {
  /// Whole-body daily summaries for the last [healthBackfillDays] (direct select).
  /// Sport-agnostic. Newest first.
  DailyHealthTrendProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailyHealthTrendProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dailyHealthTrendHash();

  @$internal
  @override
  $FutureProviderElement<List<DailyHealthSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<DailyHealthSummary>> create(Ref ref) {
    return dailyHealthTrend(ref);
  }
}

String _$dailyHealthTrendHash() => r'cb104f97ac7d8904dbd334818df76d48184f5c16';

/// Captured activity recaps for the context sport (RPC). Returns `[]` when no
/// sport is selected.

@ProviderFor(activityHealthList)
final activityHealthListProvider = ActivityHealthListProvider._();

/// Captured activity recaps for the context sport (RPC). Returns `[]` when no
/// sport is selected.

final class ActivityHealthListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ActivityHealthRow>>,
          List<ActivityHealthRow>,
          FutureOr<List<ActivityHealthRow>>
        >
    with
        $FutureModifier<List<ActivityHealthRow>>,
        $FutureProvider<List<ActivityHealthRow>> {
  /// Captured activity recaps for the context sport (RPC). Returns `[]` when no
  /// sport is selected.
  ActivityHealthListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activityHealthListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activityHealthListHash();

  @$internal
  @override
  $FutureProviderElement<List<ActivityHealthRow>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ActivityHealthRow>> create(Ref ref) {
    return activityHealthList(ref);
  }
}

String _$activityHealthListHash() =>
    r'0aa3deec00ee3d4baa2cf4f37f20a0b6e90afa25';

/// Candidate activities the user never confirmed but for which the wearable
/// shows exercise evidence — the reconciliation inbox. Re-checks the device per
/// candidate (the RPC only narrows the set; the device holds the samples).

@ProviderFor(detectedWorkouts)
final detectedWorkoutsProvider = DetectedWorkoutsProvider._();

/// Candidate activities the user never confirmed but for which the wearable
/// shows exercise evidence — the reconciliation inbox. Re-checks the device per
/// candidate (the RPC only narrows the set; the device holds the samples).

final class DetectedWorkoutsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DetectedWorkout>>,
          List<DetectedWorkout>,
          FutureOr<List<DetectedWorkout>>
        >
    with
        $FutureModifier<List<DetectedWorkout>>,
        $FutureProvider<List<DetectedWorkout>> {
  /// Candidate activities the user never confirmed but for which the wearable
  /// shows exercise evidence — the reconciliation inbox. Re-checks the device per
  /// candidate (the RPC only narrows the set; the device holds the samples).
  DetectedWorkoutsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'detectedWorkoutsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$detectedWorkoutsHash();

  @$internal
  @override
  $FutureProviderElement<List<DetectedWorkout>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<DetectedWorkout>> create(Ref ref) {
    return detectedWorkouts(ref);
  }
}

String _$detectedWorkoutsHash() => r'8a0fc3671240e663c66f85394b80d367f30d4e07';
