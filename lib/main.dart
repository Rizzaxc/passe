import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger_observer.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger_settings.dart';

import 'ads/ad_service.dart';
import 'core/model/enum.dart';
import 'core/state/selected_sport_state.dart';
import 'firebase_options.dart';
import 'health_tab/health_sync_service.dart';
import 'logger/observer.dart';
import 'notifications/notification_service.dart';
import 'onboarding/coach_marks.dart';
import 'onboarding/follow_up.dart';
import 'profile_tab/profile_controller.dart';
import 'profile_tab/sport_profile/sport_profile_controller.dart';
import 'router.dart';
import 'ui/main.dart' as ui;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/google_fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });

  await dotenv.load();

  // OSM's tile usage policy requires caching tiles locally for at least 7
  // days; tile.openstreetmap.org's own Cache-Control header (~24h) is
  // shorter than that, so this overrides the freshness window rather than
  // trusting the server's shorter one. Must run before the first TileLayer
  // builds — NetworkTileProvider (the default for both TileLayers in
  // discover_tab/location_section/main.dart) lazily creates this same singleton
  // on first use otherwise, with no override applied.
  BuiltInMapCachingProvider.getOrCreateInstance(
    overrideFreshAge: const Duration(days: 7),
  );

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
    appRunner: () {
      runApp(
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
      );
      // Google AdMob. Deferred past the first frame — see initMobileAds doc.
      // Test unit ids are used until real ones land in .env (see
      // lib/ads/ad_config.dart).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(initMobileAds());
      });
    },
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
        child: ui.PKeyboardDismiss(
          child: DefaultTextStyle(
            style: ui.pbThemeLight.typography.body.md,
            child: FToaster(child: child!),
          ),
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
  final AutoSizeGroup _navLabelGroup = AutoSizeGroup();

  @override
  void initState() {
    super.initState();
    // One-shot, non-blocking device→Supabase health sync on app launch. The
    // shell only mounts for an authed session; the sync controller self-guards
    // guests / unlinked / revoked permissions, so this is safe to fire blind.
    // The short delay (rather than firing in the post-frame callback itself)
    // keeps the multi-day backfill loop from competing with Home's first
    // paint for the UI isolate's event loop right as the app opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        ref
            .read(healthSyncControllerProvider.notifier)
            .syncNow()
            .catchError((_) => const HealthSyncResult());
      });

      // The shell's first frame has just laid out the nav bar, so the coach
      // keys have a `currentContext` by now — safe to run the rest of the
      // onboarding journey (story sheet → profile sheet → coach-marks)
      // right away; each step self-guards on its own persisted status.
      runOnboardingFollowUps(context, ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    final navigationShell = widget.navigationShell;
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    return FScaffold(
      // Every branch supplies its own page scaffold. Let that inner scaffold
      // handle the keyboard exactly once. The footer is hidden while the IME
      // is open so its height is not still reserved above the keyboard.
      resizeToAvoidBottomInset: false,
      footer: keyboardVisible
          ? null
          : FBottomNavigationBar(
              // Android edge-to-edge layouts place the footer behind the gesture /
              // three-button system navigation area unless the bar consumes the
              // device's bottom inset itself. Keep Forui's existing iOS spacing.
              safeAreaBottom: defaultTargetPlatform == TargetPlatform.android,
              index: navigationShell.currentIndex,
              onChange: (index) => _onTap(context, index),
              children: [
                FBottomNavigationBarItem(
                  key: NavCoachKeys.feed,
                  icon: Icon(FLucideIcons.clapperboard),
                  label: _NavLabel('nav.feed'.tr(), group: _navLabelGroup),
                ),
                FBottomNavigationBarItem(
                  key: NavCoachKeys.discover,
                  icon: Icon(FLucideIcons.house),
                  label: _NavLabel('nav.discover'.tr(), group: _navLabelGroup),
                ),
                FBottomNavigationBarItem(
                  key: NavCoachKeys.manage,
                  icon: Icon(FLucideIcons.calendar),
                  label: _NavLabel('nav.manage'.tr(), group: _navLabelGroup),
                ),
                FBottomNavigationBarItem(
                  key: NavCoachKeys.health,
                  icon: Icon(FLucideIcons.heartPulse),
                  label: _NavLabel('nav.health'.tr(), group: _navLabelGroup),
                ),
                FBottomNavigationBarItem(
                  key: NavCoachKeys.profile,
                  icon: Icon(FLucideIcons.userCog),
                  label: _NavLabel('nav.profile'.tr(), group: _navLabelGroup),
                ),
              ],
            ),
      child: navigationShell,
    );
  }

  Future<void> _onTap(BuildContext context, int index) async {
    if (widget.navigationShell.currentIndex == 4 && index != 4) {
      // The providers also depend on controller-owned saved baselines, which
      // can advance after a successful commit without changing draft state.
      // Re-evaluate them at the navigation boundary instead of trusting a
      // previously cached dirty result.
      ref.invalidate(profileHasUncommittedChangesProvider);
      ref.invalidate(sportProfileHasUncommittedChangesProvider);
      final hasChanges =
          ref.read(profileHasUncommittedChangesProvider) ||
          ref.read(sportProfileHasUncommittedChangesProvider);
      if (!hasChanges) {
        widget.navigationShell.goBranch(index);
        return;
      }

      final discard = await showFDialog<bool>(
        context: context,
        builder: (dialogContext, style, animation) => ui.PConfirmDialog(
          animation: animation,
          title: Text('profile.discardChangesTitle'.tr()),
          body: Text('profile.discardChangesBody'.tr()),
          actions: [
            FButton(
              variant: .outline,
              onPress: () => Navigator.of(dialogContext).pop(false),
              child: Text('profile.discardChangesStay'.tr()),
            ),
            FButton(
              variant: .destructive,
              onPress: () => Navigator.of(dialogContext).pop(true),
              child: Text('profile.discardChangesLeave'.tr()),
            ),
          ],
        ),
      );
      if (discard != true || !mounted) return;

      ref.read(profileControllerProvider.notifier).discardChanges();
      final sport = ref.read(selectedSportStateProvider).asData?.value;
      if (sport != null && sport != Sport.others) {
        discardSportProfileChanges(ref, sport);
      }
    }

    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}

class _NavLabel extends StatelessWidget {
  const _NavLabel(this.label, {required this.group});

  final String label;
  final AutoSizeGroup group;

  @override
  Widget build(BuildContext context) => AutoSizeText(
    label,
    group: group,
    minFontSize: 1,
    maxLines: 1,
    softWrap: false,
    wrapWords: false,
    overflow: TextOverflow.visible,
    textAlign: TextAlign.center,
  );
}
