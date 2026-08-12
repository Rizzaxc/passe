// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_unread_count_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Count-only query so every appbar bell shares one cheap provider instead of
/// each pulling the full notification list.

@ProviderFor(notificationUnreadCount)
final notificationUnreadCountProvider = NotificationUnreadCountProvider._();

/// Count-only query so every appbar bell shares one cheap provider instead of
/// each pulling the full notification list.

final class NotificationUnreadCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Count-only query so every appbar bell shares one cheap provider instead of
  /// each pulling the full notification list.
  NotificationUnreadCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationUnreadCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationUnreadCountHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return notificationUnreadCount(ref);
  }
}

String _$notificationUnreadCountHash() =>
    r'133df29e4bdf99944f4daa669802379bb80b498d';
