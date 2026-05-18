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

  /// Removes a value from SharedPreferences.
  Future<bool> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(_namespaceKey(key));
  }

  /// Clears all key-value pairs that belong to the current user.
  ///
  /// This method finds all keys in SharedPreferences that start with the current
  /// user's prefix and removes them. It's useful for cleaning up user data
  /// during logout.
  ///
  /// Returns a Future`<bool>` indicating whether all user data was successfully cleared.
  Future<bool> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userPrefix = _userPrefix;
    final prefixPattern = '${userPrefix}_';

    // Get all keys and filter for current user's keys
    final allKeys = prefs.getKeys();
    final userKeys = allKeys.where((key) => key.startsWith(prefixPattern)).toList();

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
