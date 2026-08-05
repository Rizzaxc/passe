import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../user_preferences.dart';
import 'vietqr_bank.dart';

part 'preferred_sending_bank_state.g.dart';

/// The banking app the current user wants Passe to open when they tap
/// "Open in App" to pay someone — deliberately independent of whichever
/// bank/wallet the recipient uses. Only [VietqrBank]s with an [VietqrBank.appId]
/// are valid choices, since that's what makes an app deep-linkable.
///
/// Same persisted-state shape as `SelectedSportState`/`ProModeState`.
@riverpod
class PreferredSendingBankState extends _$PreferredSendingBankState {
  static const _prefKey = 'PREFERRED_SENDING_BANK_BIN';
  late final UserPreferences localStorage;

  @override
  FutureOr<VietqrBank?> build() async {
    localStorage = UserPreferences.instance;
    final bin = await localStorage.getString(_prefKey);
    return bin == null ? null : vietqrBankByBin(bin);
  }

  void set(VietqrBank bank) {
    state = AsyncData(bank);
    localStorage.setString(_prefKey, bank.bin);
  }
}
