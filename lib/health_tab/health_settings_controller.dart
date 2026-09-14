import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/user_preferences.dart';

part 'health_settings_controller.g.dart';

/// Whether sync should detect standalone device workouts that have no
/// existing Passe activity (see `HealthSyncController._createStandaloneActivities`
/// in `health_sync_service.dart`) and create an unconfirmed activity for
/// review in "Detected workouts". Defaults to on; some users may not want
/// Passe reasoning about workouts they never opened the app for, even just
/// creating a row that needs a Dismiss tap.
@riverpod
class StandaloneWorkoutSyncSetting extends _$StandaloneWorkoutSyncSetting {
  static const _prefKey = 'standalone_workout_sync_enabled';
  late final UserPreferences _prefs;

  @override
  Future<bool> build() async {
    _prefs = UserPreferences.instance;
    return await _prefs.getBool(_prefKey) ?? true;
  }

  void set(bool value) {
    state = AsyncData(value);
    _prefs.setBool(_prefKey, value);
  }
}
