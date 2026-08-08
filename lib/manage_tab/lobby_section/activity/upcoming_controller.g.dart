// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upcoming_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every current/future activity for a lobby, sorted soonest-first. A lobby
/// can legitimately have several live at once (an organic session and a
/// challenge match, several weeks of a recurring series once materialised,
/// …) — each is its own row. Ended rows belong in History; rows without an
/// end time switch to History as soon as their start time passes.

@ProviderFor(LobbyUpcomingActivitiesController)
final lobbyUpcomingActivitiesControllerProvider =
    LobbyUpcomingActivitiesControllerFamily._();

/// Every current/future activity for a lobby, sorted soonest-first. A lobby
/// can legitimately have several live at once (an organic session and a
/// challenge match, several weeks of a recurring series once materialised,
/// …) — each is its own row. Ended rows belong in History; rows without an
/// end time switch to History as soon as their start time passes.
final class LobbyUpcomingActivitiesControllerProvider
    extends
        $AsyncNotifierProvider<
          LobbyUpcomingActivitiesController,
          List<UpcomingActivity>
        > {
  /// Every current/future activity for a lobby, sorted soonest-first. A lobby
  /// can legitimately have several live at once (an organic session and a
  /// challenge match, several weeks of a recurring series once materialised,
  /// …) — each is its own row. Ended rows belong in History; rows without an
  /// end time switch to History as soon as their start time passes.
  LobbyUpcomingActivitiesControllerProvider._({
    required LobbyUpcomingActivitiesControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'lobbyUpcomingActivitiesControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() =>
      _$lobbyUpcomingActivitiesControllerHash();

  @override
  String toString() {
    return r'lobbyUpcomingActivitiesControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  LobbyUpcomingActivitiesController create() =>
      LobbyUpcomingActivitiesController();

  @override
  bool operator ==(Object other) {
    return other is LobbyUpcomingActivitiesControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$lobbyUpcomingActivitiesControllerHash() =>
    r'0282c698029cdc1d33f2fb34dcc7335795bcfc10';

/// Every current/future activity for a lobby, sorted soonest-first. A lobby
/// can legitimately have several live at once (an organic session and a
/// challenge match, several weeks of a recurring series once materialised,
/// …) — each is its own row. Ended rows belong in History; rows without an
/// end time switch to History as soon as their start time passes.

final class LobbyUpcomingActivitiesControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          LobbyUpcomingActivitiesController,
          AsyncValue<List<UpcomingActivity>>,
          List<UpcomingActivity>,
          FutureOr<List<UpcomingActivity>>,
          String
        > {
  LobbyUpcomingActivitiesControllerFamily._()
    : super(
        retry: null,
        name: r'lobbyUpcomingActivitiesControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Every current/future activity for a lobby, sorted soonest-first. A lobby
  /// can legitimately have several live at once (an organic session and a
  /// challenge match, several weeks of a recurring series once materialised,
  /// …) — each is its own row. Ended rows belong in History; rows without an
  /// end time switch to History as soon as their start time passes.

  LobbyUpcomingActivitiesControllerProvider call(String lobbyId) =>
      LobbyUpcomingActivitiesControllerProvider._(
        argument: lobbyId,
        from: this,
      );

  @override
  String toString() => r'lobbyUpcomingActivitiesControllerProvider';
}

/// Every current/future activity for a lobby, sorted soonest-first. A lobby
/// can legitimately have several live at once (an organic session and a
/// challenge match, several weeks of a recurring series once materialised,
/// …) — each is its own row. Ended rows belong in History; rows without an
/// end time switch to History as soon as their start time passes.

abstract class _$LobbyUpcomingActivitiesController
    extends $AsyncNotifier<List<UpcomingActivity>> {
  late final _$args = ref.$arg as String;
  String get lobbyId => _$args;

  FutureOr<List<UpcomingActivity>> build(String lobbyId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<UpcomingActivity>>, List<UpcomingActivity>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<UpcomingActivity>>,
                List<UpcomingActivity>
              >,
              AsyncValue<List<UpcomingActivity>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
