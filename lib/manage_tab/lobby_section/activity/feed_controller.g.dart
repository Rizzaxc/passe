// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LobbyFeedController)
final lobbyFeedControllerProvider = LobbyFeedControllerFamily._();

final class LobbyFeedControllerProvider
    extends $AsyncNotifierProvider<LobbyFeedController, List<FeedItem>> {
  LobbyFeedControllerProvider._({
    required LobbyFeedControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'lobbyFeedControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$lobbyFeedControllerHash();

  @override
  String toString() {
    return r'lobbyFeedControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  LobbyFeedController create() => LobbyFeedController();

  @override
  bool operator ==(Object other) {
    return other is LobbyFeedControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$lobbyFeedControllerHash() => r'feed-controller-hand-rolled';

final class LobbyFeedControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          LobbyFeedController,
          AsyncValue<List<FeedItem>>,
          List<FeedItem>,
          FutureOr<List<FeedItem>>,
          String
        > {
  LobbyFeedControllerFamily._()
    : super(
        retry: null,
        name: r'lobbyFeedControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  LobbyFeedControllerProvider call(String lobbyId) =>
      LobbyFeedControllerProvider._(argument: lobbyId, from: this);

  @override
  String toString() => r'lobbyFeedControllerProvider';
}

abstract class _$LobbyFeedController extends $AsyncNotifier<List<FeedItem>> {
  late final _$args = ref.$arg as String;
  String get lobbyId => _$args;

  FutureOr<List<FeedItem>> build(String lobbyId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<FeedItem>>, List<FeedItem>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<FeedItem>>, List<FeedItem>>,
              AsyncValue<List<FeedItem>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
