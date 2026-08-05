import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/user_preferences.dart';

part 'hero_collapse_state.g.dart';

/// Whether the pinned activity hero (`hero.dart`) renders as a slim
/// full-width "Lên Lịch" button instead of its full card. A user density
/// preference toggled from the hero itself, persisted per-user via
/// [UserPreferences] — distinct from `ActivityHero.compact`, which is a
/// transient scroll-position-driven collapse that doesn't survive a rebuild.
@riverpod
class HeroCollapsedState extends _$HeroCollapsedState {
  static const _prefKey = 'ACTIVITY_HERO_COLLAPSED';
  late final UserPreferences _localStorage;

  @override
  FutureOr<bool> build() async {
    _localStorage = UserPreferences.instance;
    return await _localStorage.getBool(_prefKey) ?? false;
  }

  void toggle() {
    final next = !(state.value ?? false);
    state = AsyncData(next);
    _localStorage.setBool(_prefKey, next);
  }
}
