import 'dart:async';
import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/model/pubox_user.dart';
import '../core/model/user_details.dart';
import '../core/user_preferences.dart';

part 'auth_controller.g.dart';

@riverpod
class AuthController extends _$AuthController {
  final supabase = Supabase.instance.client;
  static const _userKey = 'PUBOX_USER';

  // Use a getter for the singleton to ensure it's accessed only when needed
  UserPreferences get _userPrefs => UserPreferences.instance;

  @override
  Future<PuboxUser?> build() async {
    // 1. Setup Auth Subscription
    final authSubscription = supabase.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.userUpdated ||
          event == AuthChangeEvent.tokenRefreshed) {
        // Reload state from server
        state = const AsyncValue.loading();
        state = await AsyncValue.guard(() => _loadFromServer());
      } else if (event == AuthChangeEvent.signedOut) {
        // Clear state
        state = const AsyncValue.loading();
        await _revertToGuest();
        state = const AsyncValue.data(null);
      }
    });

    // 2. Handle Disposal
    ref.onDispose(() {
      authSubscription.cancel();
      _saveToStorage();
    });

    // 3. Persist State Changes
    listenSelf((previous, next) {
      next.whenOrNull(
        data: (user) {
          if (user != null) {
            _userPrefs.setString(_userKey, jsonEncode(user.toJson()));
          }
        },
      );
    });

    // 4. Initial Load Logic
    if (supabase.auth.currentSession == null) {
      return _loadFromStorage();
    }
    return _loadFromServer();
  }

  Future<PuboxUser?> _loadFromStorage() async {
    final jsonifiedString = await _userPrefs.getString(_userKey);
    if (jsonifiedString == null) return null;

    final Map<String, dynamic> json = jsonDecode(jsonifiedString);
    return PuboxUser.fromJson(json);
  }

  Future<void> _saveToStorage() async {
    if (supabase.auth.currentSession == null) return;

    final user = state.value;
    if (user != null) {
      await _userPrefs.setString(_userKey, jsonEncode(user.toJson()));
    }
  }

  Future<PuboxUser?> _loadFromServer() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final data = await supabase
        .from('user')
        .select('username, tag_number, details')
        .eq('id', user.id)
        .maybeSingle();

    if (data == null || data.isEmpty) {
      return null;
    }

    final username = data['username'] as String?;
    // Safely parse details using fromJson if it exists
    final detailsMap = data['details'];
    final details = detailsMap is Map<String, dynamic>
        ? UserDetails.fromJson(detailsMap)
        : null;

    return PuboxUser(id: user.id, displayName: username ?? 'Guest', details: details);
  }

  Future<void> _revertToGuest() async {
    await _userPrefs.clearUserData();
  }

  Future<bool> hasInitialized() async {
    if (supabase.auth.currentSession == null) return false;
    final data = await supabase
        .from('user')
        .select()
        .eq('id', supabase.auth.currentUser!.id)
        .maybeSingle();
    return (data != null && data.isNotEmpty);
  }
}