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
    r'46720af9a4ec7ee71422fc74e700da149958db39';

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

/// One person's wall. `tagged: false` = posts they wrote, `true` = posts
/// they're tagged in. Both are filtered server-side by the same visibility
/// predicate, so a visitor simply sees a shorter list.

@ProviderFor(userWall)
final userWallProvider = UserWallFamily._();

/// One person's wall. `tagged: false` = posts they wrote, `true` = posts
/// they're tagged in. Both are filtered server-side by the same visibility
/// predicate, so a visitor simply sees a shorter list.

final class UserWallProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WallPost>>,
          List<WallPost>,
          FutureOr<List<WallPost>>
        >
    with $FutureModifier<List<WallPost>>, $FutureProvider<List<WallPost>> {
  /// One person's wall. `tagged: false` = posts they wrote, `true` = posts
  /// they're tagged in. Both are filtered server-side by the same visibility
  /// predicate, so a visitor simply sees a shorter list.
  UserWallProvider._({
    required UserWallFamily super.from,
    required (String, {bool tagged}) super.argument,
  }) : super(
         retry: null,
         name: r'userWallProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$userWallHash();

  @override
  String toString() {
    return r'userWallProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<WallPost>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<WallPost>> create(Ref ref) {
    final argument = this.argument as (String, {bool tagged});
    return userWall(ref, argument.$1, tagged: argument.tagged);
  }

  @override
  bool operator ==(Object other) {
    return other is UserWallProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userWallHash() => r'198afba387e02196fb966480ed711134fa5d60fd';

/// One person's wall. `tagged: false` = posts they wrote, `true` = posts
/// they're tagged in. Both are filtered server-side by the same visibility
/// predicate, so a visitor simply sees a shorter list.

final class UserWallFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<WallPost>>,
          (String, {bool tagged})
        > {
  UserWallFamily._()
    : super(
        retry: null,
        name: r'userWallProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One person's wall. `tagged: false` = posts they wrote, `true` = posts
  /// they're tagged in. Both are filtered server-side by the same visibility
  /// predicate, so a visitor simply sees a shorter list.

  UserWallProvider call(String userId, {bool tagged = false}) =>
      UserWallProvider._(argument: (userId, tagged: tagged), from: this);

  @override
  String toString() => r'userWallProvider';
}
