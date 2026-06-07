import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
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

import 'logger/observer.dart';
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

  await EasyLocalization.ensureInitialized();

  final sentryDSN = dotenv.env['SENTRY_DSN']!;
  const Map<String, double?> sampleRates = {
    envLocal: null,
    envTest: 1,
    envLive: 0.1,
  };

  final talker = Talker(
    observer: PasseTalkerObserver(env),
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
      options.dsn = sentryDSN;
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

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({required this.navigationShell, Key? key})
    : super(key: key ?? const ValueKey<String>('ScaffoldWithNavBar'));

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
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
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
