// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_at_risk_response_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Cheap status-only read for the notification list row's inline state —
/// mirrors `lobbyInviteStatus`'s pattern (avoid pulling full RSVP counts just
/// to know whether to show action buttons or a resolved hint).

@ProviderFor(activityAtRiskStatus)
final activityAtRiskStatusProvider = ActivityAtRiskStatusFamily._();

/// Cheap status-only read for the notification list row's inline state —
/// mirrors `lobbyInviteStatus`'s pattern (avoid pulling full RSVP counts just
/// to know whether to show action buttons or a resolved hint).

final class ActivityAtRiskStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<ActivityAtRiskStatus>,
          ActivityAtRiskStatus,
          FutureOr<ActivityAtRiskStatus>
        >
    with
        $FutureModifier<ActivityAtRiskStatus>,
        $FutureProvider<ActivityAtRiskStatus> {
  /// Cheap status-only read for the notification list row's inline state —
  /// mirrors `lobbyInviteStatus`'s pattern (avoid pulling full RSVP counts just
  /// to know whether to show action buttons or a resolved hint).
  ActivityAtRiskStatusProvider._({
    required ActivityAtRiskStatusFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'activityAtRiskStatusProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$activityAtRiskStatusHash();

  @override
  String toString() {
    return r'activityAtRiskStatusProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ActivityAtRiskStatus> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ActivityAtRiskStatus> create(Ref ref) {
    final argument = this.argument as String;
    return activityAtRiskStatus(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ActivityAtRiskStatusProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$activityAtRiskStatusHash() =>
    r'c3c680c800e8a65c425e22e84d4fbbd01c599f64';

/// Cheap status-only read for the notification list row's inline state —
/// mirrors `lobbyInviteStatus`'s pattern (avoid pulling full RSVP counts just
/// to know whether to show action buttons or a resolved hint).

final class ActivityAtRiskStatusFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ActivityAtRiskStatus>, String> {
  ActivityAtRiskStatusFamily._()
    : super(
        retry: null,
        name: r'activityAtRiskStatusProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Cheap status-only read for the notification list row's inline state —
  /// mirrors `lobbyInviteStatus`'s pattern (avoid pulling full RSVP counts just
  /// to know whether to show action buttons or a resolved hint).

  ActivityAtRiskStatusProvider call(String activityId) =>
      ActivityAtRiskStatusProvider._(argument: activityId, from: this);

  @override
  String toString() => r'activityAtRiskStatusProvider';
}

/// Resolve an "at risk" activity from the notification card — either side of
/// the two-tier action split (see schema/activity_threshold_enforcement.sql):
/// a maybe/never-responded member committing going/out, or the
/// organizer/coordinator overriding-confirm or cancelling. Both bypass the
/// post-deadline RLS freeze via their own SECURITY DEFINER RPC.
///
/// `keepAlive: true` for the same reason as `LobbyInviteResponseController`
/// — only `.notifier` is read here, no active watcher keeps a plain
/// autoDispose instance alive through the `await` gap.

@ProviderFor(ActivityAtRiskResponseController)
final activityAtRiskResponseControllerProvider =
    ActivityAtRiskResponseControllerProvider._();

/// Resolve an "at risk" activity from the notification card — either side of
/// the two-tier action split (see schema/activity_threshold_enforcement.sql):
/// a maybe/never-responded member committing going/out, or the
/// organizer/coordinator overriding-confirm or cancelling. Both bypass the
/// post-deadline RLS freeze via their own SECURITY DEFINER RPC.
///
/// `keepAlive: true` for the same reason as `LobbyInviteResponseController`
/// — only `.notifier` is read here, no active watcher keeps a plain
/// autoDispose instance alive through the `await` gap.
final class ActivityAtRiskResponseControllerProvider
    extends $NotifierProvider<ActivityAtRiskResponseController, void> {
  /// Resolve an "at risk" activity from the notification card — either side of
  /// the two-tier action split (see schema/activity_threshold_enforcement.sql):
  /// a maybe/never-responded member committing going/out, or the
  /// organizer/coordinator overriding-confirm or cancelling. Both bypass the
  /// post-deadline RLS freeze via their own SECURITY DEFINER RPC.
  ///
  /// `keepAlive: true` for the same reason as `LobbyInviteResponseController`
  /// — only `.notifier` is read here, no active watcher keeps a plain
  /// autoDispose instance alive through the `await` gap.
  ActivityAtRiskResponseControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activityAtRiskResponseControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activityAtRiskResponseControllerHash();

  @$internal
  @override
  ActivityAtRiskResponseController create() =>
      ActivityAtRiskResponseController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$activityAtRiskResponseControllerHash() =>
    r'0eb1290deb124aec44c6c51d2b60f3578b306d12';

/// Resolve an "at risk" activity from the notification card — either side of
/// the two-tier action split (see schema/activity_threshold_enforcement.sql):
/// a maybe/never-responded member committing going/out, or the
/// organizer/coordinator overriding-confirm or cancelling. Both bypass the
/// post-deadline RLS freeze via their own SECURITY DEFINER RPC.
///
/// `keepAlive: true` for the same reason as `LobbyInviteResponseController`
/// — only `.notifier` is read here, no active watcher keeps a plain
/// autoDispose instance alive through the `await` gap.

abstract class _$ActivityAtRiskResponseController extends $Notifier<void> {
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
