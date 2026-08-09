import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../user_preferences.dart';

part 'host_mode_state.g.dart';

@riverpod
class HostModeState extends _$HostModeState {
  static const _prefKey = 'HOST_MODE_ACTIVE';
  late final UserPreferences _preferences;

  @override
  FutureOr<bool> build() async {
    _preferences = UserPreferences.instance;
    return await _preferences.getBool(_prefKey) ?? false;
  }

  void set(bool active) {
    state = AsyncData(active);
    _preferences.setBool(_prefKey, active);
  }
}
