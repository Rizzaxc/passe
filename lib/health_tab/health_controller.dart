import 'dart:io';

import 'package:health/health.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_controller.dart';
import '../core/user_preferences.dart';
import 'model/user_health_link.dart';

part 'health_controller.g.dart';

/// HRV record type to request/read. Health Connect (Android) has no
/// SDNN-based record — only `HeartRateVariabilityRmssdRecord` — so requesting
/// SDNN there is a silent no-op (the `health` plugin logs "Datatype
/// HEART_RATE_VARIABILITY_SDNN not found in HC" and returns nothing). iOS
/// HealthKit is the reverse: SDNN is its native HRV metric.
HealthDataType get hrvDataType => Platform.isIOS
    ? HealthDataType.HEART_RATE_VARIABILITY_SDNN
    : HealthDataType.HEART_RATE_VARIABILITY_RMSSD;

/// Platform-native distance types. HealthKit exposes distance per movement
/// category, while Health Connect exposes one aggregate delta record.
List<HealthDataType> healthDistanceDataTypes({bool? isIOS}) =>
    (isIOS ?? Platform.isIOS)
    ? const [
        HealthDataType.DISTANCE_WALKING_RUNNING,
        HealthDataType.DISTANCE_CYCLING,
        HealthDataType.DISTANCE_SWIMMING,
      ]
    : const [HealthDataType.DISTANCE_DELTA];

/// Record used alongside active energy to derive whole-day calories.
///
/// `health` 13.2.1 advertises TOTAL_CALORIES_BURNED on iOS, but its native
/// HealthKit map does not contain that key. Query basal energy instead and add
/// it to active energy when building a daily summary.
HealthDataType healthAdditionalEnergyDataType({bool? isIOS}) =>
    (isIOS ?? Platform.isIOS)
    ? HealthDataType.BASAL_ENERGY_BURNED
    : HealthDataType.TOTAL_CALORIES_BURNED;

/// Health data types we request permission for
List<HealthDataType> get _healthDataTypes => <HealthDataType>[
  // Activity
  HealthDataType.STEPS,
  ...healthDistanceDataTypes(),
  HealthDataType.ACTIVE_ENERGY_BURNED,
  healthAdditionalEnergyDataType(),

  // Heart rate
  HealthDataType.HEART_RATE,
  HealthDataType.RESTING_HEART_RATE,
  hrvDataType,

  // Body
  HealthDataType.WEIGHT,

  // Workout
  HealthDataType.WORKOUT,
];

/// Represents the health service linking status
enum HealthLinkStatus { loading, linked, notLinked, error }

@riverpod
class HealthController extends _$HealthController {
  static const _prefKeyLinked = 'health_linked';
  static const _prefKeyPlatform = 'health_platform';

  final _health = Health();
  final _supabase = Supabase.instance.client;

  @override
  Future<HealthLinkStatus> build() async {
    // Quick check from local cache first
    final prefs = UserPreferences.instance;
    final cachedLinked = await prefs.getBool(_prefKeyLinked);

    if (cachedLinked == true) {
      // Verify permissions are still valid
      final hasPermissions = await _checkHealthPermissions();
      if (hasPermissions) {
        return HealthLinkStatus.linked;
      }
      // Permissions revoked, clear cache and update backend
      await _clearLinkStatus();
    }

    // Check backend for link status
    return _checkBackendLinkStatus();
  }

  /// Check if health permissions are currently granted.
  ///
  /// iOS HealthKit does not expose read-permission status — `hasPermissions`
  /// always returns `null` for READ types. On iOS we trust the cached /
  /// backend link; if the user revokes access in Settings, sync reads
  /// degrade to empty results and they can unlink manually.
  Future<bool> _checkHealthPermissions() async {
    if (Platform.isIOS) return true;

    try {
      await _health.configure();

      final permissions = _healthDataTypes
          .map((type) => HealthDataAccess.READ)
          .toList();

      final hasPermissions = await _health.hasPermissions(
        _healthDataTypes,
        permissions: permissions,
      );

      return hasPermissions ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Check backend for existing health link
  Future<HealthLinkStatus> _checkBackendLinkStatus() async {
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return HealthLinkStatus.notLinked;

      final response = await _supabase
          .from('user_health_link')
          .select()
          .eq('user_id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));

      if (response != null) {
        // User has linked before, verify permissions
        final hasPermissions = await _checkHealthPermissions();
        if (hasPermissions) {
          // Cache locally
          final prefs = UserPreferences.instance;
          await prefs.setBool(_prefKeyLinked, true);
          await prefs.setString(
            _prefKeyPlatform,
            response['platform'] as String,
          );
          return HealthLinkStatus.linked;
        }
        // Permissions were revoked, need to re-link
        return HealthLinkStatus.notLinked;
      }

      return HealthLinkStatus.notLinked;
    } catch (e) {
      return HealthLinkStatus.error;
    }
  }

  /// Request health permissions and link the service
  Future<void> linkHealthService() async {
    state = const AsyncLoading();

    try {
      // Configure health package
      // This may throw on iOS simulator where HealthKit isn't available
      await _health.configure().timeout(const Duration(seconds: 5));

      // Request permissions
      final permissions = _healthDataTypes
          .map((type) => HealthDataAccess.READ)
          .toList();

      // Not timeout-wrapped: this shows the interactive OS permission
      // sheet, gated on the user, like the native sign-in flows.
      final authorized = await _health.requestAuthorization(
        _healthDataTypes,
        permissions: permissions,
      );

      if (!authorized) {
        state = const AsyncData(HealthLinkStatus.notLinked);
        return;
      }

      // Determine platform
      final platform = Platform.isIOS
          ? HealthPlatform.appleHealth
          : HealthPlatform.healthConnect;

      // Save to backend
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) {
        state = AsyncError('User not authenticated', StackTrace.current);
        return;
      }

      await _supabase
          .from('user_health_link')
          .upsert({
            'user_id': userId,
            'platform': platform.dbValue,
            'linked_at': DateTime.now().toUtc().toIso8601String(),
          })
          .timeout(const Duration(seconds: 5));

      // Cache locally
      final prefs = UserPreferences.instance;
      await prefs.setBool(_prefKeyLinked, true);
      await prefs.setString(_prefKeyPlatform, platform.name);

      state = const AsyncData(HealthLinkStatus.linked);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Unlink health service
  Future<void> unlinkHealthService() async {
    state = const AsyncLoading();

    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId != null) {
        await _supabase
            .from('user_health_link')
            .delete()
            .eq('user_id', userId)
            .timeout(const Duration(seconds: 5));
      }

      await _clearLinkStatus();
      state = const AsyncData(HealthLinkStatus.notLinked);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Clear local cache
  Future<void> _clearLinkStatus() async {
    final prefs = UserPreferences.instance;
    await prefs.remove(_prefKeyLinked);
    await prefs.remove(_prefKeyPlatform);
  }

  /// Get the current health link info
  Future<UserHealthLink?> getHealthLink() async {
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return null;

      final response = await _supabase
          .from('user_health_link')
          .select()
          .eq('user_id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));

      if (response == null) return null;
      return UserHealthLink.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Update last sync timestamp
  Future<void> updateLastSync() async {
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;

      await _supabase
          .from('user_health_link')
          .update({'last_sync_at': DateTime.now().toUtc().toIso8601String()})
          .eq('user_id', userId)
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      // Silent fail for sync timestamp update
    }
  }
}
