import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'format.dart' show formatDistanceMeters;

/// Where the user is right now, or `null` when it isn't known.
///
/// Reading this never prompts: `build` only resolves a position when location
/// permission was already granted. The OS dialog is shown by [request], which
/// the "see distance" chip (`PDistanceLabel`) calls from an explicit tap —
/// same soft-ask posture as push notifications.
///
/// A coarse fix is enough (we only print "1,2 km"), so it asks for low
/// accuracy: faster, cheaper on battery, and on Android 12+ it still works if
/// the user only grants "approximate" location.
final userPositionProvider =
    AsyncNotifierProvider<UserPositionNotifier, Position?>(
      UserPositionNotifier.new,
    );

/// Whether the OS would let us read the position (already granted).
bool _granted(LocationPermission p) =>
    p == LocationPermission.whileInUse || p == LocationPermission.always;

/// Whether the "see distance" prompt is worth showing: true only when the
/// user's action could change the outcome (permission not granted, or the
/// device's location service is off). Granted-but-no-fix-yet is not a prompt
/// case — [UserPositionNotifier] keeps retrying on its own.
final locationNeedsPromptProvider = FutureProvider<bool>((ref) async {
  // Re-evaluated whenever the position changes (after [request] or a retry).
  ref.watch(userPositionProvider);
  try {
    return !await Geolocator.isLocationServiceEnabled() ||
        !_granted(await Geolocator.checkPermission());
  } catch (_) {
    return false;
  }
});

class UserPositionNotifier extends AsyncNotifier<Position?> {
  static const _maxRetries = 3;
  int _retries = 0;

  @override
  Future<Position?> build() async {
    // A fix that failed (cold GPS, timeout) must not stick for the session:
    // retry shortly, and again whenever the app comes back to the foreground
    // (permission may have been granted in Settings meanwhile).
    final lifecycle = AppLifecycleListener(
      onResume: () {
        if (state.value == null) {
          _retries = 0;
          ref.invalidateSelf();
        }
      },
    );
    ref.onDispose(lifecycle.dispose);

    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      if (!_granted(await Geolocator.checkPermission())) return null;
      final fix = await _fix();
      _retries = 0;
      return fix;
    } catch (_) {
      if (_retries < _maxRetries) {
        _retries++;
        final timer = Timer(
          Duration(seconds: 5 * _retries),
          ref.invalidateSelf,
        );
        ref.onDispose(timer.cancel);
      }
      return null;
    }
  }

  Future<Position?> _fix() async =>
      await Geolocator.getLastKnownPosition() ??
      await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      ).timeout(const Duration(seconds: 5));

  /// Asks the OS for permission (when still askable) and refreshes the fix.
  /// Returns the resulting permission so the caller can react to a permanent
  /// denial (send the user to settings).
  Future<LocationPermission> request() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return permission;
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
      return permission;
    }
    if (_granted(permission)) {
      state = const AsyncLoading<Position?>();
      state = await AsyncValue.guard(_fix);
    }
    return permission;
  }

  /// Great-circle distance in meters from the user to ([lat], [lon]), or
  /// `null` while the position is unknown.
  double? metersTo(double lat, double lon) {
    final p = state.value;
    if (p == null) return null;
    return Geolocator.distanceBetween(p.latitude, p.longitude, lat, lon);
  }
}

/// Convenience: "850 m" / "2,4 km" from the user to a point, `null` when the
/// position is unknown. Watches [userPositionProvider] so the label appears
/// as soon as a fix lands.
String? watchDistanceLabel(WidgetRef ref, double? lat, double? lon) {
  final position = ref.watch(userPositionProvider).value;
  if (position == null || lat == null || lon == null) return null;
  return formatDistanceMeters(
    Geolocator.distanceBetween(position.latitude, position.longitude, lat, lon),
  );
}
