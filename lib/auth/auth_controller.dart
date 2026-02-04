import 'dart:async';
import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../core/model/pubox_user.dart';
import '../core/model/user_details.dart';
import '../main.dart';
import '../core/user_preferences.dart';

part 'auth_controller.g.dart';

class UsernameTakenException implements Exception {
  const UsernameTakenException();
  @override
  String toString() => 'UsernameTakenException: username + tag_number combination is already taken';
}

@riverpod
class AuthController extends _$AuthController {
  final supabase = Supabase.instance.client;
  final talker = Talker();

  static const _stateKey = 'USER_DATA';

  // Offline cache TTL (24h) + timestamp key
  static const _stateSavedAtKey = 'USER_DATA_SAVED_AT_MS';
  static const Duration _offlineTtl = Duration(hours: 24);

  // Use a getter for the singleton to ensure it's accessed only when needed
  UserPreferences get _userPrefs => UserPreferences.instance;

  @override
  Future<PuboxUser?> build() async {
    // 1. Setup Auth Subscription
    final authSubscription = supabase.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      if (event == AuthChangeEvent.initialSession ||
          event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.userUpdated ||
          event == AuthChangeEvent.tokenRefreshed) {
        // Reload state from server; if offline/unreachable, fall back to cached data (within TTL).
        state = const AsyncValue.loading();

        state = await AsyncValue.guard(() async {
          try {
            return await _loadFromServer();
          } catch (_) {
            return await _loadFromStorage();
          }
        });
      } else if (event == AuthChangeEvent.signedOut) {
        // Clear state
        state = const AsyncValue.loading();
        await _userPrefs.clearUserData();
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
      if (next is AsyncData) {
        _saveToStorage();
      }
    });

    // 4. Guest and/or offline-safe logic
    // Always return cached data (if fresh). Fresh data will be loaded by the
    // auth listener when `initialSession`/`signedIn` fires.
    return _loadFromStorage();
  }

  Future<PuboxUser?> _loadFromStorage() async {
    final savedAtMs = await _userPrefs.getInt(_stateSavedAtKey);
    if (savedAtMs == null) {
      // No timestamp => treat cache as unsafe/stale.
      await _userPrefs.remove(_stateKey);
      return null;
    }

    final savedAt = DateTime.fromMillisecondsSinceEpoch(savedAtMs);
    final isExpired = DateTime.now().difference(savedAt) > _offlineTtl;
    if (isExpired) {
      // TTL exceeded: discard offline cache.
      await _userPrefs.remove(_stateKey);
      await _userPrefs.remove(_stateSavedAtKey);
      return null;
    }

    final jsonifiedString = await _userPrefs.getString(_stateKey);
    if (jsonifiedString == null) return null;

    final Map<String, dynamic> json = jsonDecode(jsonifiedString);
    return PuboxUser.fromJson(json);
  }

  Future<void> _saveToStorage() async {
    final user = state.value;
    if (user != null && supabase.auth.currentSession != null) {
      await _userPrefs.setString(_stateKey, jsonEncode(user.toJson()));
      await _userPrefs.setInt(
        _stateSavedAtKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    }
  }

  // --------------------
  // Auth API wrappers
  // --------------------

  Future<PuboxUser?> signInWithPassword({
    required String email,
    required String password,
  }) async {
    // Subscription handles state updates (initialSession/signedIn/etc.)
    try {
      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      // Let the auth listener update the state; no manual state setting here.
      return null;
    } catch (e, st) {
      talker.handle(e, st);
      rethrow;
    }
  }

  /// OAuth: Google sign-in stub using Supabase
  Future<void> signInWithGoogle() async {
    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        // You may configure redirectTo if needed for web/desktop
        // redirectTo: kIsWeb ? 'http://localhost:3000' : null,
      );
      // State will be updated via the auth listener
    } on AuthException catch (e, st) {
      talker.handle(e, st);
      state = AsyncValue.error(e, st);
      rethrow;
    } catch (e, st) {
      talker.handle(e, st);
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// OAuth: Apple sign-in stub using Supabase
  Future<void> signInWithApple() async {
    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.apple,
      );
      // State will be updated via the auth listener
    } on AuthException catch (e, st) {
      talker.handle(e, st);
      state = AsyncValue.error(e, st);
      rethrow;
    } catch (e, st) {
      talker.handle(e, st);
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<PuboxUser?> signUpWithPassword({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Optionally pass user metadata via `data`
      await supabase.auth.signUp(
        email: email,
        password: password,
        data: data,
      );
      // After sign up, depending on email confirmation settings, there might be no session.
      if (supabase.auth.currentSession == null) {
        // No session yet (e.g., email confirmation required). Keep state null.
        return null;
      }

      // Wait for project-level initiation
      final initialized = await _waitForInitialization();
      if (!initialized) {
        // Initialization did not complete in time;
        // nullify the session and signal retry.
        await supabase.auth.signOut();
        throw TimeoutException(
          'Account initialization did not complete in time. Please try logging in.',
        );
      }

      final user = await _loadFromServer();
      state = AsyncValue.data(user);
      return user;
    } on TimeoutException catch (e, st) {
      // A deliberate timeout to allow the UI to prompt retry
      talker.handle(e, st);
      rethrow;
    } catch (e, st) {
      // report the exception
      talker.handle(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await supabase.auth.signOut();
    } on AuthException catch (e, st) {
      talker.handle(e, st);
      state = AsyncValue.error(e, st);
      rethrow;
    } catch (e, st) {
      talker.handle(e, st);
      state = AsyncValue.error(e, st);
      // report the exception
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
    final tagNumber = data['tag_number'] as String?;
    final email = user.email;
    
    // Safely parse details using fromJson if it exists
    final detailsMap = data['details'];
    final details =
        detailsMap is Map<String, dynamic> ? UserDetails.fromJson(detailsMap) : null;

    return PuboxUser(
      id: user.id,
      username: username ?? 'Guest',
      tagNumber: tagNumber ?? '0000',
      email: email,
      details: details,
    );
  }

  Future<void> continueAsGuest() async {
    state = const AsyncValue.data(PuboxUser());
  }

  Future<void> changeUsername(String newUsername) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final currentUser = state.value;
    final currentTag = currentUser?.tagNumber;
    if (currentTag == null) throw Exception('No tag number');

    // Check for existing (username, tag_number) collision
    final existing = await supabase
        .from('user')
        .select('id')
        .eq('username', newUsername)
        .eq('tag_number', currentTag)
        .maybeSingle();

    if (existing != null && existing['id'] != userId) {
      throw const UsernameTakenException();
    }

    try {
      await supabase
          .from('user')
          .update({'username': newUsername}).eq('id', userId);
    } on PostgrestException catch (e, st) {
      talker.handle(e, st);
      // unique constraint violation from DB race condition
      if (e.code == '23505') {
        throw const UsernameTakenException();
      }
      rethrow;
    }

    await refresh();
  }

  Future<void> changePassword(String newPassword) async {
    try {
      await supabase.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e, st) {
      talker.handle(e, st);
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadFromServer());
  }

  Future<void> _revertToGuest() async {
    await continueAsGuest();
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

  // Waits until the project-level user row exists (created by a DB proc/trigger)
  // or the timeout elapses. Returns true if initialized within the timeout.
  Future<bool> _waitForInitialization({
    Duration timeout = const Duration(seconds: 10),
    Duration interval = const Duration(milliseconds: 250),
  }) async {
    final start = DateTime.now();
    while (DateTime.now().difference(start) < timeout) {
      if (await hasInitialized()) return true;
      await Future.delayed(interval);
    }
    return await hasInitialized();
  }
}