// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vitality_score_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The signed-in user's most recent Vitality Score (read-only; the evaluator
/// runs on sync, not here). `null` for guests or before the first sync.
/// Pull-to-refresh invalidates this.

@ProviderFor(vitalityScoreSummary)
final vitalityScoreSummaryProvider = VitalityScoreSummaryProvider._();

/// The signed-in user's most recent Vitality Score (read-only; the evaluator
/// runs on sync, not here). `null` for guests or before the first sync.
/// Pull-to-refresh invalidates this.

final class VitalityScoreSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<VitalityScore?>,
          VitalityScore?,
          FutureOr<VitalityScore?>
        >
    with $FutureModifier<VitalityScore?>, $FutureProvider<VitalityScore?> {
  /// The signed-in user's most recent Vitality Score (read-only; the evaluator
  /// runs on sync, not here). `null` for guests or before the first sync.
  /// Pull-to-refresh invalidates this.
  VitalityScoreSummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'vitalityScoreSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$vitalityScoreSummaryHash();

  @$internal
  @override
  $FutureProviderElement<VitalityScore?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<VitalityScore?> create(Ref ref) {
    return vitalityScoreSummary(ref);
  }
}

String _$vitalityScoreSummaryHash() =>
    r'18de31f8153cc5148ade16a336d05b323b1e5f5a';
