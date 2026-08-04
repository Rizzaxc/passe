// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_center_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The notification centre's list — a read-only history of past
/// `notification_outbox` rows for the current user, most recent first.
/// No pagination for v1 (matches the project's default toward not building
/// for hypothetical future needs); unread rows get a dot in the UI rather
/// than being re-sorted to the top.

@ProviderFor(NotificationCenterController)
final notificationCenterControllerProvider =
    NotificationCenterControllerProvider._();

/// The notification centre's list — a read-only history of past
/// `notification_outbox` rows for the current user, most recent first.
/// No pagination for v1 (matches the project's default toward not building
/// for hypothetical future needs); unread rows get a dot in the UI rather
/// than being re-sorted to the top.
final class NotificationCenterControllerProvider
    extends
        $AsyncNotifierProvider<
          NotificationCenterController,
          List<NotificationItem>
        > {
  /// The notification centre's list — a read-only history of past
  /// `notification_outbox` rows for the current user, most recent first.
  /// No pagination for v1 (matches the project's default toward not building
  /// for hypothetical future needs); unread rows get a dot in the UI rather
  /// than being re-sorted to the top.
  NotificationCenterControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationCenterControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationCenterControllerHash();

  @$internal
  @override
  NotificationCenterController create() => NotificationCenterController();
}

String _$notificationCenterControllerHash() =>
    r'c239ab1d7b76cc52b15059d25ec7f70a72f66c9d';

/// The notification centre's list — a read-only history of past
/// `notification_outbox` rows for the current user, most recent first.
/// No pagination for v1 (matches the project's default toward not building
/// for hypothetical future needs); unread rows get a dot in the UI rather
/// than being re-sorted to the top.

abstract class _$NotificationCenterController
    extends $AsyncNotifier<List<NotificationItem>> {
  FutureOr<List<NotificationItem>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<NotificationItem>>, List<NotificationItem>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<NotificationItem>>,
                List<NotificationItem>
              >,
              AsyncValue<List<NotificationItem>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
