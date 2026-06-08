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
    extends $AsyncNotifierProvider<TeammateFeed, List<LobbyFeedItem>> {
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

String _$teammateFeedHash() => r'd8c78ea049c63cba7f027567f5644a6b16ff1f35';

abstract class _$TeammateFeed extends $AsyncNotifier<List<LobbyFeedItem>> {
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

@ProviderFor(RequestedLobbyIds)
final requestedLobbyIdsProvider = RequestedLobbyIdsProvider._();

final class RequestedLobbyIdsProvider
    extends $NotifierProvider<RequestedLobbyIds, Set<String>> {
  RequestedLobbyIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'requestedLobbyIdsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$requestedLobbyIdsHash();

  @$internal
  @override
  RequestedLobbyIds create() => RequestedLobbyIds();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$requestedLobbyIdsHash() => r'd7f35792279610fe4fdb080c2cf62d8657c05f82';

abstract class _$RequestedLobbyIds extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
