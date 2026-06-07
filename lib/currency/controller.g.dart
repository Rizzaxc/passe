// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Đá balance — kept in memory, persisted across launches.
///
/// Right now this is seeded from a constant sample value because the
/// currency ledger isn't in the DB yet. Once the backend lands, replace
/// the seed with a Supabase fetch and wire purchase/spend mutations
/// through here instead of mutating the local int directly.

@ProviderFor(DaBalance)
final daBalanceProvider = DaBalanceProvider._();

/// Đá balance — kept in memory, persisted across launches.
///
/// Right now this is seeded from a constant sample value because the
/// currency ledger isn't in the DB yet. Once the backend lands, replace
/// the seed with a Supabase fetch and wire purchase/spend mutations
/// through here instead of mutating the local int directly.
final class DaBalanceProvider extends $AsyncNotifierProvider<DaBalance, int> {
  /// Đá balance — kept in memory, persisted across launches.
  ///
  /// Right now this is seeded from a constant sample value because the
  /// currency ledger isn't in the DB yet. Once the backend lands, replace
  /// the seed with a Supabase fetch and wire purchase/spend mutations
  /// through here instead of mutating the local int directly.
  DaBalanceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'daBalanceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$daBalanceHash();

  @$internal
  @override
  DaBalance create() => DaBalance();
}

String _$daBalanceHash() => r'1604e7eced88fcff8ff1111f8525b4a7062031b0';

/// Đá balance — kept in memory, persisted across launches.
///
/// Right now this is seeded from a constant sample value because the
/// currency ledger isn't in the DB yet. Once the backend lands, replace
/// the seed with a Supabase fetch and wire purchase/spend mutations
/// through here instead of mutating the local int directly.

abstract class _$DaBalance extends $AsyncNotifier<int> {
  FutureOr<int> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<int>, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<int>, int>,
              AsyncValue<int>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
