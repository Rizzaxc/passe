// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide push singleton. Eagerly instantiated (keepAlive) so its FCM
/// listeners and the auth-driven token lifecycle live for the whole session.

@ProviderFor(notificationService)
final notificationServiceProvider = NotificationServiceProvider._();

/// App-wide push singleton. Eagerly instantiated (keepAlive) so its FCM
/// listeners and the auth-driven token lifecycle live for the whole session.

final class NotificationServiceProvider
    extends
        $FunctionalProvider<
          NotificationService,
          NotificationService,
          NotificationService
        >
    with $Provider<NotificationService> {
  /// App-wide push singleton. Eagerly instantiated (keepAlive) so its FCM
  /// listeners and the auth-driven token lifecycle live for the whole session.
  NotificationServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationServiceHash();

  @$internal
  @override
  $ProviderElement<NotificationService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NotificationService create(Ref ref) {
    return notificationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationService>(value),
    );
  }
}

String _$notificationServiceHash() =>
    r'3b2f1f9ad2164f8acdb33565398de4b9fc935ebf';
