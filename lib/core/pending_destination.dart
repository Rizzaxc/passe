/// The location a cold start or deep link actually asked for, held while the
/// router detours through `/splash`, the auth flow and `/onboarding`.
///
/// Pure (no go_router / Riverpod) so the bookkeeping can be unit-tested
/// without standing up the whole router. `router.dart`'s `redirect` feeds
/// every pass through [observe] and spends the value with [take] once the
/// detour is over.
///
/// The detour screens themselves are never destinations worth restoring.
/// `/onboarding` used to be missing from that list, so a brand-new user who
/// opened `passe.vn/invite/CODE` had it overwritten by `/onboarding` on the
/// way through the sport pick and landed on a default tab instead.
class PendingDestination {
  static const _detourPaths = {
    '/splash',
    '/auth',
    '/welcome',
    '/forgot-password',
    '/reset-password',
    '/onboarding',
  };

  String? _value;

  String? get value => _value;

  static bool isDetour(String path) => _detourPaths.contains(path);

  /// Remember [uri] unless it's one of the detour screens.
  void observe(Uri uri) {
    if (isDetour(uri.path)) return;
    _value = uri.toString();
  }

  /// Spend the remembered destination, falling back to [fallback] when
  /// nothing was asked for.
  String take(String fallback) {
    final destination = _value ?? fallback;
    _value = null;
    return destination;
  }
}
