// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lobby_invite_response_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(lobbyInvitePreview)
final lobbyInvitePreviewProvider = LobbyInvitePreviewFamily._();

final class LobbyInvitePreviewProvider
    extends
        $FunctionalProvider<
          AsyncValue<LobbyInvitePreview>,
          LobbyInvitePreview,
          FutureOr<LobbyInvitePreview>
        >
    with
        $FutureModifier<LobbyInvitePreview>,
        $FutureProvider<LobbyInvitePreview> {
  LobbyInvitePreviewProvider._({
    required LobbyInvitePreviewFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'lobbyInvitePreviewProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$lobbyInvitePreviewHash();

  @override
  String toString() {
    return r'lobbyInvitePreviewProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<LobbyInvitePreview> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<LobbyInvitePreview> create(Ref ref) {
    final argument = this.argument as String;
    return lobbyInvitePreview(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LobbyInvitePreviewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$lobbyInvitePreviewHash() =>
    r'2cbf061ab4651e485f78f1e1946dbb49132b2878';

final class LobbyInvitePreviewFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<LobbyInvitePreview>, String> {
  LobbyInvitePreviewFamily._()
    : super(
        retry: null,
        name: r'lobbyInvitePreviewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  LobbyInvitePreviewProvider call(String recordId) =>
      LobbyInvitePreviewProvider._(argument: recordId, from: this);

  @override
  String toString() => r'lobbyInvitePreviewProvider';
}

/// Cheap status-only read for the notification list row's inline state —
/// avoids pulling the full preview (lobby name/sport/captain/…) just to know
/// whether to show Accept/Reject or a resolved hint.

@ProviderFor(lobbyInviteStatus)
final lobbyInviteStatusProvider = LobbyInviteStatusFamily._();

/// Cheap status-only read for the notification list row's inline state —
/// avoids pulling the full preview (lobby name/sport/captain/…) just to know
/// whether to show Accept/Reject or a resolved hint.

final class LobbyInviteStatusProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// Cheap status-only read for the notification list row's inline state —
  /// avoids pulling the full preview (lobby name/sport/captain/…) just to know
  /// whether to show Accept/Reject or a resolved hint.
  LobbyInviteStatusProvider._({
    required LobbyInviteStatusFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'lobbyInviteStatusProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$lobbyInviteStatusHash();

  @override
  String toString() {
    return r'lobbyInviteStatusProvider'
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
    return lobbyInviteStatus(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LobbyInviteStatusProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$lobbyInviteStatusHash() => r'45a0862d95ec6f8448d86b07dbfa5670995e9204';

/// Cheap status-only read for the notification list row's inline state —
/// avoids pulling the full preview (lobby name/sport/captain/…) just to know
/// whether to show Accept/Reject or a resolved hint.

final class LobbyInviteStatusFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String?>, String> {
  LobbyInviteStatusFamily._()
    : super(
        retry: null,
        name: r'lobbyInviteStatusProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Cheap status-only read for the notification list row's inline state —
  /// avoids pulling the full preview (lobby name/sport/captain/…) just to know
  /// whether to show Accept/Reject or a resolved hint.

  LobbyInviteStatusProvider call(String recordId) =>
      LobbyInviteStatusProvider._(argument: recordId, from: this);

  @override
  String toString() => r'lobbyInviteStatusProvider';
}

/// Accept/decline a lobby invite. Shared by the notification card's inline
/// buttons and LobbyInvitePreviewPage — the only two surfaces that respond to
/// an invite (the old Manage▸Lobby mail-icon sheet is retired).
///
/// `keepAlive: true` — nothing ever watches this controller's (trivial void)
/// state, only its `.notifier` for `respond()`, so a plain autoDispose
/// provider gets disposed the instant the `ref.read` call returns (no
/// listeners) — then `respond()`'s own `ref.invalidate(...)` throws after its
/// `await` gap because its own `ref` is already dead.

@ProviderFor(LobbyInviteResponseController)
final lobbyInviteResponseControllerProvider =
    LobbyInviteResponseControllerProvider._();

/// Accept/decline a lobby invite. Shared by the notification card's inline
/// buttons and LobbyInvitePreviewPage — the only two surfaces that respond to
/// an invite (the old Manage▸Lobby mail-icon sheet is retired).
///
/// `keepAlive: true` — nothing ever watches this controller's (trivial void)
/// state, only its `.notifier` for `respond()`, so a plain autoDispose
/// provider gets disposed the instant the `ref.read` call returns (no
/// listeners) — then `respond()`'s own `ref.invalidate(...)` throws after its
/// `await` gap because its own `ref` is already dead.
final class LobbyInviteResponseControllerProvider
    extends $NotifierProvider<LobbyInviteResponseController, void> {
  /// Accept/decline a lobby invite. Shared by the notification card's inline
  /// buttons and LobbyInvitePreviewPage — the only two surfaces that respond to
  /// an invite (the old Manage▸Lobby mail-icon sheet is retired).
  ///
  /// `keepAlive: true` — nothing ever watches this controller's (trivial void)
  /// state, only its `.notifier` for `respond()`, so a plain autoDispose
  /// provider gets disposed the instant the `ref.read` call returns (no
  /// listeners) — then `respond()`'s own `ref.invalidate(...)` throws after its
  /// `await` gap because its own `ref` is already dead.
  LobbyInviteResponseControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lobbyInviteResponseControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lobbyInviteResponseControllerHash();

  @$internal
  @override
  LobbyInviteResponseController create() => LobbyInviteResponseController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$lobbyInviteResponseControllerHash() =>
    r'58efe5ab9eb71c8adde30e3ed7bd72fb79926798';

/// Accept/decline a lobby invite. Shared by the notification card's inline
/// buttons and LobbyInvitePreviewPage — the only two surfaces that respond to
/// an invite (the old Manage▸Lobby mail-icon sheet is retired).
///
/// `keepAlive: true` — nothing ever watches this controller's (trivial void)
/// state, only its `.notifier` for `respond()`, so a plain autoDispose
/// provider gets disposed the instant the `ref.read` call returns (no
/// listeners) — then `respond()`'s own `ref.invalidate(...)` throws after its
/// `await` gap because its own `ref` is already dead.

abstract class _$LobbyInviteResponseController extends $Notifier<void> {
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
