// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friendship_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The caller's friends plus every open request, in one round trip
/// (`friend_data` RPC). Everything else in this file mutates through the
/// SECURITY DEFINER RPCs and then invalidates this.

@ProviderFor(FriendshipController)
final friendshipControllerProvider = FriendshipControllerProvider._();

/// The caller's friends plus every open request, in one round trip
/// (`friend_data` RPC). Everything else in this file mutates through the
/// SECURITY DEFINER RPCs and then invalidates this.
final class FriendshipControllerProvider
    extends $AsyncNotifierProvider<FriendshipController, List<FriendUser>> {
  /// The caller's friends plus every open request, in one round trip
  /// (`friend_data` RPC). Everything else in this file mutates through the
  /// SECURITY DEFINER RPCs and then invalidates this.
  FriendshipControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'friendshipControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$friendshipControllerHash();

  @$internal
  @override
  FriendshipController create() => FriendshipController();
}

String _$friendshipControllerHash() =>
    r'e9a6231284bd86475ae323be7fc9ba4e0fadedfa';

/// The caller's friends plus every open request, in one round trip
/// (`friend_data` RPC). Everything else in this file mutates through the
/// SECURITY DEFINER RPCs and then invalidates this.

abstract class _$FriendshipController extends $AsyncNotifier<List<FriendUser>> {
  FutureOr<List<FriendUser>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<FriendUser>>, List<FriendUser>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<FriendUser>>, List<FriendUser>>,
              AsyncValue<List<FriendUser>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Accepted friends only.

@ProviderFor(friends)
final friendsProvider = FriendsProvider._();

/// Accepted friends only.

final class FriendsProvider
    extends
        $FunctionalProvider<
          List<FriendUser>,
          List<FriendUser>,
          List<FriendUser>
        >
    with $Provider<List<FriendUser>> {
  /// Accepted friends only.
  FriendsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'friendsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$friendsHash();

  @$internal
  @override
  $ProviderElement<List<FriendUser>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<FriendUser> create(Ref ref) {
    return friends(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<FriendUser> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<FriendUser>>(value),
    );
  }
}

String _$friendsHash() => r'a66ade9e13161227a7244614109a03fadacd4094';

/// Requests waiting on the caller — drives the badge on the friends entry.

@ProviderFor(incomingFriendRequests)
final incomingFriendRequestsProvider = IncomingFriendRequestsProvider._();

/// Requests waiting on the caller — drives the badge on the friends entry.

final class IncomingFriendRequestsProvider
    extends
        $FunctionalProvider<
          List<FriendUser>,
          List<FriendUser>,
          List<FriendUser>
        >
    with $Provider<List<FriendUser>> {
  /// Requests waiting on the caller — drives the badge on the friends entry.
  IncomingFriendRequestsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'incomingFriendRequestsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$incomingFriendRequestsHash();

  @$internal
  @override
  $ProviderElement<List<FriendUser>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<FriendUser> create(Ref ref) {
    return incomingFriendRequests(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<FriendUser> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<FriendUser>>(value),
    );
  }
}

String _$incomingFriendRequestsHash() =>
    r'7edcb03c7900709456014766967a5799daf6d842';
