// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ChallengerFeed)
final challengerFeedProvider = ChallengerFeedProvider._();

final class ChallengerFeedProvider
    extends $AsyncNotifierProvider<ChallengerFeed, List<LobbyFeedItem>> {
  ChallengerFeedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'challengerFeedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$challengerFeedHash();

  @$internal
  @override
  ChallengerFeed create() => ChallengerFeed();
}

String _$challengerFeedHash() => r'ad26fe6b8bcc9f75368d44c14f14200465c9c27f';

abstract class _$ChallengerFeed extends $AsyncNotifier<List<LobbyFeedItem>> {
  FutureOr<List<LobbyFeedItem>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<LobbyFeedItem>>, List<LobbyFeedItem>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<LobbyFeedItem>>, List<LobbyFeedItem>>,
              AsyncValue<List<LobbyFeedItem>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
