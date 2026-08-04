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
import 'core/model/passe_user.dart';
import 'core/model/professional_feed_item.dart';
import 'currency/wallet_home_screen.dart';
import 'currency/wallet_intro_screen.dart';
import 'currency/wallet_purchase_history_screen.dart';
import 'currency/wallet_spending_history_screen.dart';
import 'currency/wallet_topup_screen.dart';
import 'feed_tab/main.dart';
import 'health_tab/main.dart';
import 'home_tab/main.dart';
import 'main.dart';
import 'manage_tab/lobby_section/lobby_detail_page.dart';
import 'manage_tab/main.dart';
import 'notification/main.dart';
import 'onboarding/onboarding_controller.dart';
import 'onboarding/onboarding_prefs.dart';
import 'onboarding/onboarding_screen.dart';
import 'professional/main.dart';
import 'profile_tab/main.dart';
import 'social/user_page.dart';
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
  // (logged in vs logged out, or an error appearing/clearing), not on every
  // AsyncValue change.
  PasseUser? previousUser;
  bool previousIsError = false;
  bool isFirstUpdate = true;
  ref.listen(authControllerProvider, (_, next) {
    final currentUser = next.value;
    final currentIsError = next is AsyncError;
    final hasAuthStateChanged =
        isFirstUpdate ||
        (previousUser == null) != (currentUser == null) ||
        (previousUser?.isGuest != currentUser?.isGuest) ||
        // Propagate error transitions so the redirect's AsyncError branch can
        // fire (e.g. an initial load failure), not just null/guest changes.
        (previousIsError != currentIsError);

    if (hasAuthStateChanged) {
      user.value = next;
      previousUser = currentUser;
      previousIsError = currentIsError;
      isFirstUpdate = false;
    }
  });

  // Mirrors the `user` notifier above: only `redirect` needs a synchronous,
  // always-current read of onboarding status, so its provider value is
  // mirrored into a plain `ValueNotifier` the router can watch.
  final onboarding = ValueNotifier<AsyncValue<OnboardingStatus>>(
    const AsyncLoading(),
  );
  ref.onDispose(onboarding.dispose);
  ref.listen(onboardingStateProvider, (_, next) {
    onboarding.value = next;
  }, fireImmediately: true);

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    observers: [TalkerRouteObserver(talker)],
    restorationScopeId: 'router',
    refreshListenable: Listenable.merge([user, onboarding]),
    initialLocation: const SplashRoute().location,
    // debugLogDiagnostics: true,
    routes: $appRoutes,
    redirect: (context, state) {
      final isSplash = state.uri.path == const SplashRoute().location;
      final isOnboarding = state.uri.path == const OnboardingRoute().location;
      // Password-recovery screens carry their own flag: unlike the rest of
      // the auth flow, guests must be able to reach them too — the "Forgot
      // password?" link is only ever shown from the embedded form in
      // GuestProfileView, so without this carve-out a guest could never get
      // past the redirect below to actually use it.
      // (`/reset-password` is matched by path only because it carries an
      // `?email=` query.)
      final isPasswordRecoveryFlow =
          state.uri.path == const ForgotPasswordRoute().location ||
          state.uri.path == '/reset-password';
      final isAuthFlow =
          state.uri.path == const AuthRoute().location ||
          state.uri.path == const WelcomeRoute().location ||
          isPasswordRecoveryFlow;

      // Only reachable once `user.value` is `AsyncData` with a real identity
      // (guest or signed-in) — the auth branches below gate that. Returns
      // `null` when the current location is already correct for onboarding
      // status, otherwise the path to redirect to. `coreDone` (sport picked)
      // is the only thing that blocks entry to the shell — the rest of the
      // guide (story/profile/coach-marks, and whether a guest declined it)
      // runs afterward as sheets/coach-marks over the real shell, so it
      // doesn't gate routing at all. See `onboarding/follow_up.dart`.
      String? gateOnboarding() {
        switch (onboarding.value) {
          case AsyncLoading():
            // Always claim `/splash` — never `null` — even when already
            // there. Returning `null` while already on `/splash` let the
            // callers' own `isSplash -> Home` fallback fire mid-load
            // (`OnboardingState` goes back through `AsyncLoading` on every
            // `authControllerProvider` change, e.g. the auth refresh a
            // profile-sheet save triggers), which then immediately bounced
            // back to `/splash` on the next pass — a `/splash <-> /home`
            // redirect loop go_router detects and throws on.
            return const SplashRoute().location;
          case AsyncError():
            // Fail open — never trap the user on a broken onboarding read.
            return isOnboarding ? HomeRoute().location : null;
          case AsyncData(value: final status):
            if (!status.coreDone) {
              return isOnboarding ? null : const OnboardingRoute().location;
            }
            return isOnboarding ? HomeRoute().location : null;
        }
      }

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
            if (isPasswordRecoveryFlow) return null;
            final onboardingRedirect = gateOnboarding();
            if (onboardingRedirect != null) return onboardingRedirect;
            if (isSplash || isAuthFlow) return HomeRoute().location;
            return null;
          }

          final onboardingRedirect = gateOnboarding();
          if (onboardingRedirect != null) return onboardingRedirect;
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

