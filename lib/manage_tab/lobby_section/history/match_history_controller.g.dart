// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_history_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Played-match history for a lobby — wins, losses, practice sessions.
///
/// Backed by `lobby_match` via the `lobby_match_history_data` RPC,
/// which resolves the opponent lobby name, MVP username and current
/// member usernames in one round-trip.

@ProviderFor(LobbyMatchHistoryController)
final lobbyMatchHistoryControllerProvider =
    LobbyMatchHistoryControllerFamily._();

/// Played-match history for a lobby — wins, losses, practice sessions.
///
/// Backed by `lobby_match` via the `lobby_match_history_data` RPC,
/// which resolves the opponent lobby name, MVP username and current
/// member usernames in one round-trip.
final class LobbyMatchHistoryControllerProvider
    extends
        $AsyncNotifierProvider<LobbyMatchHistoryController, List<LobbyMatch>> {
  /// Played-match history for a lobby — wins, losses, practice sessions.
  ///
  /// Backed by `lobby_match` via the `lobby_match_history_data` RPC,
  /// which resolves the opponent lobby name, MVP username and current
  /// member usernames in one round-trip.
  LobbyMatchHistoryControllerProvider._({
    required LobbyMatchHistoryControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'lobbyMatchHistoryControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$lobbyMatchHistoryControllerHash();

  @override
  String toString() {
    return r'lobbyMatchHistoryControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  LobbyMatchHistoryController create() => LobbyMatchHistoryController();

  @override
  bool operator ==(Object other) {
    return other is LobbyMatchHistoryControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$lobbyMatchHistoryControllerHash() =>
    r'13c236a7993a9cc4a12c67bba1f5586ed7cfdd13';

/// Played-match history for a lobby — wins, losses, practice sessions.
///
/// Backed by `lobby_match` via the `lobby_match_history_data` RPC,
/// which resolves the opponent lobby name, MVP username and current
/// member usernames in one round-trip.

final class LobbyMatchHistoryControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          LobbyMatchHistoryController,
          AsyncValue<List<LobbyMatch>>,
          List<LobbyMatch>,
          FutureOr<List<LobbyMatch>>,
          String
        > {
  LobbyMatchHistoryControllerFamily._()
    : super(
        retry: null,
        name: r'lobbyMatchHistoryControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Played-match history for a lobby — wins, losses, practice sessions.
  ///
  /// Backed by `lobby_match` via the `lobby_match_history_data` RPC,
  /// which resolves the opponent lobby name, MVP username and current
  /// member usernames in one round-trip.

  LobbyMatchHistoryControllerProvider call(String lobbyId) =>
      LobbyMatchHistoryControllerProvider._(argument: lobbyId, from: this);

  @override
  String toString() => r'lobbyMatchHistoryControllerProvider';
}

/// Played-match history for a lobby — wins, losses, practice sessions.
///
/// Backed by `lobby_match` via the `lobby_match_history_data` RPC,
/// which resolves the opponent lobby name, MVP username and current
/// member usernames in one round-trip.

abstract class _$LobbyMatchHistoryController
    extends $AsyncNotifier<List<LobbyMatch>> {
  late final _$args = ref.$arg as String;
  String get lobbyId => _$args;

  FutureOr<List<LobbyMatch>> build(String lobbyId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<LobbyMatch>>, List<LobbyMatch>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<LobbyMatch>>, List<LobbyMatch>>,
              AsyncValue<List<LobbyMatch>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
