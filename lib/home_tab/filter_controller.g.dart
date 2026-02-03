// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'filter_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FilterState)
final filterStateProvider = FilterStateProvider._();

final class FilterStateProvider
    extends $NotifierProvider<FilterState, FilterData> {
  FilterStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filterStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filterStateHash();

  @$internal
  @override
  FilterState create() => FilterState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FilterData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FilterData>(value),
    );
  }
}

String _$filterStateHash() => r'0b78cb89ce358795f017961921fcfdebcd2718b7';

abstract class _$FilterState extends $Notifier<FilterData> {
  FilterData build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<FilterData, FilterData>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FilterData, FilterData>,
              FilterData,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
