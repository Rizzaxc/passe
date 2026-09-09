// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'freeplay_expose_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(lobbyExposureContext)
final lobbyExposureContextProvider = LobbyExposureContextFamily._();

final class LobbyExposureContextProvider
    extends
        $FunctionalProvider<
          AsyncValue<LobbyExposureContext>,
          LobbyExposureContext,
          FutureOr<LobbyExposureContext>
        >
    with
        $FutureModifier<LobbyExposureContext>,
        $FutureProvider<LobbyExposureContext> {
  LobbyExposureContextProvider._({
    required LobbyExposureContextFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'lobbyExposureContextProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$lobbyExposureContextHash();

  @override
  String toString() {
    return r'lobbyExposureContextProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<LobbyExposureContext> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<LobbyExposureContext> create(Ref ref) {
    final argument = this.argument as String;
    return lobbyExposureContext(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LobbyExposureContextProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$lobbyExposureContextHash() =>
    r'27908202184b2a29bdebd32cb6caf6edfca376e0';

final class LobbyExposureContextFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<LobbyExposureContext>, String> {
  LobbyExposureContextFamily._()
    : super(
        retry: null,
        name: r'lobbyExposureContextProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  LobbyExposureContextProvider call(String lobbyId) =>
      LobbyExposureContextProvider._(argument: lobbyId, from: this);

  @override
  String toString() => r'lobbyExposureContextProvider';
}

/// Whether the lobby currently advertises seats on the freeplay feed.
///
/// A lobby with a live listing cannot be made private — the server raises
/// `lobby_private_blocked_by_freeplay` rather than stranding outsiders who
/// already hold a seat. This is the client mirror, so the option is refused
/// with an explanation instead of a generic save failure.

@ProviderFor(lobbyHasLiveFreeplay)
final lobbyHasLiveFreeplayProvider = LobbyHasLiveFreeplayFamily._();

/// Whether the lobby currently advertises seats on the freeplay feed.
///
/// A lobby with a live listing cannot be made private — the server raises
/// `lobby_private_blocked_by_freeplay` rather than stranding outsiders who
/// already hold a seat. This is the client mirror, so the option is refused
/// with an explanation instead of a generic save failure.

final class LobbyHasLiveFreeplayProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether the lobby currently advertises seats on the freeplay feed.
  ///
  /// A lobby with a live listing cannot be made private — the server raises
  /// `lobby_private_blocked_by_freeplay` rather than stranding outsiders who
  /// already hold a seat. This is the client mirror, so the option is refused
  /// with an explanation instead of a generic save failure.
  LobbyHasLiveFreeplayProvider._({
    required LobbyHasLiveFreeplayFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'lobbyHasLiveFreeplayProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$lobbyHasLiveFreeplayHash();

  @override
  String toString() {
    return r'lobbyHasLiveFreeplayProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as String;
    return lobbyHasLiveFreeplay(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LobbyHasLiveFreeplayProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$lobbyHasLiveFreeplayHash() =>
    r'd363a89f764da05bb44d1e8f895a69f32424dd78';

/// Whether the lobby currently advertises seats on the freeplay feed.
///
/// A lobby with a live listing cannot be made private — the server raises
/// `lobby_private_blocked_by_freeplay` rather than stranding outsiders who
/// already hold a seat. This is the client mirror, so the option is refused
/// with an explanation instead of a generic save failure.

final class LobbyHasLiveFreeplayFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<bool>, String> {
  LobbyHasLiveFreeplayFamily._()
    : super(
        retry: null,
        name: r'lobbyHasLiveFreeplayProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Whether the lobby currently advertises seats on the freeplay feed.
  ///
  /// A lobby with a live listing cannot be made private — the server raises
  /// `lobby_private_blocked_by_freeplay` rather than stranding outsiders who
  /// already hold a seat. This is the client mirror, so the option is refused
  /// with an explanation instead of a generic save failure.

  LobbyHasLiveFreeplayProvider call(String lobbyId) =>
      LobbyHasLiveFreeplayProvider._(argument: lobbyId, from: this);

  @override
  String toString() => r'lobbyHasLiveFreeplayProvider';
}
