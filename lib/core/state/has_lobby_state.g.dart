// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'has_lobby_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the signed-in user belongs to any lobby, in any sport. Read once
/// at cold start by the router to pick the landing tab: a player with no
/// lobby yet has nothing to manage, so they land on Discover ▸ Teammates
/// instead of an empty Manage list. `false` for guests / signed-out.

@ProviderFor(hasAnyLobby)
final hasAnyLobbyProvider = HasAnyLobbyProvider._();

/// Whether the signed-in user belongs to any lobby, in any sport. Read once
/// at cold start by the router to pick the landing tab: a player with no
/// lobby yet has nothing to manage, so they land on Discover ▸ Teammates
/// instead of an empty Manage list. `false` for guests / signed-out.

final class HasAnyLobbyProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether the signed-in user belongs to any lobby, in any sport. Read once
  /// at cold start by the router to pick the landing tab: a player with no
  /// lobby yet has nothing to manage, so they land on Discover ▸ Teammates
  /// instead of an empty Manage list. `false` for guests / signed-out.
  HasAnyLobbyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hasAnyLobbyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hasAnyLobbyHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return hasAnyLobby(ref);
  }
}

String _$hasAnyLobbyHash() => r'c0764bc99f708c292bffdf0d441d2c3814b8d2d7';
