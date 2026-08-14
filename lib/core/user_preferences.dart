import 'package:shared_preferences/shared_preferences.dart';

import 'utils.dart';

/// A wrapper around SharedPreferences that namespaces keys by user.
///
/// This class provides methods to get and set values in SharedPreferences
/// with keys that are namespaced by the current user's ID. If the user is
/// not logged in, the keys are namespaced with 'guest'.
class UserPreferences {
  static const String _guestPrefix = 'guest';

  /// Creates a new instance of UserPreferences.
  UserPreferences._();

  static final _instance = UserPreferences._();

  /// Returns the singleton instance of UserPreferences.
  static UserPreferences get instance => _instance;

  /// Returns the current user prefix.
  ///
  /// If the user is logged in, this returns their user ID.
  /// Otherwise, it returns the guest prefix.
  ///
  /// Sanctioned exception to the "never read `auth.currentUser` directly" rule
  /// (the other being `AuthController`). `UserPreferences` is a synchronous
  /// singleton that `AuthController` itself depends on to cache the user, so it
  /// cannot route through `currentUserIdProvider` (which is async and needs a
  /// `ref`) without creating a dependency cycle. The raw getter is read-only
  /// here and only used to namespace SharedPreferences keys.
  String get _userPrefix {
    final user = supabase.auth.currentUser;
    return user?.id ?? _guestPrefix;
  }

  /// Namespaces a key with the current user prefix.
  String _namespaceKey(String key) => '${_userPrefix}_$key';

  /// Gets a boolean value from SharedPreferences.
  Future<bool?> getBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_namespaceKey(key));
  }

  /// Sets a boolean value in SharedPreferences.
  Future<bool> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_namespaceKey(key), value);
  }

  /// Gets an integer value from SharedPreferences.
  Future<int?> getInt(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_namespaceKey(key));
  }

  /// Sets an integer value in SharedPreferences.
  Future<bool> setInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_namespaceKey(key), value);
  }

  /// Gets a double value from SharedPreferences.
  Future<double?> getDouble(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_namespaceKey(key));
  }

  /// Sets a double value in SharedPreferences.
  Future<bool> setDouble(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setDouble(_namespaceKey(key), value);
  }

  /// Gets a string value from SharedPreferences.
  Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_namespaceKey(key));
  }

  /// Sets a string value in SharedPreferences.
  Future<bool> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_namespaceKey(key), value);
  }

  /// Gets a list of strings from SharedPreferences.
  Future<List<String>?> getStringList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_namespaceKey(key));
  }

  /// Sets a list of strings in SharedPreferences.
  Future<bool> setStringList(String key, List<String> value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(_namespaceKey(key), value);
  }

  /// Gets a device-wide string list that deliberately is not namespaced by
  /// the current user.
  ///
  /// Most app state belongs in the per-user methods above. This escape hatch
  /// is for device-level account bookkeeping that must survive logout, when
  /// [clearUserData] removes every value in the outgoing user's namespace.
  Future<List<String>?> getDeviceStringList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key);
  }

  /// Sets a device-wide string list. See [getDeviceStringList].
  Future<bool> setDeviceStringList(String key, List<String> value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(key, value);
  }

  /// Removes a value from SharedPreferences.
  Future<bool> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(_namespaceKey(key));
  }

  /// Copies [key]'s value from the device's guest namespace into the current
  /// user's namespace, only if the current user has no value for it yet, then
  /// removes the guest-namespaced copy. No-op when the current user *is* the
  /// guest namespace.
  ///
  /// Guests share a single `'guest'`-prefixed namespace and gain a stable id
  /// only once they sign up (see [_userPrefix]), so state written while
  /// guest (e.g. "has seen onboarding") doesn't automatically carry over to
  /// the new namespace a sign-up creates. This is the bridge for that.
  ///
  /// The guest key is deleted (consumed) once adopted, not left behind: this
  /// namespace is shared by every unauthenticated session on the device, so
  /// a stale value from one guest/account would otherwise silently get
  /// re-adopted by the *next*, unrelated account that signs up on the same
  /// device — e.g. a device that once finished onboarding as a guest would
  /// permanently exempt every future signup from onboarding too, regardless
  /// of who they are.
  Future<void> adoptGuestValue(String key) async {
    final currentPrefix = _userPrefix;
    if (currentPrefix == _guestPrefix) return;

    final prefs = await SharedPreferences.getInstance();
    final guestKey = '${_guestPrefix}_$key';
    final currentKey = '${currentPrefix}_$key';
    if (prefs.containsKey(currentKey)) {
      await prefs.remove(guestKey);
      return;
    }

    final value = prefs.get(guestKey);
    switch (value) {
      case bool v:
        await prefs.setBool(currentKey, v);
      case int v:
        await prefs.setInt(currentKey, v);
      case double v:
        await prefs.setDouble(currentKey, v);
      case String v:
        await prefs.setString(currentKey, v);
      case List<String> v:
        await prefs.setStringList(currentKey, v);
      case null:
        break;
    }
    await prefs.remove(guestKey);
  }

  /// Clears all key-value pairs that belong to the current user.
  ///
  /// This method finds all keys in SharedPreferences that start with the current
  /// user's prefix and removes them. It's useful for cleaning up user data
  /// during logout.
  ///
  /// Pass [prefix] to clear a specific namespace (e.g. the just-signed-out
  /// user's id, captured before their session ends) instead of whatever
  /// [_userPrefix] resolves to *now* — by the time a sign-out completes,
  /// `auth.currentUser` is already null and this would otherwise wipe the
  /// shared `'guest'` namespace instead.
  ///
  /// Returns a Future`<bool>` indicating whether all user data was successfully cleared.
  Future<bool> clearUserData([String? prefix]) async {
    final prefs = await SharedPreferences.getInstance();
    final userPrefix = prefix ?? _userPrefix;
    final prefixPattern = '${userPrefix}_';

    // Get all keys and filter for current user's keys
    final allKeys = prefs.getKeys();
    final userKeys = allKeys
        .where((key) => key.startsWith(prefixPattern))
        .toList();

    // Remove all user-specific keys
    bool allRemoved = true;
    for (final key in userKeys) {
      final removed = await prefs.remove(key);
      if (!removed) {
        allRemoved = false;
      }
    }

    return allRemoved;
  }
}
