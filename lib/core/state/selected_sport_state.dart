import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/enum.dart';
import '../user_preferences.dart';

part 'selected_sport_state.g.dart';

@riverpod
class SelectedSportState extends _$SelectedSportState {
  static const _prefKey = 'SELECTED_SPORT';
  late final UserPreferences localStorage;

  int get id => state.value?.index ?? 0;

  @override
  FutureOr<Sport> build() async {
    localStorage = UserPreferences.instance;
    final stored = await localStorage.getInt(_prefKey) ?? 0;
    return Sport.values[stored];
  }

  void change(Sport newSport) {
    state = AsyncData(newSport);
    localStorage.setInt(_prefKey, newSport.index);
  }

  Future<void> saveToStorage() async {
    await localStorage.setInt(_prefKey, id);
  }
}