/// Post-auth onboarding journey (app story → select sport → improve profile
/// → the feature-intro coach-marks run separately, over the live shell).
/// Top-level, outside [MainRoute]'s shell — no bottom nav while it's up.
/// Gated by `redirect`'s `gateOnboarding`, not reachable/leavable by hand.
@TypedGoRoute<OnboardingRoute>(path: '/onboarding')
@immutable
class OnboardingRoute extends GoRouteData with $OnboardingRoute {
  const OnboardingRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const OnboardingScreen();
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

/// Another player's page — wall, identity, and the friend CTA.
///
/// Like [ProfessionalDetailRoute] this is push-only, never a tab. Reached from
/// a lobby member row, a friend search result, a feed post author or a tag
/// chip. Pass the username as `$extra` so the header has something to show
/// before `user_profile_data` returns.
@TypedGoRoute<UserRoute>(path: '/user/:id')
@immutable
class UserRoute extends GoRouteData with $UserRoute {
  final String id;
  // ignore: library_private_types_in_public_api
  final String? $extra;

  const UserRoute({required this.id, this.$extra});

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      UserPage(userId: id, initialName: $extra);
}

@TypedStatefulShellRoute<MainRoute>(
  branches: [
    TypedStatefulShellBranch(routes: [TypedGoRoute<FeedRoute>(path: '/feed')]),
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
            TypedGoRoute<ManageRequestsRoute>(path: 'requests'),
            TypedGoRoute<ManageLobbyRoute>(
              path: 'lobby',
              routes: [TypedGoRoute<LobbyDetailRoute>(path: ':id')],
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
      routes: [TypedGoRoute<ProfileRoute>(path: '/profile')],
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

/// Feed — a main tab in its own right, first in the bottom nav. A TikTok-style
/// vertical feed of wall posts; see `lib/feed_tab/main.dart`.
@immutable
class FeedRoute extends GoRouteData with $FeedRoute {
  const FeedRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const FeedTab();
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
  Widget build(BuildContext context, GoRouterState state) => const ManageTab();
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
class ManageRequestsRoute extends GoRouteData with $ManageRequestsRoute {
  // Set from a professional_booking_requested notification tap so the
  // pending-requests list can scroll to and highlight that one card.
  final String? highlightBookingId;

  const ManageRequestsRoute({this.highlightBookingId});

  // In pro mode, ManageTab's subtab list is [schedule, pending requests,
  // history] instead of [schedule, lobby, coaching] — index 1 lands on
  // pending requests only when pro mode is active (see ManageTab.build).
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      ManageTab.withInitialTab(1, highlightBookingId: highlightBookingId);
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
  Widget build(BuildContext context, GoRouterState state) => const HealthTab();
}

@immutable
class HealthUserHealthRoute extends GoRouteData with $HealthUserHealthRoute {
  const HealthUserHealthRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      HealthTab.withInitialTab(0);
}

@immutable
class HealthActivityDataRoute extends GoRouteData
    with $HealthActivityDataRoute {
  const HealthActivityDataRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      HealthTab.withInitialTab(1);
}

@immutable
class HealthAchievementsRoute extends GoRouteData
    with $HealthAchievementsRoute {
  const HealthAchievementsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      HealthTab.withInitialTab(2);
}

@immutable
class ProfileRoute extends GoRouteData with $ProfileRoute {
  const ProfileRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const ProfileTab();
}
