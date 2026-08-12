// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The Feed's own sport filter — deliberately **not** `selectedSportStateProvider`.
///
/// Every Discover subtab is scoped to the context sport, but a social feed
/// scoped that way would hide a friend's badminton photo while you happen to
/// be in soccer mode. So the Feed defaults to all sports and offers this as an
/// opt-in chip. `null` = every sport.

@ProviderFor(FeedSportFilter)
final feedSportFilterProvider = FeedSportFilterProvider._();

/// The Feed's own sport filter — deliberately **not** `selectedSportStateProvider`.
///
/// Every Discover subtab is scoped to the context sport, but a social feed
/// scoped that way would hide a friend's badminton photo while you happen to
/// be in soccer mode. So the Feed defaults to all sports and offers this as an
/// opt-in chip. `null` = every sport.
final class FeedSportFilterProvider
    extends $NotifierProvider<FeedSportFilter, int?> {
  /// The Feed's own sport filter — deliberately **not** `selectedSportStateProvider`.
  ///
  /// Every Discover subtab is scoped to the context sport, but a social feed
  /// scoped that way would hide a friend's badminton photo while you happen to
  /// be in soccer mode. So the Feed defaults to all sports and offers this as an
  /// opt-in chip. `null` = every sport.
  FeedSportFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'feedSportFilterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$feedSportFilterHash();

  @$internal
  @override
  FeedSportFilter create() => FeedSportFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int?>(value),
    );
  }
}

String _$feedSportFilterHash() => r'd61c45c791629453f1849212ddeb8443fadaf815';

/// The Feed's own sport filter — deliberately **not** `selectedSportStateProvider`.
///
/// Every Discover subtab is scoped to the context sport, but a social feed
/// scoped that way would hide a friend's badminton photo while you happen to
/// be in soccer mode. So the Feed defaults to all sports and offers this as an
/// opt-in chip. `null` = every sport.

abstract class _$FeedSportFilter extends $Notifier<int?> {
  int? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int?, int?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int?, int?>,
              int?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Session-wide "is autoplaying video muted" preference — unmuted by
/// default (video only ever autoplays in the Feed pager, with sound). The
/// mute toggle on a playing video (post_card.dart's `_VideoPage`) flips this,
/// and it carries forward to the next video the user lands on rather than
/// resetting per-video.

@ProviderFor(FeedVideoMuted)
final feedVideoMutedProvider = FeedVideoMutedProvider._();

/// Session-wide "is autoplaying video muted" preference — unmuted by
/// default (video only ever autoplays in the Feed pager, with sound). The
/// mute toggle on a playing video (post_card.dart's `_VideoPage`) flips this,
/// and it carries forward to the next video the user lands on rather than
/// resetting per-video.
final class FeedVideoMutedProvider
    extends $NotifierProvider<FeedVideoMuted, bool> {
  /// Session-wide "is autoplaying video muted" preference — unmuted by
  /// default (video only ever autoplays in the Feed pager, with sound). The
  /// mute toggle on a playing video (post_card.dart's `_VideoPage`) flips this,
  /// and it carries forward to the next video the user lands on rather than
  /// resetting per-video.
  FeedVideoMutedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'feedVideoMutedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$feedVideoMutedHash();

  @$internal
  @override
  FeedVideoMuted create() => FeedVideoMuted();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$feedVideoMutedHash() => r'2778e2b21d51f6a1464a417d96ade0a433e4aa2d';

/// Session-wide "is autoplaying video muted" preference — unmuted by
/// default (video only ever autoplays in the Feed pager, with sound). The
/// mute toggle on a playing video (post_card.dart's `_VideoPage`) flips this,
/// and it carries forward to the next video the user lands on rather than
/// resetting per-video.

abstract class _$FeedVideoMuted extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Post ids the signed-in user chose to hide from the main Feed on this
/// device. This is display state only: it does not mutate the post, affect
/// other users, or hide the same card on lobby/profile surfaces.

@ProviderFor(HiddenFeedPosts)
final hiddenFeedPostsProvider = HiddenFeedPostsProvider._();

/// Post ids the signed-in user chose to hide from the main Feed on this
/// device. This is display state only: it does not mutate the post, affect
/// other users, or hide the same card on lobby/profile surfaces.
final class HiddenFeedPostsProvider
    extends $AsyncNotifierProvider<HiddenFeedPosts, Set<String>> {
  /// Post ids the signed-in user chose to hide from the main Feed on this
  /// device. This is display state only: it does not mutate the post, affect
  /// other users, or hide the same card on lobby/profile surfaces.
  HiddenFeedPostsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hiddenFeedPostsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hiddenFeedPostsHash();

  @$internal
  @override
  HiddenFeedPosts create() => HiddenFeedPosts();
}

String _$hiddenFeedPostsHash() => r'3fd3cc6a2b2f53eb25062c8871b6d3d195c72a96';

/// Post ids the signed-in user chose to hide from the main Feed on this
/// device. This is display state only: it does not mutate the post, affect
/// other users, or hide the same card on lobby/profile surfaces.

abstract class _$HiddenFeedPosts extends $AsyncNotifier<Set<String>> {
  FutureOr<Set<String>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Set<String>>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Set<String>>, Set<String>>,
              AsyncValue<Set<String>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Posts from the caller, their friends, their lobby mates, and any post a
/// friend of theirs is tagged in. Visibility is resolved server-side in
/// `wall_feed_data` — the client never assembles the audience itself.

@ProviderFor(WallFeedController)
final wallFeedControllerProvider = WallFeedControllerProvider._();

/// Posts from the caller, their friends, their lobby mates, and any post a
/// friend of theirs is tagged in. Visibility is resolved server-side in
/// `wall_feed_data` — the client never assembles the audience itself.
final class WallFeedControllerProvider
    extends $AsyncNotifierProvider<WallFeedController, List<WallPost>> {
  /// Posts from the caller, their friends, their lobby mates, and any post a
  /// friend of theirs is tagged in. Visibility is resolved server-side in
  /// `wall_feed_data` — the client never assembles the audience itself.
  WallFeedControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wallFeedControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wallFeedControllerHash();

  @$internal
  @override
  WallFeedController create() => WallFeedController();
}

String _$wallFeedControllerHash() =>
    r'c3bfdbdb074e04d1b7ad5a5ac1d35a905f7990a4';

/// Posts from the caller, their friends, their lobby mates, and any post a
/// friend of theirs is tagged in. Visibility is resolved server-side in
/// `wall_feed_data` — the client never assembles the audience itself.

abstract class _$WallFeedController extends $AsyncNotifier<List<WallPost>> {
  FutureOr<List<WallPost>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<WallPost>>, List<WallPost>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<WallPost>>, List<WallPost>>,
              AsyncValue<List<WallPost>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
