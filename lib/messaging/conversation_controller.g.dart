// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Live view of one conversation (`schema/messaging.sql` + `messaging_realtime.sql`).
///
/// Realtime delivery is best-effort, so this controller never treats the
/// socket as the source of truth:
///
///   * every `subscribed` transition (the first one *and* every automatic
///     rejoin after a drop) triggers a backfill from the newest message held,
///   * so does an app resume, since a socket killed while backgrounded can
///     rejoin without the SDK noticing a gap,
///   * and `conversation_data` is always the authority — the broadcast payload
///     is a fast path, not a replacement.
///
/// Without that, a dropped socket loses messages silently: the thread simply
/// stops updating and nothing surfaces the gap to the user.

@ProviderFor(ConversationController)
final conversationControllerProvider = ConversationControllerFamily._();

/// Live view of one conversation (`schema/messaging.sql` + `messaging_realtime.sql`).
///
/// Realtime delivery is best-effort, so this controller never treats the
/// socket as the source of truth:
///
///   * every `subscribed` transition (the first one *and* every automatic
///     rejoin after a drop) triggers a backfill from the newest message held,
///   * so does an app resume, since a socket killed while backgrounded can
///     rejoin without the SDK noticing a gap,
///   * and `conversation_data` is always the authority — the broadcast payload
///     is a fast path, not a replacement.
///
/// Without that, a dropped socket loses messages silently: the thread simply
/// stops updating and nothing surfaces the gap to the user.
final class ConversationControllerProvider
    extends
        $AsyncNotifierProvider<ConversationController, ConversationSnapshot> {
  /// Live view of one conversation (`schema/messaging.sql` + `messaging_realtime.sql`).
  ///
  /// Realtime delivery is best-effort, so this controller never treats the
  /// socket as the source of truth:
  ///
  ///   * every `subscribed` transition (the first one *and* every automatic
  ///     rejoin after a drop) triggers a backfill from the newest message held,
  ///   * so does an app resume, since a socket killed while backgrounded can
  ///     rejoin without the SDK noticing a gap,
  ///   * and `conversation_data` is always the authority — the broadcast payload
  ///     is a fast path, not a replacement.
  ///
  /// Without that, a dropped socket loses messages silently: the thread simply
  /// stops updating and nothing surfaces the gap to the user.
  ConversationControllerProvider._({
    required ConversationControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'conversationControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$conversationControllerHash();

  @override
  String toString() {
    return r'conversationControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ConversationController create() => ConversationController();

  @override
  bool operator ==(Object other) {
    return other is ConversationControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$conversationControllerHash() =>
    r'ec42ff071693edee335ba6dbb0b0d4c8b92a8580';

/// Live view of one conversation (`schema/messaging.sql` + `messaging_realtime.sql`).
///
/// Realtime delivery is best-effort, so this controller never treats the
/// socket as the source of truth:
///
///   * every `subscribed` transition (the first one *and* every automatic
///     rejoin after a drop) triggers a backfill from the newest message held,
///   * so does an app resume, since a socket killed while backgrounded can
///     rejoin without the SDK noticing a gap,
///   * and `conversation_data` is always the authority — the broadcast payload
///     is a fast path, not a replacement.
///
/// Without that, a dropped socket loses messages silently: the thread simply
/// stops updating and nothing surfaces the gap to the user.

final class ConversationControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ConversationController,
          AsyncValue<ConversationSnapshot>,
          ConversationSnapshot,
          FutureOr<ConversationSnapshot>,
          String
        > {
  ConversationControllerFamily._()
    : super(
        retry: null,
        name: r'conversationControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Live view of one conversation (`schema/messaging.sql` + `messaging_realtime.sql`).
  ///
  /// Realtime delivery is best-effort, so this controller never treats the
  /// socket as the source of truth:
  ///
  ///   * every `subscribed` transition (the first one *and* every automatic
  ///     rejoin after a drop) triggers a backfill from the newest message held,
  ///   * so does an app resume, since a socket killed while backgrounded can
  ///     rejoin without the SDK noticing a gap,
  ///   * and `conversation_data` is always the authority — the broadcast payload
  ///     is a fast path, not a replacement.
  ///
  /// Without that, a dropped socket loses messages silently: the thread simply
  /// stops updating and nothing surfaces the gap to the user.

  ConversationControllerProvider call(String conversationId) =>
      ConversationControllerProvider._(argument: conversationId, from: this);

  @override
  String toString() => r'conversationControllerProvider';
}

/// Live view of one conversation (`schema/messaging.sql` + `messaging_realtime.sql`).
///
/// Realtime delivery is best-effort, so this controller never treats the
/// socket as the source of truth:
///
///   * every `subscribed` transition (the first one *and* every automatic
///     rejoin after a drop) triggers a backfill from the newest message held,
///   * so does an app resume, since a socket killed while backgrounded can
///     rejoin without the SDK noticing a gap,
///   * and `conversation_data` is always the authority — the broadcast payload
///     is a fast path, not a replacement.
///
/// Without that, a dropped socket loses messages silently: the thread simply
/// stops updating and nothing surfaces the gap to the user.

abstract class _$ConversationController
    extends $AsyncNotifier<ConversationSnapshot> {
  late final _$args = ref.$arg as String;
  String get conversationId => _$args;

  FutureOr<ConversationSnapshot> build(String conversationId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<ConversationSnapshot>, ConversationSnapshot>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<ConversationSnapshot>,
                ConversationSnapshot
              >,
              AsyncValue<ConversationSnapshot>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
