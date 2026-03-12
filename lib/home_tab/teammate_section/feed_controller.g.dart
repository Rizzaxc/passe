// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TeammateFeed)
final teammateFeedProvider = TeammateFeedProvider._();

final class TeammateFeedProvider
    extends $AsyncNotifierProvider<TeammateFeed, List<Map<String, dynamic>>> {
  TeammateFeedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teammateFeedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teammateFeedHash();

  @$internal
  @override
  TeammateFeed create() => TeammateFeed();
}

String _$teammateFeedHash() => r'65895f7a3db67e3a9806776008f595e9bcadf386';

abstract class _$TeammateFeed
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
