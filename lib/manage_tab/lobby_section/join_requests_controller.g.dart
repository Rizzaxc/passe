// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'join_requests_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(JoinRequestsController)
final joinRequestsControllerProvider = JoinRequestsControllerFamily._();

final class JoinRequestsControllerProvider
    extends $AsyncNotifierProvider<JoinRequestsController, List<JoinRequest>> {
  JoinRequestsControllerProvider._({
    required JoinRequestsControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'joinRequestsControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$joinRequestsControllerHash();

  @override
  String toString() {
    return r'joinRequestsControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  JoinRequestsController create() => JoinRequestsController();

  @override
  bool operator ==(Object other) {
    return other is JoinRequestsControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$joinRequestsControllerHash() =>
    r'4de0d13ff31cbd012565be37b40632d66f3f19a9';

final class JoinRequestsControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          JoinRequestsController,
          AsyncValue<List<JoinRequest>>,
          List<JoinRequest>,
          FutureOr<List<JoinRequest>>,
          String
        > {
  JoinRequestsControllerFamily._()
    : super(
        retry: null,
        name: r'joinRequestsControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  JoinRequestsControllerProvider call(String lobbyId) =>
      JoinRequestsControllerProvider._(argument: lobbyId, from: this);

  @override
  String toString() => r'joinRequestsControllerProvider';
}

abstract class _$JoinRequestsController
    extends $AsyncNotifier<List<JoinRequest>> {
  late final _$args = ref.$arg as String;
  String get lobbyId => _$args;

  FutureOr<List<JoinRequest>> build(String lobbyId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<JoinRequest>>, List<JoinRequest>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<JoinRequest>>, List<JoinRequest>>,
              AsyncValue<List<JoinRequest>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// Cheap status-only read for the notification card's inline Accept/Reject —
/// avoids pulling the full pending-request list just to know whether this
/// one record still needs a decision. Mirrors `lobbyInviteStatus`.

@ProviderFor(joinRequestStatus)
final joinRequestStatusProvider = JoinRequestStatusFamily._();

/// Cheap status-only read for the notification card's inline Accept/Reject —
/// avoids pulling the full pending-request list just to know whether this
/// one record still needs a decision. Mirrors `lobbyInviteStatus`.

final class JoinRequestStatusProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// Cheap status-only read for the notification card's inline Accept/Reject —
  /// avoids pulling the full pending-request list just to know whether this
  /// one record still needs a decision. Mirrors `lobbyInviteStatus`.
  JoinRequestStatusProvider._({
    required JoinRequestStatusFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'joinRequestStatusProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$joinRequestStatusHash();

  @override
  String toString() {
    return r'joinRequestStatusProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    final argument = this.argument as String;
    return joinRequestStatus(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is JoinRequestStatusProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$joinRequestStatusHash() => r'74249e6e1a22cd6aba71224c3c57a0b8ae412217';

/// Cheap status-only read for the notification card's inline Accept/Reject —
/// avoids pulling the full pending-request list just to know whether this
/// one record still needs a decision. Mirrors `lobbyInviteStatus`.

final class JoinRequestStatusFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String?>, String> {
  JoinRequestStatusFamily._()
    : super(
        retry: null,
        name: r'joinRequestStatusProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Cheap status-only read for the notification card's inline Accept/Reject —
  /// avoids pulling the full pending-request list just to know whether this
  /// one record still needs a decision. Mirrors `lobbyInviteStatus`.

  JoinRequestStatusProvider call(String recordId) =>
      JoinRequestStatusProvider._(argument: recordId, from: this);

  @override
  String toString() => r'joinRequestStatusProvider';
}

/// Accept/decline a lobby join request. Shared by the notification card's
/// inline buttons and [JoinRequestsController] (the "Manage Requests" sheet).
///
/// `keepAlive: true` — nothing ever watches this controller's (trivial void)
/// state, only its `.notifier` for `respond()`, so a plain autoDispose
/// provider gets disposed the instant the `ref.read` call returns (no
/// listeners) — then `respond()`'s own `ref.invalidate(...)` throws after its
/// `await` gap because its own `ref` is already dead. Mirrors
/// `LobbyInviteResponseController`.

@ProviderFor(JoinRequestResponseController)
final joinRequestResponseControllerProvider =
    JoinRequestResponseControllerProvider._();

/// Accept/decline a lobby join request. Shared by the notification card's
/// inline buttons and [JoinRequestsController] (the "Manage Requests" sheet).
///
/// `keepAlive: true` — nothing ever watches this controller's (trivial void)
/// state, only its `.notifier` for `respond()`, so a plain autoDispose
/// provider gets disposed the instant the `ref.read` call returns (no
/// listeners) — then `respond()`'s own `ref.invalidate(...)` throws after its
/// `await` gap because its own `ref` is already dead. Mirrors
/// `LobbyInviteResponseController`.
final class JoinRequestResponseControllerProvider
    extends $NotifierProvider<JoinRequestResponseController, void> {
  /// Accept/decline a lobby join request. Shared by the notification card's
  /// inline buttons and [JoinRequestsController] (the "Manage Requests" sheet).
  ///
  /// `keepAlive: true` — nothing ever watches this controller's (trivial void)
  /// state, only its `.notifier` for `respond()`, so a plain autoDispose
  /// provider gets disposed the instant the `ref.read` call returns (no
  /// listeners) — then `respond()`'s own `ref.invalidate(...)` throws after its
  /// `await` gap because its own `ref` is already dead. Mirrors
  /// `LobbyInviteResponseController`.
  JoinRequestResponseControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'joinRequestResponseControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$joinRequestResponseControllerHash();

  @$internal
  @override
  JoinRequestResponseController create() => JoinRequestResponseController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$joinRequestResponseControllerHash() =>
    r'48f46174c680e8732796ac909990018c5abfccc2';

/// Accept/decline a lobby join request. Shared by the notification card's
/// inline buttons and [JoinRequestsController] (the "Manage Requests" sheet).
///
/// `keepAlive: true` — nothing ever watches this controller's (trivial void)
/// state, only its `.notifier` for `respond()`, so a plain autoDispose
/// provider gets disposed the instant the `ref.read` call returns (no
/// listeners) — then `respond()`'s own `ref.invalidate(...)` throws after its
/// `await` gap because its own `ref` is already dead. Mirrors
/// `LobbyInviteResponseController`.

abstract class _$JoinRequestResponseController extends $Notifier<void> {
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
