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

String _$teammateFeedHash() => r'456d6aa5553a18218c119180f1995f6b8b035824';

abstract class _$TeammateFeed extends $AsyncNotifier<List<LobbyFeedItem>> {
  FutureOr<List<LobbyFeedItem>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
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
    return element.handleCreate(ref, build);
  }
}

/// Per-lobby, in-session override of the join-request state. The feed row's
/// `alreadyRequested` (from the server) is the baseline; an entry here takes
/// precedence (`true` = just requested, `false` = just undone). `keepAlive` so
/// an optimistic toggle isn't lost if the list briefly stops watching.

@ProviderFor(JoinRequestState)
final joinRequestStateProvider = JoinRequestStateProvider._();

/// Per-lobby, in-session override of the join-request state. The feed row's
/// `alreadyRequested` (from the server) is the baseline; an entry here takes
/// precedence (`true` = just requested, `false` = just undone). `keepAlive` so
/// an optimistic toggle isn't lost if the list briefly stops watching.
final class JoinRequestStateProvider
    extends $NotifierProvider<JoinRequestState, Map<String, bool>> {
  /// Per-lobby, in-session override of the join-request state. The feed row's
  /// `alreadyRequested` (from the server) is the baseline; an entry here takes
  /// precedence (`true` = just requested, `false` = just undone). `keepAlive` so
  /// an optimistic toggle isn't lost if the list briefly stops watching.
  JoinRequestStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'joinRequestStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$joinRequestStateHash();

  @$internal
  @override
  JoinRequestState create() => JoinRequestState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, bool> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, bool>>(value),
    );
  }
}

String _$joinRequestStateHash() => r'fb5f9b67d91ff92ef73218367c66cd7ba0cf5ad9';

/// Per-lobby, in-session override of the join-request state. The feed row's
/// `alreadyRequested` (from the server) is the baseline; an entry here takes
/// precedence (`true` = just requested, `false` = just undone). `keepAlive` so
/// an optimistic toggle isn't lost if the list briefly stops watching.

abstract class _$JoinRequestState extends $Notifier<Map<String, bool>> {
  Map<String, bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Map<String, bool>, Map<String, bool>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, bool>, Map<String, bool>>,
              Map<String, bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
