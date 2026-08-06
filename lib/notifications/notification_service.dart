import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../auth/auth_controller.dart';
import '../notification/notification_center_controller.dart';
import '../notification/notification_unread_count_controller.dart';
import '../router.dart';
import '../ui/main.dart';
import 'notification_router.dart';

part 'notification_service.g.dart';

/// Background isolate handler. The server sends a `notification`+`data` message,
/// so the OS renders the banner itself when the app is backgrounded/terminated —
/// there is nothing to do here but exist (FCM requires a registered handler).
/// Must be a top-level / static function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// Android foreground-display channel. iOS shows foreground banners via
/// [FirebaseMessaging.setForegroundNotificationPresentationOptions] instead.
const _androidChannel = AndroidNotificationChannel(
  'passe_default',
  'Thông báo Passe',
  description: 'Thông báo về hoạt động, challenge và lịch tập',
  importance: Importance.high,
);

/// App-wide push singleton. Eagerly instantiated (keepAlive) so its FCM
/// listeners and the auth-driven token lifecycle live for the whole session.
@Riverpod(keepAlive: true)
NotificationService notificationService(Ref ref) {
  final service = NotificationService(ref);
  service.init();
  return service;
}

class NotificationService with WidgetsBindingObserver {
  NotificationService(this._ref);

  final Ref _ref;
  final _talker = Talker();
  final _messaging = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();
  SupabaseClient get _supabase => Supabase.instance.client;

  bool _started = false;

  String get _platform => Platform.isIOS ? 'ios' : 'android';

