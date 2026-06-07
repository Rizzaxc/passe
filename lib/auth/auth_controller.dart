import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../core/model/pubox_user.dart';
import '../core/model/user_details.dart';
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

  // Native Google sign-in configuration.
  // - iOS client id is required for the native iOS flow (also drives the
  //   reversed-client-id URL scheme in Info.plist).
  // - The "Web" OAuth client id is passed as `serverClientId` so the returned
  //   ID token's audience matches what Supabase is configured to trust.
  static final String? _googleIosClientId = dotenv.env['GOOGLE_IOS_CLIENT_ID'];
  static final String? _googleWebClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];

  // `GoogleSignIn.instance.initialize` must run exactly once per app lifecycle;
  // cache the future so concurrent/repeat sign-in taps reuse it.
  static Future<void>? _googleInitFuture;

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
      ).timeout(const Duration(seconds: 5));
      // Let the auth listener update the state; no manual state setting here.
      return null;
    } catch (e, st) {
      talker.handle(e, st);
      rethrow;
    }
  }

  /// Native Google sign-in.
  ///
  /// Uses the platform account picker to obtain an ID token, then exchanges it
  /// with Supabase via [signInWithIdToken] — no browser round-trip / deep link.
  /// The resulting session is propagated through the [onAuthStateChange]
  /// listener set up in [build]; we deliberately do not set [state] here so a
  /// failure or cancellation can't strand the router on an error screen.
  ///
  /// No `.timeout` is applied: this is an interactive flow gated on the user,
  /// not a background RPC.
  Future<void> signInWithGoogle() async {
    try {
      await _ensureGoogleInitialized();

      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: const ['email', 'profile'],
      );

      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthException('Google sign-in did not return an ID token.');
      }

      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
    } on GoogleSignInException catch (e, st) {
      // The user backing out of the picker is not an error worth surfacing.
      if (e.code == GoogleSignInExceptionCode.canceled) return;
      talker.handle(e, st);
      rethrow;
    } catch (e, st) {
      talker.handle(e, st);
      rethrow;
    }
  }

  /// Native Apple sign-in.
  ///
  /// Generates a raw nonce, sends its SHA-256 hash to Apple (embedded in the
  /// returned identity token), and hands the raw nonce to Supabase so it can
  /// verify the token wasn't replayed. Session propagation matches
  /// [signInWithGoogle].
  Future<void> signInWithApple() async {
    try {
      final rawNonce = _generateRawNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw const AuthException(
          'Apple sign-in did not return an identity token.',
        );
      }

      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
    } on SignInWithAppleAuthorizationException catch (e, st) {
      if (e.code == AuthorizationErrorCode.canceled) return;
      talker.handle(e, st);
      rethrow;
    } catch (e, st) {
      talker.handle(e, st);
      rethrow;
    }
  }

  Future<void> _ensureGoogleInitialized() {
    return _googleInitFuture ??= GoogleSignIn.instance.initialize(
      clientId: _googleIosClientId,
      serverClientId: _googleWebClientId,
    );
  }

  /// Cryptographically-secure random string used as the OAuth nonce.
  String _generateRawNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
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
      ).timeout(const Duration(seconds: 5));
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
        await supabase.auth.signOut().timeout(const Duration(seconds: 5));
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
      await supabase.auth.signOut().timeout(const Duration(seconds: 5));
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
        .maybeSingle()
        .timeout(const Duration(seconds: 5));

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
        .maybeSingle()
        .timeout(const Duration(seconds: 5));

    if (existing != null && existing['id'] != userId) {
      throw const UsernameTakenException();
    }

    try {
      await supabase
          .from('user')
          .update({'username': newUsername})
          .eq('id', userId)
          .timeout(const Duration(seconds: 5));
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
      await supabase.auth
          .updateUser(UserAttributes(password: newPassword))
          .timeout(const Duration(seconds: 5));
    } on AuthException catch (e, st) {
      talker.handle(e, st);
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadFromServer());
  }

  Future<bool> hasInitialized() async {
    if (supabase.auth.currentSession == null) return false;
    final data = await supabase
        .from('user')
        .select()
        .eq('id', supabase.auth.currentUser!.id)
        .maybeSingle()
        .timeout(const Duration(seconds: 5));
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