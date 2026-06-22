import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:forui/forui.dart';
import 'ui/main.dart' as ui;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger_observer.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger_settings.dart';

import 'ads/ad_service.dart';
import 'firebase_options.dart';
import 'health_tab/health_sync_service.dart';
import 'logger/observer.dart';
import 'notifications/notification_service.dart';
import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/google_fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });

  await dotenv.load();

  final env = dotenv.env['ENV'] ?? 'local';
  const envLocal = 'local';
  const envTest = 'test';
  const envLive = 'live';
  assert(env == envLocal || env == envTest || env == envLive);

  final supabaseURL = dotenv.env['SUPABASE_URL']!;
  final supabaseAnonKey = dotenv.env['SUPABASE_PUBLIC_KEY']!;
  await Supabase.initialize(url: supabaseURL, anonKey: supabaseAnonKey);

  // Firebase + FCM. The background handler must be registered before runApp;
  // it is a no-op (the OS renders the notification block) but FCM requires it.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await EasyLocalization.ensureInitialized();

  // Google AdMob. Init is independent of the UI; banners/interstitials won't
  // serve until this completes. Test unit ids are used until real ones land
  // in .env (see lib/ads/ad_config.dart).
  await initMobileAds();

  final sentryDSN = dotenv.env['SENTRY_DSN']!;
  const Map<String, double?> sampleRates = {
    envLocal: null,
    envTest: 1,
    envLive: 0.1,
  };

  final talker = Talker(
    observer: PasseTalkerObserver(),
    logger: TalkerLogger(
      settings: TalkerLoggerSettings(
        level: env == envLocal ? LogLevel.debug : LogLevel.verbose,
      ),
    ),
    settings: TalkerSettings(
      timeFormat: TimeFormat.yearMonthDayAndTime,
      useConsoleLogs: false,
    ),
  );

  await SentryFlutter.init(
    (options) {
      // An empty DSN tells the SDK to no-op (see Sentry._setDefaultConfiguration),
      // which keeps local dev's build/hot-reload errors out of the issue feed.
      options.dsn = env == envLocal ? '' : sentryDSN;
      options.tracesSampleRate = sampleRates[env];
      options.profilesSampleRate = 1.0;
      options.environment = env;
    },
    appRunner: () => runApp(
      ProviderScope(
        observers: [
          TalkerRiverpodObserver(
            talker: talker,
            settings: TalkerRiverpodLoggerSettings(
              printProviderDisposed: env != envLive,
              printProviderAdded: env != envLive,
              printProviderUpdated: env != envLive,
              printProviderFailed: env != envLive,
            ),
          ),
        ],
        child: EasyLocalization(
          supportedLocales: const [Locale('vi'), Locale('en')],
          path: 'assets/translations',
          startLocale: const Locale('vi'),
          child: const Passe(),
        ),
      ),
    ),
  );
}

class Passe extends HookConsumerWidget {
  const Passe({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // Eagerly start the push service (FCM listeners + auth-driven token lifecycle).
    ref.watch(notificationServiceProvider);

    return MaterialApp.router(
      title: 'Passe',
      restorationScopeId: 'app',
      builder: (_, child) => FTheme(
        data: ui.pbThemeLight,
        child: DefaultTextStyle(
          style: ui.pbThemeLight.typography.md,
          child: FToaster(child: child!),
        ),
      ),
      theme: ui.pbThemeLight.toApproximateMaterialTheme(),
      routerConfig: router,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    );
  }
}

class ScaffoldWithNavBar extends ConsumerStatefulWidget {
  const ScaffoldWithNavBar({required this.navigationShell, Key? key})
    : super(key: key ?? const ValueKey<String>('ScaffoldWithNavBar'));

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends ConsumerState<ScaffoldWithNavBar> {
  @override
  void initState() {
    super.initState();
    // One-shot, non-blocking device→Supabase health sync on app launch. The
    // shell only mounts for an authed session; the sync controller self-guards
    // guests / unlinked / revoked permissions, so this is safe to fire blind.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(healthSyncControllerProvider.notifier)
          .syncNow()
          .catchError((_) => const HealthSyncResult());
    });
  }

  @override
  Widget build(BuildContext context) {
    final navigationShell = widget.navigationShell;
    return FScaffold(
      footer: FBottomNavigationBar(
        index: navigationShell.currentIndex,
        onChange: (index) => _onTap(context, index),
        children: [
          FBottomNavigationBarItem(
            icon: Icon(FIcons.house),
            label: Text('nav.home'.tr()),
          ),
          FBottomNavigationBarItem(
            icon: Icon(FIcons.calendar),
            label: Text('nav.manage'.tr()),
          ),
          FBottomNavigationBarItem(
            icon: Icon(FIcons.heartPulse),
            label: Text('nav.health'.tr()),
          ),
          FBottomNavigationBarItem(
            icon: Icon(FIcons.userCog),
            label: Text('nav.profile'.tr()),
          ),
        ],
      ),
      child: navigationShell,
    );
  }

  void _onTap(BuildContext context, int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}
