import 'package:flutter_test/flutter_test.dart';
import 'package:passe/core/user_preferences.dart';
import 'package:passe/manage_tab/lobby_section/lobby_hub_tour.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('tour completion is deduplicated by user id on the device', () async {
    expect(await LobbyHubTourPrefs.hasSeen('user-a'), isFalse);
    expect(await LobbyHubTourPrefs.hasSeen('user-b'), isFalse);

    await LobbyHubTourPrefs.markSeen('user-a');

    expect(await LobbyHubTourPrefs.hasSeen('user-a'), isTrue);
    expect(await LobbyHubTourPrefs.hasSeen('user-b'), isFalse);

    // Logout clears the outgoing user's namespaced preferences, but this
    // device-level ledger must survive so a re-login does not replay it.
    await UserPreferences.instance.clearUserData('user-a');
    expect(await LobbyHubTourPrefs.hasSeen('user-a'), isTrue);

    // Re-marking the same account must remain idempotent.
    await LobbyHubTourPrefs.markSeen('user-a');
    expect(await LobbyHubTourPrefs.hasSeen('user-a'), isTrue);
  });
}
