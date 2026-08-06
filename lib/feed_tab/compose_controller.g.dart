// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compose_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Sessions the caller may hook a post to: lobby activities from the last 7
/// days they RSVP'd `going` to, plus their coach lessons in the same window.
/// Comes straight from `postable_activities()` so the picker can never offer
/// something `create_wall_post` would then reject.

@ProviderFor(postableSessions)
final postableSessionsProvider = PostableSessionsProvider._();

/// Sessions the caller may hook a post to: lobby activities from the last 7
/// days they RSVP'd `going` to, plus their coach lessons in the same window.
/// Comes straight from `postable_activities()` so the picker can never offer
/// something `create_wall_post` would then reject.

final class PostableSessionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PostableSession>>,
          List<PostableSession>,
          FutureOr<List<PostableSession>>
        >
    with
        $FutureModifier<List<PostableSession>>,
        $FutureProvider<List<PostableSession>> {
  /// Sessions the caller may hook a post to: lobby activities from the last 7
  /// days they RSVP'd `going` to, plus their coach lessons in the same window.
  /// Comes straight from `postable_activities()` so the picker can never offer
  /// something `create_wall_post` would then reject.
  PostableSessionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'postableSessionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$postableSessionsHash();

  @$internal
  @override
  $FutureProviderElement<List<PostableSession>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PostableSession>> create(Ref ref) {
    return postableSessions(ref);
  }
}

String _$postableSessionsHash() => r'bc11c0226c2465cf46b5f4c5cc1b6c1236aa012c';

@ProviderFor(taggableUsers)
final taggableUsersProvider = TaggableUsersFamily._();

final class TaggableUsersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TaggableUser>>,
          List<TaggableUser>,
          FutureOr<List<TaggableUser>>
        >
    with
        $FutureModifier<List<TaggableUser>>,
        $FutureProvider<List<TaggableUser>> {
  TaggableUsersProvider._({
    required TaggableUsersFamily super.from,
    required ({String? activityId, String? bookingId}) super.argument,
  }) : super(
         retry: null,
         name: r'taggableUsersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$taggableUsersHash();

  @override
  String toString() {
    return r'taggableUsersProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<TaggableUser>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TaggableUser>> create(Ref ref) {
    final argument = this.argument as ({String? activityId, String? bookingId});
    return taggableUsers(
      ref,
      activityId: argument.activityId,
      bookingId: argument.bookingId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TaggableUsersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$taggableUsersHash() => r'02fc3f46ca762025c5e67a64b15a7a1ba76ae34a';

final class TaggableUsersFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<TaggableUser>>,
          ({String? activityId, String? bookingId})
        > {
  TaggableUsersFamily._()
    : super(
        retry: null,
        name: r'taggableUsersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TaggableUsersProvider call({String? activityId, String? bookingId}) =>
      TaggableUsersProvider._(
        argument: (activityId: activityId, bookingId: bookingId),
        from: this,
      );

  @override
  String toString() => r'taggableUsersProvider';
}

/// Uploads the picked media, then creates the post.
///
/// Images (and video thumbnails) go to `<uid>/<random>.jpg` in the public
/// `wall_post` bucket; video goes to `<uid>/<random>.<ext>` in
/// `wall_post_video` (see schema/wall_post_video.sql for why they're split).
/// Paths are user-scoped rather than post-scoped because the upload happens
/// *before* the post row exists, and the storage policy can only check the
/// first path segment against `auth.uid()`.

@ProviderFor(ComposePostController)
final composePostControllerProvider = ComposePostControllerProvider._();

/// Uploads the picked media, then creates the post.
///
/// Images (and video thumbnails) go to `<uid>/<random>.jpg` in the public
/// `wall_post` bucket; video goes to `<uid>/<random>.<ext>` in
/// `wall_post_video` (see schema/wall_post_video.sql for why they're split).
/// Paths are user-scoped rather than post-scoped because the upload happens
/// *before* the post row exists, and the storage policy can only check the
/// first path segment against `auth.uid()`.
final class ComposePostControllerProvider
    extends $NotifierProvider<ComposePostController, void> {
  /// Uploads the picked media, then creates the post.
  ///
  /// Images (and video thumbnails) go to `<uid>/<random>.jpg` in the public
  /// `wall_post` bucket; video goes to `<uid>/<random>.<ext>` in
  /// `wall_post_video` (see schema/wall_post_video.sql for why they're split).
  /// Paths are user-scoped rather than post-scoped because the upload happens
  /// *before* the post row exists, and the storage policy can only check the
  /// first path segment against `auth.uid()`.
  ComposePostControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'composePostControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$composePostControllerHash();

  @$internal
  @override
  ComposePostController create() => ComposePostController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$composePostControllerHash() =>
    r'3e0954f5063a995b7e94abfb10ada09e22f72bec';

/// Uploads the picked media, then creates the post.
///
/// Images (and video thumbnails) go to `<uid>/<random>.jpg` in the public
/// `wall_post` bucket; video goes to `<uid>/<random>.<ext>` in
/// `wall_post_video` (see schema/wall_post_video.sql for why they're split).
/// Paths are user-scoped rather than post-scoped because the upload happens
/// *before* the post row exists, and the storage policy can only check the
/// first path segment against `auth.uid()`.

abstract class _$ComposePostController extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
