// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'router.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $splashRoute,
  $authRoute,
  $notificationRoute,
  $mainRoute,
];

RouteBase get $splashRoute =>
    GoRouteData.$route(path: '/splash', factory: $SplashRoute._fromState);

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

RouteBase get $authRoute =>
    GoRouteData.$route(path: '/auth', factory: $AuthRoute._fromState);

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

RouteBase get $notificationRoute => GoRouteData.$route(
  path: '/notifications',
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

RouteBase get $mainRoute => StatefulShellRouteData.$route(
  factory: $MainRouteExtension._fromState,
  branches: [
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/home',
          factory: $HomeRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: 'teammate',
              factory: $HomeTeammateRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'challenger',
              factory: $HomeChallengerRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'neutral',
              factory: $HomeNeutralRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'place',
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
          factory: $ManageRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: 'schedule',
              factory: $ManageScheduleRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'lobby',
              factory: $ManageLobbyRoute._fromState,
            ),
          ],
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(path: '/health', factory: $HealthRoute._fromState),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(path: '/profile', factory: $ProfileRoute._fromState),
      ],
    ),
  ],
);

extension $MainRouteExtension on MainRoute {
  static MainRoute _fromState(GoRouterState state) => const MainRoute();
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
  static HomeTeammateRoute _fromState(GoRouterState state) =>
      const HomeTeammateRoute();

  @override
  String get location => GoRouteData.$location('/home/teammate');

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

mixin $HomeNeutralRoute on GoRouteData {
  static HomeNeutralRoute _fromState(GoRouterState state) =>
      const HomeNeutralRoute();

  @override
  String get location => GoRouteData.$location('/home/neutral');

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

String _$routerHash() => r'e25fb03a8ffcfd26b88e43ce8cae6350d46df0cd';
