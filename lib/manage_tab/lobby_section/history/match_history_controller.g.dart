// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_history_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Lobby history combines recorded matches with completed activities that do
/// not have a match record yet. The latter retain their post-session actions
/// without being incorrectly counted as competitive results.
///
/// Match details come from `lobby_match_history_data`; completed activities
/// use the member-visible `activity` rows. A matching `activity_id` is
/// de-duplicated in the client because challenge matches already render their
/// richer match record.

@ProviderFor(LobbyMatchHistoryController)
final lobbyMatchHistoryControllerProvider =
    LobbyMatchHistoryControllerFamily._();

/// Lobby history combines recorded matches with completed activities that do
/// not have a match record yet. The latter retain their post-session actions
/// without being incorrectly counted as competitive results.
///
/// Match details come from `lobby_match_history_data`; completed activities
/// use the member-visible `activity` rows. A matching `activity_id` is
/// de-duplicated in the client because challenge matches already render their
/// richer match record.
final class LobbyMatchHistoryControllerProvider
    extends $AsyncNotifierProvider<LobbyMatchHistoryController, LobbyHistory> {
  /// Lobby history combines recorded matches with completed activities that do
  /// not have a match record yet. The latter retain their post-session actions
  /// without being incorrectly counted as competitive results.
  ///
  /// Match details come from `lobby_match_history_data`; completed activities
  /// use the member-visible `activity` rows. A matching `activity_id` is
  /// de-duplicated in the client because challenge matches already render their
  /// richer match record.
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
    r'4e5e9ec60cbd85af364323f88e49c2e1e4c4d23c';

/// Lobby history combines recorded matches with completed activities that do
/// not have a match record yet. The latter retain their post-session actions
/// without being incorrectly counted as competitive results.
///
/// Match details come from `lobby_match_history_data`; completed activities
/// use the member-visible `activity` rows. A matching `activity_id` is
/// de-duplicated in the client because challenge matches already render their
/// richer match record.

final class LobbyMatchHistoryControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          LobbyMatchHistoryController,
          AsyncValue<LobbyHistory>,
          LobbyHistory,
          FutureOr<LobbyHistory>,
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

  /// Lobby history combines recorded matches with completed activities that do
  /// not have a match record yet. The latter retain their post-session actions
  /// without being incorrectly counted as competitive results.
  ///
  /// Match details come from `lobby_match_history_data`; completed activities
  /// use the member-visible `activity` rows. A matching `activity_id` is
  /// de-duplicated in the client because challenge matches already render their
  /// richer match record.

  LobbyMatchHistoryControllerProvider call(String lobbyId) =>
      LobbyMatchHistoryControllerProvider._(argument: lobbyId, from: this);

  @override
  String toString() => r'lobbyMatchHistoryControllerProvider';
}

/// Lobby history combines recorded matches with completed activities that do
/// not have a match record yet. The latter retain their post-session actions
/// without being incorrectly counted as competitive results.
///
/// Match details come from `lobby_match_history_data`; completed activities
/// use the member-visible `activity` rows. A matching `activity_id` is
/// de-duplicated in the client because challenge matches already render their
/// richer match record.

abstract class _$LobbyMatchHistoryController
    extends $AsyncNotifier<LobbyHistory> {
  late final _$args = ref.$arg as String;
  String get lobbyId => _$args;

  FutureOr<LobbyHistory> build(String lobbyId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<LobbyHistory>, LobbyHistory>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<LobbyHistory>, LobbyHistory>,
              AsyncValue<LobbyHistory>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
