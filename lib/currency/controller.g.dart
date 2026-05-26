// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DaBalance)
final daBalanceProvider = DaBalanceProvider._();

final class DaBalanceProvider extends $AsyncNotifierProvider<DaBalance, int> {
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

String _$daBalanceHash() => r'da-balance-hand-rolled';

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
