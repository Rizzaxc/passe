// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LocationFeed)
final locationFeedProvider = LocationFeedProvider._();

final class LocationFeedProvider
    extends $AsyncNotifierProvider<LocationFeed, List<Location>> {
  LocationFeedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'locationFeedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$locationFeedHash();

  @$internal
  @override
  LocationFeed create() => LocationFeed();
}

String _$locationFeedHash() => r'6c2fa1048c2da2ce2db015ded0da1cb64d9cfe09';

abstract class _$LocationFeed extends $AsyncNotifier<List<Location>> {
  FutureOr<List<Location>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Location>>, List<Location>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Location>>, List<Location>>,
              AsyncValue<List<Location>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
