// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_pending_requests_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The user's pending join requests across **every** sport — a request
/// shouldn't vanish from view because the context sport changed. Before this,
/// a sent request only existed as the "Đã gửi" state on a Discover card.
/// Rebuilds when [joinRequestStateProvider] changes, so sending or undoing
/// from Discover shows up here without a manual refresh.

@ProviderFor(myPendingRequests)
final myPendingRequestsProvider = MyPendingRequestsProvider._();

/// The user's pending join requests across **every** sport — a request
/// shouldn't vanish from view because the context sport changed. Before this,
/// a sent request only existed as the "Đã gửi" state on a Discover card.
/// Rebuilds when [joinRequestStateProvider] changes, so sending or undoing
/// from Discover shows up here without a manual refresh.

final class MyPendingRequestsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MyPendingRequest>>,
          List<MyPendingRequest>,
          FutureOr<List<MyPendingRequest>>
        >
    with
        $FutureModifier<List<MyPendingRequest>>,
        $FutureProvider<List<MyPendingRequest>> {
  /// The user's pending join requests across **every** sport — a request
  /// shouldn't vanish from view because the context sport changed. Before this,
  /// a sent request only existed as the "Đã gửi" state on a Discover card.
  /// Rebuilds when [joinRequestStateProvider] changes, so sending or undoing
  /// from Discover shows up here without a manual refresh.
  MyPendingRequestsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myPendingRequestsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myPendingRequestsHash();

  @$internal
  @override
  $FutureProviderElement<List<MyPendingRequest>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MyPendingRequest>> create(Ref ref) {
    return myPendingRequests(ref);
  }
}

String _$myPendingRequestsHash() => r'd8c1846f73a5adb5894ad07f6037f4f1a8da6bce';
