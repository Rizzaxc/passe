import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';

import 'auth/auth_controller.dart';
import 'auth/auth_screen.dart';
import 'auth/forgot_password_screen.dart';
import 'auth/reset_password_screen.dart';
import 'auth/welcome_screen.dart';
import 'core/model/professional_feed_item.dart';
import 'core/model/passe_user.dart';
import 'currency/wallet_home_screen.dart';
import 'currency/wallet_intro_screen.dart';
import 'currency/wallet_purchase_history_screen.dart';
import 'currency/wallet_spending_history_screen.dart';
import 'currency/wallet_topup_screen.dart';
import 'home_tab/main.dart';
import 'main.dart';
import 'manage_tab/lobby_section/lobby_detail_page.dart';
import 'manage_tab/main.dart';
import 'health_tab/main.dart';
import 'notification/main.dart';
import 'professional/main.dart';
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

  final user = ValueNotifier<AsyncValue<PasseUser?>>(const AsyncLoading());
  ref.onDispose(user.dispose);

  // Only update the listenable when there's a meaningful auth state change
  // (logged in vs logged out), not on every AsyncValue change
  PasseUser? previousUser;
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
      // Password-recovery screens are part of the unauthenticated flow and must
      // stay reachable: `/reset-password` is matched by path only because it
      // carries an `?email=` query.
      final isAuthFlow = state.uri.path == const AuthRoute().location ||
          state.uri.path == const WelcomeRoute().location ||
          state.uri.path == const ForgotPasswordRoute().location ||
          state.uri.path == '/reset-password';
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

/// Password recovery — step 1: request a reset code by email.
@TypedGoRoute<ForgotPasswordRoute>(path: '/forgot-password')
@immutable
class ForgotPasswordRoute extends GoRouteData with $ForgotPasswordRoute {
  const ForgotPasswordRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ForgotPasswordScreen();
}

/// Password recovery — step 2: verify the OTP and set a new password.
/// `email` is carried as a query parameter (`?email=...`).
@TypedGoRoute<ResetPasswordRoute>(path: '/reset-password')
@immutable
class ResetPasswordRoute extends GoRouteData with $ResetPasswordRoute {
  final String email;

  const ResetPasswordRoute({required this.email});

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      ResetPasswordScreen(email: email);
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

/// Đá in-app currency wallet — entry point pushed from the appbar pill.
@TypedGoRoute<WalletHomeRoute>(path: '/wallet')
@immutable
class WalletHomeRoute extends GoRouteData with $WalletHomeRoute {
  const WalletHomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const WalletHomeScreen();
}

@TypedGoRoute<WalletIntroRoute>(path: '/wallet/intro')
@immutable
class WalletIntroRoute extends GoRouteData with $WalletIntroRoute {
  const WalletIntroRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const WalletIntroScreen();
}

@TypedGoRoute<WalletPurchaseHistoryRoute>(path: '/wallet/purchase')
@immutable
class WalletPurchaseHistoryRoute extends GoRouteData
    with $WalletPurchaseHistoryRoute {
  const WalletPurchaseHistoryRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const WalletPurchaseHistoryScreen();
}

@TypedGoRoute<WalletSpendingHistoryRoute>(path: '/wallet/spending')
@immutable
class WalletSpendingHistoryRoute extends GoRouteData
    with $WalletSpendingHistoryRoute {
  const WalletSpendingHistoryRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const WalletSpendingHistoryScreen();
}

@TypedGoRoute<WalletTopupRoute>(path: '/wallet/topup')
@immutable
class WalletTopupRoute extends GoRouteData with $WalletTopupRoute {
  const WalletTopupRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const WalletTopupScreen();
}

/// Coach / referee profile detail.
///
/// Not part of the main tab navigation — only reachable as a push
/// destination from discovery flows (home professional feed, manage
/// coaching links, search, notifications). Pass a [ProfessionalFeedItem]
/// as `$extra` when available to skip the network round-trip.
@TypedGoRoute<ProfessionalDetailRoute>(path: '/professional/:id')
@immutable
class ProfessionalDetailRoute extends GoRouteData
    with $ProfessionalDetailRoute {
  final String id;
  // ignore: library_private_types_in_public_api
  final ProfessionalFeedItem? $extra;

  const ProfessionalDetailRoute({required this.id, this.$extra});

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      ProfessionalDetailPage(id: id, initialItem: $extra);
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
            TypedGoRoute<HomeProfessionalRoute>(path: 'professional'),
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
            TypedGoRoute<ManageLobbyRoute>(
              path: 'lobby',
              routes: [
                TypedGoRoute<LobbyDetailRoute>(path: ':id'),
              ],
            ),
          ],
        ),
      ],
    ),
    TypedStatefulShellBranch(
      routes: [
        TypedGoRoute<HealthRoute>(
          path: '/health',
          routes: [
            TypedGoRoute<HealthUserHealthRoute>(path: 'user_health'),
            TypedGoRoute<HealthActivityDataRoute>(path: 'activity_data'),
            TypedGoRoute<HealthAchievementsRoute>(path: 'achievements'),
          ],
        ),
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
class HomeProfessionalRoute extends GoRouteData with $HomeProfessionalRoute {
  const HomeProfessionalRoute();

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
class LobbyDetailRoute extends GoRouteData with $LobbyDetailRoute {
  final String id;
  // ignore: library_private_types_in_public_api
  final String? $extra;

  const LobbyDetailRoute({required this.id, this.$extra});

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      LobbyDetailPage(lobbyId: id, lobbyName: $extra);
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
class HealthUserHealthRoute extends GoRouteData with $HealthUserHealthRoute {
  const HealthUserHealthRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      HealthTab.withInitialTab(0);
}

@immutable
class HealthActivityDataRoute extends GoRouteData with $HealthActivityDataRoute {
  const HealthActivityDataRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      HealthTab.withInitialTab(1);
}

@immutable
class HealthAchievementsRoute extends GoRouteData with $HealthAchievementsRoute {
  const HealthAchievementsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      HealthTab.withInitialTab(2);
}

@immutable
class ProfileRoute extends GoRouteData with $ProfileRoute {
  const ProfileRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ProfileTab();
}