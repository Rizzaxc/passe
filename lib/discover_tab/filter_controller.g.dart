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

String _$filterStateHash() => r'940cc5060b7526b8bb9b57007580dd7b422baa7d';

abstract class _$FilterState extends $Notifier<FilterData> {
  FilterData build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<FilterData, FilterData>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FilterData, FilterData>,
              FilterData,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// True when the user has narrowed the filter away from their profile seed.
/// Drives the dot on Discover's filter summary chip and the reset action.

@ProviderFor(filterIsActive)
final filterIsActiveProvider = FilterIsActiveProvider._();

/// True when the user has narrowed the filter away from their profile seed.
/// Drives the dot on Discover's filter summary chip and the reset action.

final class FilterIsActiveProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// True when the user has narrowed the filter away from their profile seed.
  /// Drives the dot on Discover's filter summary chip and the reset action.
  FilterIsActiveProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filterIsActiveProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filterIsActiveHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return filterIsActive(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$filterIsActiveHash() => r'd58690bd8a5f555009c7559e10babb52d82bc0e9';
