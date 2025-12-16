import 'dart:async';

import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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

  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  final sentryDSN = dotenv.env['SENTRY_DSN']!;
  const Map<String, double?> sampleRates = {
    envLocal: null,
    envTest: 1,
    envLive: 0.1,
  };

  final talker = Talker(
    observer: PuboxTalkerObserver(env),
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
          child: const Pubox(),
        ),
      ),
    ),
  );
}

class Pubox extends HookConsumerWidget {
  const Pubox({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Pubox',
      builder: (_, child) =>
          FAnimatedTheme(data: ui.pbThemeLight, child: child!),
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

  static final tabIcons = <IconData>[
    CupertinoIcons.house_fill,
    Icons.edit_calendar_rounded,
    FontAwesomeIcons.heartPulse,
    CupertinoIcons.profile_circled,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      extendBody: true,

      bottomNavigationBar: AnimatedBottomNavigationBar(
        activeIndex: navigationShell.currentIndex,
        splashRadius: 0,
        iconSize: 28,
        onTap: (int index) => _onTap(context, index),
        gapLocation: GapLocation.center,
        notchSmoothness: NotchSmoothness.softEdge,
        notchMargin: 8,
        icons: tabIcons,
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
