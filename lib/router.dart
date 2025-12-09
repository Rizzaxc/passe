import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/auth_controller.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import 'home_tab/main.dart';
import 'main.dart';
import 'manage_tab/main.dart';
import 'health_tab/main.dart';
import 'profile_tab/main.dart';
import 'splash/main.dart';

part 'router.g.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

final GlobalKey<NavigatorState> _sectionANavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'sectionNav');

final supabase = Supabase.instance.client;

@riverpod
GoRouter router(Ref ref) {
  final user = ValueNotifier<AsyncValue<User?>>(const AsyncLoading());
  ref.onDispose(user.dispose);

  // update the listenable, when the auth state changes
  ref.listen(authControllerProvider, (_, next) {
    user.value = next;
  });

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    refreshListenable: user,
    initialLocation: const SplashRoute().location,
    debugLogDiagnostics: true,
    routes: $appRoutes,
    redirect: (context, state) {
      final isSplash = state.uri.path == const SplashRoute().location;
      final isLoggingIn = state.uri.path == const LoginRoute().location;
      switch (user.value) {
        case AsyncError():
          return const AppRoute().location;
        case AsyncLoading():
          return const SplashRoute().location;
        case AsyncData(value: null):
          if (isSplash) return const LoginRoute().location;
          if (isLoggingIn) return null;

          return const SplashRoute().location;
        case AsyncData(value: User()):
          if (isSplash) return const AppRoute().location;
          if (isLoggingIn) return const AppRoute().location;

          return null;
      }
    },
  );

  ref.onDispose(router.dispose);

  return router;
}

/// splash route - serves as a "buffer", while we check authentication
@TypedGoRoute<SplashRoute>(path: '/splash')
class SplashRoute extends GoRouteData with $SplashRoute {
  /// splash route - serves as a "buffer", while we check authentication
  const SplashRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SplashPage();
  }
}

class AppRoute extends StatefulShellRouteData with $AppRoute {
  const AppRoute();
  static RouteBase route() {
    return StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: <StatefulShellBranch>[
        StatefulShellBranch(
          navigatorKey: _sectionANavigatorKey,
          preload: true,
          routes: <RouteBase>[
            GoRoute(
              path: '/home',
              builder: (context, state) => HomeTab.instance,
              routes: <RouteBase>[
                GoRoute(
                  path: 'teammate',
                  builder: (context, state) {
                    return HomeTab.withInitialTab(0);
                  },
                ),
                GoRoute(
                  path: 'challenger',
                  builder: (context, state) {
                    return HomeTab.withInitialTab(1);
                  },
                ),
                GoRoute(
                  path: 'neutral',
                  builder: (context, state) {
                    return HomeTab.withInitialTab(2);
                  },
                ),
                GoRoute(
                  path: 'place',
                  builder: (context, state) {
                    return HomeTab.withInitialTab(3);
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/manage',
              builder: (context, state) => ManageTab.instance,
              routes: <RouteBase>[
                GoRoute(
                  path: 'schedule',
                  builder: (context, state) => ManageTab.withInitialTab(0),
                ),
                GoRoute(
                  path: 'lobby',
                  builder: (context, state) => ManageTab.withInitialTab(1),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/health',
              builder: (context, state) => HealthTab.instance,
              routes: const <RouteBase>[],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/profile',
              builder: (context, state) => ProfileTab.instance,
              routes: const <RouteBase>[],
            ),
          ],
        ),
      ],
    );
  }
}