  /// Wire FCM listeners, foreground display, tap routing, and the auth-driven
  /// token lifecycle. Idempotent.
  Future<void> init() async {
    if (_started) return;
    _started = true;

    try {
      // Foreground local-notification plugin (Android renders these; on iOS the
      // OS draws the banner from the notification block via the option below).
      await _local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload == null) return;
          _routeTap(jsonDecode(payload) as Map<String, dynamic>);
        },
      );
      await _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_androidChannel);

      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Foreground messages: Android isn't auto-displayed, so draw it ourselves.
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      // Tap on an OS-drawn banner that brought the app to the foreground.
      FirebaseMessaging.onMessageOpenedApp.listen(
        (m) => _routeTap(m.data),
      );
      // Cold start: the app was launched by tapping a notification.
      final initial = await _messaging.getInitialMessage();
      if (initial != null) {
        // Defer until the first frame so the router is mounted.
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _routeTap(initial.data),
        );
      }

      // Token rotation: re-register whenever FCM issues a new token.
      _messaging.onTokenRefresh.listen((_) => _registerIfPermitted());

      // Auth lifecycle: register on sign-in (if already permitted), drop the
      // device row on sign-out so the previous user goes silent on this device.
      _ref.listen<AsyncValue<dynamic>>(authControllerProvider, (prev, next) {
        final wasSignedIn = prev?.value != null;
        final isSignedIn = next.value != null;
        if (isSignedIn && !wasSignedIn) {
          _registerIfPermitted();
        } else if (!isSignedIn && wasSignedIn) {
          unawaited(unregister());
        }
      });

      // Already-authed warm start with permission previously granted.
      await _registerIfPermitted();

      // Coming back to the foreground (app switch, lock screen) is the other
      // common way the bell/badge goes stale: a notification can land while
      // this device was merely backgrounded (push delivered, but nothing here
      // was running to react to it), not just while fully closed. Refresh on
      // every resume rather than only reacting to a live FCM message.
      WidgetsBinding.instance.addObserver(this);
      _ref.onDispose(() => WidgetsBinding.instance.removeObserver(this));
    } catch (e, st) {
      _talker.handle(e, st, 'notification init failed');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _ref.invalidate(notificationUnreadCountProvider);
    _ref.invalidate(notificationCenterControllerProvider);
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    // A notification arrived while the app is open — refresh the bell badge
    // and the notification-centre list live rather than waiting for the next
    // screen visit, on both platforms.
    _ref.invalidate(notificationUnreadCountProvider);
    _ref.invalidate(notificationCenterControllerProvider);
    // The OS foreground presentation (iOS) / a manually-drawn tray entry
    // (Android, below) can be easy to miss while eyes are already on the
    // screen — this in-app toast is the reliable, always-visible cue, and is
    // tappable straight into the same destination a push tap would open.
    _showInAppToast(message);

    // iOS already draws the banner (presentation options); only Android needs us.
    if (Platform.isIOS) return;
    await _local.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _showInAppToast(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    final router = _ref.read(routerProvider);
    final context = router.routerDelegate.navigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    late final FToasterEntry entry;
    entry = showFToast(
      context: context,
      icon: const Icon(FLucideIcons.bell),
      alignment: .topCenter,
      title: GestureDetector(
        onTap: () {
          entry.dismiss();
          _routeTap(message.data);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: 2,
          children: [
            Text(
              notification.title ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (notification.body case final body?)
              Text(body, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  void _routeTap(Map<String, dynamic> data) {
    try {
      routeNotificationTap(_ref.read(routerProvider), data);
    } catch (e, st) {
      _talker.handle(e, st, 'notification routing failed');
    }
    // Acting on a push directly (banner/cold-start tap) should clear its
    // unread state too, not just tapping it inside the notification center.
    // Fire-and-forget — don't block navigation on this.
    unawaited(_markReadFromTapData(data));
  }

  Future<void> _markReadFromTapData(Map<String, dynamic> data) async {
    final rawId = data['notification_id'] as String?;
    final id = rawId == null ? null : int.tryParse(rawId);
    if (id == null) return;
    try {
      await _supabase
          .rpc('fn_mark_notification_read', params: {'p_id': id})
          .timeout(const Duration(seconds: 5));
      _ref.invalidate(notificationUnreadCountProvider);
      _ref.invalidate(notificationCenterControllerProvider);
    } catch (e, st) {
      _talker.handle(e, st, 'mark notification read from tap failed');
    }
  }

  /// Soft-ask: show an in-app rationale, then (only on accept) trigger the OS
  /// prompt. Call at the first moment a notification becomes meaningful — after
  /// the user joins/creates a lobby, sends a befriend request, or books a pro.
  /// Never triggers the OS dialog cold (an iOS denial is permanent), never
  /// re-prompts after a denial, and no-ops for guests.
  Future<void> maybePromptAndRegister(
    BuildContext context,
    WidgetRef ref,
  ) async {
    if (ref.read(currentUserIdProvider) == null) return; // guest / signed-out

    final settings = await _messaging.getNotificationSettings();
    switch (settings.authorizationStatus) {
      case AuthorizationStatus.authorized:
      case AuthorizationStatus.provisional:
        await _registerIfPermitted();
        return;
      case AuthorizationStatus.denied:
        return; // permanent on iOS — don't nag; a Settings hint can come later
      case AuthorizationStatus.notDetermined:
        break; // fall through to the soft-ask
    }

    if (!context.mounted) return;
    final accepted = await _showSoftAsk(context);
    if (accepted != true) return;

    final result = await _messaging.requestPermission();
    if (result.authorizationStatus == AuthorizationStatus.authorized ||
        result.authorizationStatus == AuthorizationStatus.provisional) {
      await _registerIfPermitted();
    }
  }

  Future<bool?> _showSoftAsk(BuildContext context) {
    return showPSheet<bool>(
      context: context,
      builder: (sheetContext) {
        final typography = sheetContext.theme.typography;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PSheetTitle(label: 'Bật thông báo?'),
            const SizedBox(height: 12),
            Text(
              'Cho phép thông báo để biết khi nào hoạt động được chốt và '
              'khi sắp tới giờ tập với coach.',
              style: typography.body.md,
            ),
            const SizedBox(height: 24),
            FButton(
              onPress: () => Navigator.of(sheetContext).pop(true),
              child: const Text('Cho phép'),
            ),
            const SizedBox(height: 8),
            FButton(
              variant: .ghost,
              onPress: () => Navigator.of(sheetContext).pop(false),
              child: const Text('Để sau'),
            ),
          ],
        );
      },
    );
  }

  /// Register the current device token iff a session is active and the OS
  /// permission is already granted. Safe to call repeatedly.
  Future<void> _registerIfPermitted() async {
    try {
      if (_ref.read(currentUserIdProvider) == null) return;
      final settings = await _messaging.getNotificationSettings();
      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!granted) return;
      await _registerToken();
    } catch (e, st) {
      _talker.handle(e, st, 'token register failed');
    }
  }

  Future<void> _registerToken() async {
    final token = await _messaging.getToken();
    if (token == null) return;
    await _supabase.rpc(
      'register_device_token',
      params: {'p_fcm_token': token, 'p_platform': _platform},
    ).timeout(const Duration(seconds: 5));
  }

  /// Drop this device's token row (call on logout) so the next user of the
  /// device — or a signed-out state — stops receiving this account's pushes.
  Future<void> unregister() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      await _supabase
          .from('user_device_token')
          .delete()
          .eq('fcm_token', token)
          .timeout(const Duration(seconds: 5));
    } catch (e, st) {
      _talker.handle(e, st, 'token unregister failed');
    }
  }
}
