// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lobby_public_preview_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The public preview for one lobby, fetched on demand (family, keyed by
/// lobby id) rather than watched against the shared filter — this is opened
/// per-tap, not part of a feed. Works unauthenticated: `get_lobby_public_preview`
/// is `anon`-granted so guests can open it straight from Discover.

@ProviderFor(lobbyPublicPreview)
final lobbyPublicPreviewProvider = LobbyPublicPreviewFamily._();

/// The public preview for one lobby, fetched on demand (family, keyed by
/// lobby id) rather than watched against the shared filter — this is opened
/// per-tap, not part of a feed. Works unauthenticated: `get_lobby_public_preview`
/// is `anon`-granted so guests can open it straight from Discover.

final class LobbyPublicPreviewProvider
    extends
        $FunctionalProvider<
          AsyncValue<LobbyPublicPreview?>,
          LobbyPublicPreview?,
          FutureOr<LobbyPublicPreview?>
        >
    with
        $FutureModifier<LobbyPublicPreview?>,
        $FutureProvider<LobbyPublicPreview?> {
  /// The public preview for one lobby, fetched on demand (family, keyed by
  /// lobby id) rather than watched against the shared filter — this is opened
  /// per-tap, not part of a feed. Works unauthenticated: `get_lobby_public_preview`
  /// is `anon`-granted so guests can open it straight from Discover.
  LobbyPublicPreviewProvider._({
    required LobbyPublicPreviewFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'lobbyPublicPreviewProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$lobbyPublicPreviewHash();

  @override
  String toString() {
    return r'lobbyPublicPreviewProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<LobbyPublicPreview?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<LobbyPublicPreview?> create(Ref ref) {
    final argument = this.argument as String;
    return lobbyPublicPreview(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LobbyPublicPreviewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$lobbyPublicPreviewHash() =>
    r'0db9636a340f5b50cb6beade32d7ac5d6bacb21d';

/// The public preview for one lobby, fetched on demand (family, keyed by
/// lobby id) rather than watched against the shared filter — this is opened
/// per-tap, not part of a feed. Works unauthenticated: `get_lobby_public_preview`
/// is `anon`-granted so guests can open it straight from Discover.

final class LobbyPublicPreviewFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<LobbyPublicPreview?>, String> {
  LobbyPublicPreviewFamily._()
    : super(
        retry: null,
        name: r'lobbyPublicPreviewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The public preview for one lobby, fetched on demand (family, keyed by
  /// lobby id) rather than watched against the shared filter — this is opened
  /// per-tap, not part of a feed. Works unauthenticated: `get_lobby_public_preview`
  /// is `anon`-granted so guests can open it straight from Discover.

  LobbyPublicPreviewProvider call(String lobbyId) =>
      LobbyPublicPreviewProvider._(argument: lobbyId, from: this);

  @override
  String toString() => r'lobbyPublicPreviewProvider';
}
