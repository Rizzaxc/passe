// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ad_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Preloads and serves interstitials.
///
/// Usage: `ref.read(interstitialControllerProvider.notifier).show()` at a
/// natural break point. The controller transparently reloads the next ad after
/// each show (or after a failed/expired impression), so callers never block on
/// network — if nothing is loaded yet, `show()` is a no-op and the user flow
/// continues uninterrupted.

@ProviderFor(InterstitialController)
final interstitialControllerProvider = InterstitialControllerProvider._();

/// Preloads and serves interstitials.
///
/// Usage: `ref.read(interstitialControllerProvider.notifier).show()` at a
/// natural break point. The controller transparently reloads the next ad after
/// each show (or after a failed/expired impression), so callers never block on
/// network — if nothing is loaded yet, `show()` is a no-op and the user flow
/// continues uninterrupted.
final class InterstitialControllerProvider
    extends $NotifierProvider<InterstitialController, void> {
  /// Preloads and serves interstitials.
  ///
  /// Usage: `ref.read(interstitialControllerProvider.notifier).show()` at a
  /// natural break point. The controller transparently reloads the next ad after
  /// each show (or after a failed/expired impression), so callers never block on
  /// network — if nothing is loaded yet, `show()` is a no-op and the user flow
  /// continues uninterrupted.
  InterstitialControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'interstitialControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$interstitialControllerHash();

  @$internal
  @override
  InterstitialController create() => InterstitialController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$interstitialControllerHash() =>
    r'a362121a5c60d1660a2b07bc812c3b792b7d04cc';

/// Preloads and serves interstitials.
///
/// Usage: `ref.read(interstitialControllerProvider.notifier).show()` at a
/// natural break point. The controller transparently reloads the next ad after
/// each show (or after a failed/expired impression), so callers never block on
/// network — if nothing is loaded yet, `show()` is a no-op and the user flow
/// continues uninterrupted.

abstract class _$InterstitialController extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
