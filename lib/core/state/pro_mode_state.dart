import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../user_preferences.dart';

part 'pro_mode_state.g.dart';

/// Whether a linked professional is currently viewing Manage/Profile as their
/// pro-facing surface instead of the normal player one. Only meaningful when
/// `linkedProfessionalIdProvider` resolves non-null — the toggle that flips
/// this is hidden otherwise. Same shape as `SelectedSportState`.
@riverpod
class ProModeState extends _$ProModeState {
  static const _prefKey = 'PRO_MODE_ACTIVE';
  late final UserPreferences localStorage;

  @override
  FutureOr<bool> build() async {
    localStorage = UserPreferences.instance;
    return await localStorage.getBool(_prefKey) ?? false;
  }

  void set(bool active) {
    state = AsyncData(active);
    localStorage.setBool(_prefKey, active);
  }
}
