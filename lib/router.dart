import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';

import 'auth/auth_controller.dart';
import 'auth/auth_screen.dart';
import 'auth/welcome_screen.dart';
import 'core/model/pubox_user.dart';
import 'home_tab/main.dart';
import 'main.dart';
import 'manage_tab/main.dart';
import 'health_tab/main.dart';
import 'notification/main.dart';
import 'profile_tab/main.dart';
import 'splash/main.dart';

part 'router.g.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final supabase = Supabase.instance.client;

@riverpod
GoRouter router(Ref ref) {
  final talker = Talker();

  final user = ValueNotifier<AsyncValue<PuboxUser?>>(const AsyncLoading());
  ref.onDispose(user.dispose);

  // Only update the listenable when there's a meaningful auth state change
  // (logged in vs logged out), not on every AsyncValue change
  PuboxUser? previousUser;
  bool isFirstUpdate = true;
  ref.listen(authControllerProvider, (_, next) {
    final currentUser = next.value;
    final hasAuthStateChanged = isFirstUpdate ||
        (previousUser == null) != (currentUser == null) ||
        (previousUser?.isGuest != currentUser?.isGuest);

    if (hasAuthStateChanged) {
      user.value = next;
      previousUser = currentUser;
      isFirstUpdate = false;
    }
  });

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    observers: [TalkerRouteObserver(talker)],
    restorationScopeId: 'router',
    refreshListenable: user,
    initialLocation: const SplashRoute().location,
    // debugLogDiagnostics: true,
    routes: $appRoutes,
    redirect: (context, state) {
      final isSplash = state.uri.path == const SplashRoute().location;
      final isAuthFlow = state.uri.path == const AuthRoute().location ||
          state.uri.path == const WelcomeRoute().location;
      switch (user.value) {
        case AsyncError():
          if (isAuthFlow) return null;
          return const WelcomeRoute().location;
        case AsyncLoading():
          if (isAuthFlow) return null;
          return const SplashRoute().location;
        case AsyncData(value: null):
          if (isSplash || !isAuthFlow) return const WelcomeRoute().location;
          return null;
        case AsyncData(value: final user):
          if (user!.isGuest) {
            if (isSplash) return HomeRoute().location;
            if (isAuthFlow) return HomeRoute().location;
            return null;
          }

          if (isSplash || isAuthFlow) return HomeRoute().location;
          return null;
      }
    },
  );

  ref.onDispose(router.dispose);

  return router;
}

/// splash route - serves as a "buffer", while we check authentication
@TypedGoRoute<SplashRoute>(path: '/splash')
@immutable
class SplashRoute extends GoRouteData with $SplashRoute {
  /// splash route - serves as a "buffer", while we check authentication
  const SplashRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SplashScreen();
  }
}

@TypedGoRoute<AuthRoute>(path: '/auth')
@immutable
class AuthRoute extends GoRouteData with $AuthRoute {
  const AuthRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const AuthScreen();
  }
}

@TypedGoRoute<WelcomeRoute>(path: '/welcome')
@immutable
class WelcomeRoute extends GoRouteData with $WelcomeRoute {
  const WelcomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const WelcomeScreen();
  }
}

@TypedGoRoute<NotificationRoute>(path: '/notifications')
@immutable
class NotificationRoute extends GoRouteData with $NotificationRoute {
  const NotificationRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const NotificationPage();
  }
}

@TypedStatefulShellRoute<MainRoute>(
  branches: [
    TypedStatefulShellBranch(
      routes: [
        TypedGoRoute<HomeRoute>(
          path: '/home',
          routes: [
            TypedGoRoute<HomeTeammateRoute>(path: 'teammate'),
            TypedGoRoute<HomeChallengerRoute>(path: 'challenger'),
            TypedGoRoute<HomeNeutralRoute>(path: 'neutral'),
            TypedGoRoute<HomePlaceRoute>(path: 'place'),
          ],
        ),
      ],
    ),
    TypedStatefulShellBranch(
      routes: [
        TypedGoRoute<ManageRoute>(
          path: '/manage',
          routes: [
            TypedGoRoute<ManageScheduleRoute>(path: 'schedule'),
            TypedGoRoute<ManageLobbyRoute>(path: 'lobby'),
          ],
        ),
      ],
    ),
    TypedStatefulShellBranch(
      routes: [
        TypedGoRoute<HealthRoute>(path: '/health'),
      ],
    ),
    TypedStatefulShellBranch(
      routes: [
        TypedGoRoute<ProfileRoute>(path: '/profile'),
      ],
    ),
  ],
)
@immutable
class MainRoute extends StatefulShellRouteData {
  const MainRoute();

  @override
  Widget builder(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) {
    return ScaffoldWithNavBar(navigationShell: navigationShell);
  }
}

@immutable
class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const HomeTab();
}

@immutable
class HomeTeammateRoute extends GoRouteData with $HomeTeammateRoute {
  const HomeTeammateRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      HomeTab.withInitialTab(0);
}

@immutable
class HomeChallengerRoute extends GoRouteData with $HomeChallengerRoute {
  const HomeChallengerRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      HomeTab.withInitialTab(1);
}

@immutable
class HomeNeutralRoute extends GoRouteData with $HomeNeutralRoute {
  const HomeNeutralRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      HomeTab.withInitialTab(2);
}

@immutable
class HomePlaceRoute extends GoRouteData with $HomePlaceRoute {
  const HomePlaceRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      HomeTab.withInitialTab(3);
}

@immutable
class ManageRoute extends GoRouteData with $ManageRoute {
  const ManageRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ManageTab();
}

@immutable
class ManageScheduleRoute extends GoRouteData with $ManageScheduleRoute {
  const ManageScheduleRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      ManageTab.withInitialTab(0);
}

@immutable
class ManageLobbyRoute extends GoRouteData with $ManageLobbyRoute {
  const ManageLobbyRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      ManageTab.withInitialTab(1);
}

@immutable
class HealthRoute extends GoRouteData with $HealthRoute {
  const HealthRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const HealthTab();
}

@immutable
class ProfileRoute extends GoRouteData with $ProfileRoute {
  const ProfileRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ProfileTab();
}