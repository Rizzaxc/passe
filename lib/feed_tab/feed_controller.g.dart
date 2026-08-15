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

/// When the signed-in user last opened the Feed tab on this device — a
/// per-device watermark, not synced across devices (same posture as the đá
/// balance and `HiddenFeedPosts` above). Written *only* from `FeedTab`'s
/// `initState` (see `main.dart`) when the tab is actually opened — never
/// from [feedHasUnread] itself, or checking "is there anything unread" would
/// immediately erase the thing it just found.

@ProviderFor(FeedLastVisitedAt)
final feedLastVisitedAtProvider = FeedLastVisitedAtProvider._();

/// When the signed-in user last opened the Feed tab on this device — a
/// per-device watermark, not synced across devices (same posture as the đá
/// balance and `HiddenFeedPosts` above). Written *only* from `FeedTab`'s
/// `initState` (see `main.dart`) when the tab is actually opened — never
/// from [feedHasUnread] itself, or checking "is there anything unread" would
/// immediately erase the thing it just found.
final class FeedLastVisitedAtProvider
    extends $AsyncNotifierProvider<FeedLastVisitedAt, DateTime?> {
  /// When the signed-in user last opened the Feed tab on this device — a
  /// per-device watermark, not synced across devices (same posture as the đá
  /// balance and `HiddenFeedPosts` above). Written *only* from `FeedTab`'s
  /// `initState` (see `main.dart`) when the tab is actually opened — never
  /// from [feedHasUnread] itself, or checking "is there anything unread" would
  /// immediately erase the thing it just found.
  FeedLastVisitedAtProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'feedLastVisitedAtProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$feedLastVisitedAtHash();

  @$internal
  @override
  FeedLastVisitedAt create() => FeedLastVisitedAt();
}

String _$feedLastVisitedAtHash() => r'9d6095509a6d8c1fda126d650237652d820cb71d';

/// When the signed-in user last opened the Feed tab on this device — a
/// per-device watermark, not synced across devices (same posture as the đá
/// balance and `HiddenFeedPosts` above). Written *only* from `FeedTab`'s
/// `initState` (see `main.dart`) when the tab is actually opened — never
/// from [feedHasUnread] itself, or checking "is there anything unread" would
/// immediately erase the thing it just found.

abstract class _$FeedLastVisitedAt extends $AsyncNotifier<DateTime?> {
  FutureOr<DateTime?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<DateTime?>, DateTime?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<DateTime?>, DateTime?>,
              AsyncValue<DateTime?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Whether the caller has a wall post newer than [FeedLastVisitedAt] from
/// someone other than themselves — drives `router.dart`'s initial-tab pick
/// (guest -> Discover, unread Feed -> Feed, else -> Manage). Not wired to a
/// nav-bar badge or kept live during a session; it's read once at cold start.

@ProviderFor(feedHasUnread)
final feedHasUnreadProvider = FeedHasUnreadProvider._();

/// Whether the caller has a wall post newer than [FeedLastVisitedAt] from
/// someone other than themselves — drives `router.dart`'s initial-tab pick
/// (guest -> Discover, unread Feed -> Feed, else -> Manage). Not wired to a
/// nav-bar badge or kept live during a session; it's read once at cold start.

final class FeedHasUnreadProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether the caller has a wall post newer than [FeedLastVisitedAt] from
  /// someone other than themselves — drives `router.dart`'s initial-tab pick
  /// (guest -> Discover, unread Feed -> Feed, else -> Manage). Not wired to a
  /// nav-bar badge or kept live during a session; it's read once at cold start.
  FeedHasUnreadProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'feedHasUnreadProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$feedHasUnreadHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return feedHasUnread(ref);
  }
}

String _$feedHasUnreadHash() => r'f7dae7a0acf57ffb1b0a8796e8df8838617b4e96';

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
