import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/user_preferences.dart';
import 'data.dart';

part 'controller.g.dart';

/// Đá balance — kept in memory, persisted across launches.
///
/// Right now this is seeded from a constant sample value because the
/// currency ledger isn't in the DB yet. Once the backend lands, replace
/// the seed with a Supabase fetch and wire purchase/spend mutations
/// through here instead of mutating the local int directly.
@riverpod
class DaBalance extends _$DaBalance {
  static const _prefKey = 'DA_BALANCE';
  late final UserPreferences _localStorage;

  @override
  Future<int> build() async {
    _localStorage = UserPreferences.instance;
    final stored = await _localStorage.getInt(_prefKey);
    return stored ?? defaultDaBalance;
  }

  Future<void> credit(int amount) async {
    final next = (state.value ?? defaultDaBalance) + amount;
    state = AsyncData(next);
    await _localStorage.setInt(_prefKey, next);
  }

  Future<void> debit(int amount) async {
    final next = (state.value ?? defaultDaBalance) - amount;
    state = AsyncData(next);
    await _localStorage.setInt(_prefKey, next);
  }
}
