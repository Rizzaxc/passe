// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'router.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $splashRoute,
  $authRoute,
  $welcomeRoute,
  $forgotPasswordRoute,
  $resetPasswordRoute,
  $onboardingRoute,
  $notificationRoute,
  $walletHomeRoute,
  $walletIntroRoute,
  $walletPurchaseHistoryRoute,
  $walletSpendingHistoryRoute,
  $walletTopupRoute,
  $professionalDetailRoute,
  $userRoute,
  $mainRoute,
];

RouteBase get $splashRoute => GoRouteData.$route(
  path: '/splash',
  hasOverriddenOnExit: false,
  factory: $SplashRoute._fromState,
);

mixin $SplashRoute on GoRouteData {
  static SplashRoute _fromState(GoRouterState state) => const SplashRoute();

  @override
  String get location => GoRouteData.$location('/splash');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $authRoute => GoRouteData.$route(
  path: '/auth',
  hasOverriddenOnExit: false,
  factory: $AuthRoute._fromState,
);

mixin $AuthRoute on GoRouteData {
  static AuthRoute _fromState(GoRouterState state) => const AuthRoute();

  @override
  String get location => GoRouteData.$location('/auth');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $welcomeRoute => GoRouteData.$route(
  path: '/welcome',
  hasOverriddenOnExit: false,
  factory: $WelcomeRoute._fromState,
);

mixin $WelcomeRoute on GoRouteData {
  static WelcomeRoute _fromState(GoRouterState state) => const WelcomeRoute();

  @override
  String get location => GoRouteData.$location('/welcome');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $forgotPasswordRoute => GoRouteData.$route(
  path: '/forgot-password',
  hasOverriddenOnExit: false,
  factory: $ForgotPasswordRoute._fromState,
);

mixin $ForgotPasswordRoute on GoRouteData {
  static ForgotPasswordRoute _fromState(GoRouterState state) =>
      const ForgotPasswordRoute();

  @override
  String get location => GoRouteData.$location('/forgot-password');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $resetPasswordRoute => GoRouteData.$route(
  path: '/reset-password',
  hasOverriddenOnExit: false,
  factory: $ResetPasswordRoute._fromState,
);

mixin $ResetPasswordRoute on GoRouteData {
  static ResetPasswordRoute _fromState(GoRouterState state) =>
      ResetPasswordRoute(email: state.uri.queryParameters['email']!);

  ResetPasswordRoute get _self => this as ResetPasswordRoute;

  @override
  String get location => GoRouteData.$location(
    '/reset-password',
    queryParams: {'email': _self.email},
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $onboardingRoute => GoRouteData.$route(
  path: '/onboarding',
  hasOverriddenOnExit: false,
  factory: $OnboardingRoute._fromState,
);

mixin $OnboardingRoute on GoRouteData {
  static OnboardingRoute _fromState(GoRouterState state) =>
      const OnboardingRoute();

  @override
  String get location => GoRouteData.$location('/onboarding');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $notificationRoute => GoRouteData.$route(
  path: '/notifications',
  hasOverriddenOnExit: false,
  factory: $NotificationRoute._fromState,
);

mixin $NotificationRoute on GoRouteData {
  static NotificationRoute _fromState(GoRouterState state) =>
      const NotificationRoute();

  @override
  String get location => GoRouteData.$location('/notifications');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $walletHomeRoute => GoRouteData.$route(
  path: '/wallet',
  hasOverriddenOnExit: false,
  factory: $WalletHomeRoute._fromState,
);

mixin $WalletHomeRoute on GoRouteData {
  static WalletHomeRoute _fromState(GoRouterState state) =>
      const WalletHomeRoute();

  @override
  String get location => GoRouteData.$location('/wallet');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $walletIntroRoute => GoRouteData.$route(
  path: '/wallet/intro',
  hasOverriddenOnExit: false,
  factory: $WalletIntroRoute._fromState,
);

mixin $WalletIntroRoute on GoRouteData {
  static WalletIntroRoute _fromState(GoRouterState state) =>
      const WalletIntroRoute();

  @override
  String get location => GoRouteData.$location('/wallet/intro');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $walletPurchaseHistoryRoute => GoRouteData.$route(
  path: '/wallet/purchase',
  hasOverriddenOnExit: false,
  factory: $WalletPurchaseHistoryRoute._fromState,
);

mixin $WalletPurchaseHistoryRoute on GoRouteData {
  static WalletPurchaseHistoryRoute _fromState(GoRouterState state) =>
      const WalletPurchaseHistoryRoute();

  @override
  String get location => GoRouteData.$location('/wallet/purchase');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $walletSpendingHistoryRoute => GoRouteData.$route(
  path: '/wallet/spending',
  hasOverriddenOnExit: false,
  factory: $WalletSpendingHistoryRoute._fromState,
);

mixin $WalletSpendingHistoryRoute on GoRouteData {
  static WalletSpendingHistoryRoute _fromState(GoRouterState state) =>
      const WalletSpendingHistoryRoute();

  @override
  String get location => GoRouteData.$location('/wallet/spending');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $walletTopupRoute => GoRouteData.$route(
  path: '/wallet/topup',
  hasOverriddenOnExit: false,
  factory: $WalletTopupRoute._fromState,
);

mixin $WalletTopupRoute on GoRouteData {
  static WalletTopupRoute _fromState(GoRouterState state) =>
      const WalletTopupRoute();

  @override
  String get location => GoRouteData.$location('/wallet/topup');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $professionalDetailRoute => GoRouteData.$route(
  path: '/professional/:id',
  hasOverriddenOnExit: false,
  factory: $ProfessionalDetailRoute._fromState,
);

mixin $ProfessionalDetailRoute on GoRouteData {
  static ProfessionalDetailRoute _fromState(GoRouterState state) =>
      ProfessionalDetailRoute(
        id: state.pathParameters['id']!,
        $extra: state.extra as ProfessionalFeedItem?,
      );

  ProfessionalDetailRoute get _self => this as ProfessionalDetailRoute;

  @override
  String get location =>
      GoRouteData.$location('/professional/${Uri.encodeComponent(_self.id)}');

  @override
  void go(BuildContext context) => context.go(location, extra: _self.$extra);

  @override
  Future<T?> push<T>(BuildContext context) =>
      context.push<T>(location, extra: _self.$extra);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location, extra: _self.$extra);

  @override
  void replace(BuildContext context) =>
      context.replace(location, extra: _self.$extra);
}

RouteBase get $userRoute => GoRouteData.$route(
  path: '/user/:id',
  hasOverriddenOnExit: false,
  factory: $UserRoute._fromState,
);

mixin $UserRoute on GoRouteData {
  static UserRoute _fromState(GoRouterState state) => UserRoute(
    id: state.pathParameters['id']!,
    $extra: state.extra as String?,
  );

  UserRoute get _self => this as UserRoute;

  @override
  String get location =>
      GoRouteData.$location('/user/${Uri.encodeComponent(_self.id)}');

  @override
  void go(BuildContext context) => context.go(location, extra: _self.$extra);

  @override
  Future<T?> push<T>(BuildContext context) =>
      context.push<T>(location, extra: _self.$extra);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location, extra: _self.$extra);

  @override
  void replace(BuildContext context) =>
      context.replace(location, extra: _self.$extra);
}

RouteBase get $mainRoute => StatefulShellRouteData.$route(
  factory: $MainRouteExtension._fromState,
  branches: [
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/feed',
          hasOverriddenOnExit: false,
          factory: $FeedRoute._fromState,
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/home',
          hasOverriddenOnExit: false,
          factory: $HomeRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: 'teammate',
              hasOverriddenOnExit: false,
              factory: $HomeTeammateRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'challenger',
              hasOverriddenOnExit: false,
              factory: $HomeChallengerRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'professional',
              hasOverriddenOnExit: false,
              factory: $HomeProfessionalRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'place',
              hasOverriddenOnExit: false,
              factory: $HomePlaceRoute._fromState,
            ),
          ],
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/manage',
          hasOverriddenOnExit: false,
          factory: $ManageRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: 'schedule',
              hasOverriddenOnExit: false,
              factory: $ManageScheduleRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'requests',
              hasOverriddenOnExit: false,
              factory: $ManageRequestsRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'lobby',
              hasOverriddenOnExit: false,
              factory: $ManageLobbyRoute._fromState,
              routes: [
                GoRouteData.$route(
                  path: ':id',
                  hasOverriddenOnExit: false,
                  factory: $LobbyDetailRoute._fromState,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/health',
          hasOverriddenOnExit: false,
          factory: $HealthRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: 'user_health',
              hasOverriddenOnExit: false,
              factory: $HealthUserHealthRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'activity_data',
              hasOverriddenOnExit: false,
              factory: $HealthActivityDataRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'achievements',
              hasOverriddenOnExit: false,
              factory: $HealthAchievementsRoute._fromState,
            ),
          ],
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/profile',
          hasOverriddenOnExit: false,
          factory: $ProfileRoute._fromState,
        ),
      ],
    ),
  ],
);

extension $MainRouteExtension on MainRoute {
  static MainRoute _fromState(GoRouterState state) => const MainRoute();
}

mixin $FeedRoute on GoRouteData {
  static FeedRoute _fromState(GoRouterState state) => const FeedRoute();

  @override
  String get location => GoRouteData.$location('/feed');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $HomeRoute on GoRouteData {
  static HomeRoute _fromState(GoRouterState state) => const HomeRoute();

  @override
  String get location => GoRouteData.$location('/home');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $HomeTeammateRoute on GoRouteData {
  static HomeTeammateRoute _fromState(GoRouterState state) => HomeTeammateRoute(
    openFilter:
        _$convertMapValue(
          'open-filter',
          state.uri.queryParameters,
          _$boolConverter,
        ) ??
        false,
  );

  HomeTeammateRoute get _self => this as HomeTeammateRoute;

  @override
  String get location => GoRouteData.$location(
    '/home/teammate',
    queryParams: {
      if (_self.openFilter != false) 'open-filter': _self.openFilter.toString(),
    },
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $HomeChallengerRoute on GoRouteData {
  static HomeChallengerRoute _fromState(GoRouterState state) =>
      const HomeChallengerRoute();

  @override
  String get location => GoRouteData.$location('/home/challenger');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $HomeProfessionalRoute on GoRouteData {
  static HomeProfessionalRoute _fromState(GoRouterState state) =>
      const HomeProfessionalRoute();

  @override
  String get location => GoRouteData.$location('/home/professional');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $HomePlaceRoute on GoRouteData {
  static HomePlaceRoute _fromState(GoRouterState state) =>
      const HomePlaceRoute();

  @override
  String get location => GoRouteData.$location('/home/place');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ManageRoute on GoRouteData {
  static ManageRoute _fromState(GoRouterState state) => const ManageRoute();

  @override
  String get location => GoRouteData.$location('/manage');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ManageScheduleRoute on GoRouteData {
  static ManageScheduleRoute _fromState(GoRouterState state) =>
      const ManageScheduleRoute();

  @override
  String get location => GoRouteData.$location('/manage/schedule');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ManageRequestsRoute on GoRouteData {
  static ManageRequestsRoute _fromState(GoRouterState state) =>
      ManageRequestsRoute(
        highlightBookingId: state.uri.queryParameters['highlight-booking-id'],
      );

  ManageRequestsRoute get _self => this as ManageRequestsRoute;

  @override
  String get location => GoRouteData.$location(
    '/manage/requests',
    queryParams: {
      if (_self.highlightBookingId != null)
        'highlight-booking-id': _self.highlightBookingId,
    },
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ManageLobbyRoute on GoRouteData {
  static ManageLobbyRoute _fromState(GoRouterState state) =>
      const ManageLobbyRoute();

  @override
  String get location => GoRouteData.$location('/manage/lobby');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $LobbyDetailRoute on GoRouteData {
  static LobbyDetailRoute _fromState(GoRouterState state) => LobbyDetailRoute(
    id: state.pathParameters['id']!,
    $extra: state.extra as String?,
  );

  LobbyDetailRoute get _self => this as LobbyDetailRoute;

  @override
  String get location =>
      GoRouteData.$location('/manage/lobby/${Uri.encodeComponent(_self.id)}');

  @override
  void go(BuildContext context) => context.go(location, extra: _self.$extra);

  @override
  Future<T?> push<T>(BuildContext context) =>
      context.push<T>(location, extra: _self.$extra);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location, extra: _self.$extra);

  @override
  void replace(BuildContext context) =>
      context.replace(location, extra: _self.$extra);
}

mixin $HealthRoute on GoRouteData {
  static HealthRoute _fromState(GoRouterState state) => const HealthRoute();

  @override
  String get location => GoRouteData.$location('/health');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $HealthUserHealthRoute on GoRouteData {
  static HealthUserHealthRoute _fromState(GoRouterState state) =>
      const HealthUserHealthRoute();

  @override
  String get location => GoRouteData.$location('/health/user_health');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $HealthActivityDataRoute on GoRouteData {
  static HealthActivityDataRoute _fromState(GoRouterState state) =>
      const HealthActivityDataRoute();

  @override
  String get location => GoRouteData.$location('/health/activity_data');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $HealthAchievementsRoute on GoRouteData {
  static HealthAchievementsRoute _fromState(GoRouterState state) =>
      const HealthAchievementsRoute();

  @override
  String get location => GoRouteData.$location('/health/achievements');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ProfileRoute on GoRouteData {
  static ProfileRoute _fromState(GoRouterState state) => const ProfileRoute();

  @override
  String get location => GoRouteData.$location('/profile');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

T? _$convertMapValue<T>(
  String key,
  Map<String, String> map,
  T? Function(String) converter,
) {
  final value = map[key];
  return value == null ? null : converter(value);
}

bool _$boolConverter(String value) {
  switch (value) {
    case 'true':
      return true;
    case 'false':
      return false;
    default:
      throw UnsupportedError('Cannot convert "$value" into a bool.');
  }
}

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(router)
final routerProvider = RouterProvider._();

final class RouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  RouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routerHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return router(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$routerHash() => r'c6e93ed66d977785d160f0b307e4796d8acf4cec';
