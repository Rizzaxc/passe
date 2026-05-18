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
    extends $AsyncNotifierProvider<LocationFeed, List<Map<String, dynamic>>> {
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

String _$locationFeedHash() => r'c84a97b07135ae0c26509b022daf44239cbb8ea1';

abstract class _$LocationFeed
    extends $AsyncNotifier<List<Map<String, dynamic>>> {
  FutureOr<List<Map<String, dynamic>>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<Map<String, dynamic>>>,
              List<Map<String, dynamic>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<Map<String, dynamic>>>,
                List<Map<String, dynamic>>
              >,
              AsyncValue<List<Map<String, dynamic>>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
