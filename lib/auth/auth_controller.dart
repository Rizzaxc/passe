import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../core/model/passe_user.dart';
import '../core/model/user_details.dart';
import '../core/user_preferences.dart';

part 'auth_controller.g.dart';

/// Single source of truth for the signed-in user's id.
///
/// ALWAYS read the current identity through this provider (or
/// [authControllerProvider] for the full [PasseUser]) — never reach for
/// `Supabase.instance.client.auth.currentUser` directly. The raw Supabase
/// getter bypasses the guest model and the offline cache, and it does not
/// trigger a rebuild when auth state changes.
///
/// Returns `null` for guests and signed-out states, so existing
/// `if (userId == null) return;` guards keep working unchanged.
@riverpod
String? currentUserId(Ref ref) {
  return ref.watch(authControllerProvider).value?.id;
}

class UsernameTakenException implements Exception {
  const UsernameTakenException();
  @override
  String toString() => 'UsernameTakenException: username + tag_number combination is already taken';
}

enum AccountDeletionBlockReason { captain, host }

/// Thrown by [AuthController.deleteAccount] when `request_account_deletion()`
/// rejects the request because the caller still captains a lobby or runs an
/// active freeplay-host profile — both require the user to resolve them
/// first (transfer captaincy / close the host profile), rather than the RPC
/// silently doing it for them. See schema/account_deletion.sql.
class AccountDeletionBlockedException implements Exception {
  final AccountDeletionBlockReason reason;
  const AccountDeletionBlockedException(this.reason);
  @override
  String toString() => 'AccountDeletionBlockedException: $reason';
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
  Future<PasseUser?> build() async {
    // `onAuthStateChange` is backed by a `BehaviorSubject` (see
    // gotrue_client.dart), so it replays the already-fired `initialSession`
    // event to us the instant we `.listen()` below — potentially *during*
    // this very `build()` call, before its return value has been applied as
    // the provider's state. Riverpod doesn't allow assigning `state` before
    // the initial build resolves, so letting that replayed event through
    // here races (and can wedge) the resolution step 4 below already
    // performs for that exact case. Skip only that one first delivery —
    // step 4 already covers it — while still handling every later real
    // event (a subsequent sign-in, token refresh, etc.) normally.
    var skippedReplayedInitialEvent = false;

    // 1. Setup Auth Subscription
    final authSubscription = supabase.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      if (event == AuthChangeEvent.initialSession ||
          event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.userUpdated ||
          event == AuthChangeEvent.tokenRefreshed) {
        if (!skippedReplayedInitialEvent) {
          skippedReplayedInitialEvent = true;
          return;
        }
        // Reload state from server; if offline/unreachable, fall back to cached data (within TTL).
        state = const AsyncValue.loading();

        state = await AsyncValue.guard(() async {
          try {
            return await _loadFromServer();
          } catch (_) {
            return await _loadFromStorage();
          }
        });
      } else if (event == AuthChangeEvent.passwordRecovery) {
        // A recovery session is now active (the user verified the reset OTP)
        // but they haven't chosen a new password yet. Intentionally do NOT
        // publish a signed-in state here — that would let the router navigate
        // away from the reset screen mid-flow. The reset screen completes the
        // flow with updateUser(), whose `userUpdated` event (handled above)
        // then refreshes state and lets the router proceed. See
        // ResetPasswordScreen.
      } else if (event == AuthChangeEvent.signedOut) {
        // Clear state. Capture the outgoing user's id *before* clearing —
        // `UserPreferences._userPrefix` reads `auth.currentUser` live, which
        // is already null by the time this event fires, so without this the
        // clear would wipe the shared 'guest' namespace instead of the
        // user who actually signed out.
        final outgoingUserId = state.value?.id;
        state = const AsyncValue.loading();
        await _userPrefs.clearUserData(outgoingUserId);
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

    // 4. Resolve the initial state.
    // `Supabase.initialize()` in `main()` awaits its own session restoration,
    // so `currentSession` is already populated here for a returning user —
    // load the real user now instead of trusting only our app-level cache.
    // That cache carries its own 24h TTL (`_offlineTtl`) independent of the
    // Supabase session, so it can be empty/expired while the session is
    // still perfectly valid; returning `null` in that case used to resolve
    // `build()` to a signed-out state for one frame, which the router reads
    // as "no user" and bounces to `/welcome` — visible as the welcome
    // flow's first slide flashing before the `initialSession` auth event
    // (handled below) corrects it moments later. Going straight to the
    // server when a session exists avoids that detour entirely.
    if (supabase.auth.currentSession != null) {
      try {
        return await _loadFromServer();
      } catch (_) {
        return _loadFromStorage();
      }
    }
    return _loadFromStorage();
  }

  Future<PasseUser?> _loadFromStorage() async {
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
    return PasseUser.fromJson(json);
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

  Future<PasseUser?> signInWithPassword({
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
      // Always log: Android's Credential Manager backend can report
      // `canceled` for failures that aren't a real user dismissal (provider
      // errors, missing OAuth client registration, etc), so this is the only
      // signal we get for those cases.
      talker.handle(e, st);
      // The user backing out of the picker is not an error worth surfacing.
      if (e.code == GoogleSignInExceptionCode.canceled) return;
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
    // Native `getAppleIDCredential` is only meaningful on Apple platforms —
    // on Android/other platforms it requires `webAuthenticationOptions`
    // (the OAuth/web flow), which Supabase explicitly advises against
    // pairing with `signInWithIdToken`. Guard it out here so the button
    // (also hidden on those platforms in `SocialAuthSection`) can never be
    // reached via some other path either.
    if (!Platform.isIOS && !Platform.isMacOS) {
      throw const AuthException(
        'Sign in with Apple is only available on iOS and macOS.',
      );
    }

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
      // Always log: a user backing out of the native Apple sheet (swipe-dismiss,
      // no iCloud account configured, etc.) doesn't reliably report `canceled` —
      // iOS sometimes reports `unknown` for the same user-initiated dismissal.
      // Treat both as "not an error worth surfacing", matching the Google branch.
      talker.handle(e, st);
      if (e.code == AuthorizationErrorCode.canceled ||
          e.code == AuthorizationErrorCode.unknown) {
        return;
      }
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

  Future<PasseUser?> signUpWithPassword({
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

      // Depending on the project's email-confirmation setting there may be no
      // session yet. Keep state null; the user confirms then signs in later.
      if (supabase.auth.currentSession == null) {
        return null;
      }

      // The `public.user` row is created by the `new_user_created_trigger_fn`
      // AFTER INSERT trigger on `auth.users`, which executes inside the signup
      // transaction. So the moment we hold a session the row is already
      // committed — no polling / retry handshake is needed. (The
      // onAuthStateChange listener also fires `signedIn` and refreshes state;
      // we load here as well so the return value is populated for the caller.)
      final user = await _loadFromServer();
      state = AsyncValue.data(user);
      return user;
    } catch (e, st) {
      talker.handle(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await supabase.auth.signOut().timeout(const Duration(seconds: 5));
      // On success the onAuthStateChange SIGNED_OUT handler in build() emits
      // AsyncData(null); no need to set state here.
    } on AuthException catch (e, st) {
      talker.handle(e, st);
      // A failed sign-out doesn't mean the session is gone — re-derive the real
      // state instead of an error state, which would eject a still-valid session
      // to Welcome.
      state = AsyncData(await _loadFromServer());
      rethrow;
    } catch (e, st) {
      talker.handle(e, st);
      state = AsyncData(await _loadFromServer());
    }
  }

  Future<PasseUser?> _loadFromServer() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final data = await supabase
        .from('user')
        .select('username, tag_number, details, has_password')
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

    return PasseUser(
      id: user.id,
      username: username ?? 'Guest',
      tagNumber: tagNumber ?? '0000',
      email: email,
      details: details,
      hasPassword: data['has_password'] as bool? ?? false,
    );
  }

  Future<void> continueAsGuest() async {
    state = const AsyncValue.data(PasseUser());
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

  /// Whether the current session has an email/password credential set —
  /// false for a user who only ever signed in via Google/Apple and has never
  /// set a password. `identities` covers users who signed up directly with
  /// email/password — stable, since they never go through an OAuth sign-in
  /// that could touch it. `PasseUser.hasPassword` (`public.user.has_password`)
  /// covers an OAuth-only user who added a password afterwards: that can't be
  /// derived from `identities` (`updateUser(password: ...)` alone doesn't add
  /// an email identity) or from Supabase Auth `user_metadata` (Google/Apple
  /// sign-in re-syncs `user_metadata` from the provider's claims on every
  /// login, silently wiping any custom key stored there) — so it's tracked as
  /// our own durable fact instead.
  bool hasPasswordCredential() {
    final hasEmailIdentity = supabase.auth.currentUser?.identities
            ?.any((identity) => identity.provider == 'email') ??
        false;
    return hasEmailIdentity || (state.value?.hasPassword ?? false);
  }

  Future<void> changePassword(String newPassword) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    try {
      await supabase.auth
          .updateUser(UserAttributes(password: newPassword))
          .timeout(const Duration(seconds: 5));
      await supabase
          .from('user')
          .update({'has_password': true})
          .eq('id', userId)
          .timeout(const Duration(seconds: 5));
    } on AuthException catch (e, st) {
      talker.handle(e, st);
      rethrow;
    }

    await refresh();
  }

  /// Deletes the signed-in user's account: `request_account_deletion()`
  /// removes their public-schema data server-side and queues the privileged
  /// `auth.users` deletion (see schema/account_deletion.sql), then this
  /// signs the session out immediately so the app doesn't keep using a
  /// session whose profile is already gone.
  ///
  /// Throws [AccountDeletionBlockedException] if the RPC reports the user
  /// still captains a lobby or runs an active freeplay-host profile — both
  /// need to be resolved by the user first.
  Future<void> deleteAccount() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    try {
      await supabase.rpc('request_account_deletion').timeout(const Duration(seconds: 5));
    } on PostgrestException catch (e, st) {
      talker.handle(e, st);
      if (e.message.contains('Captain cannot leave lobby')) {
        throw const AccountDeletionBlockedException(
          AccountDeletionBlockReason.captain,
        );
      }
      if (e.message.contains('active freeplay host')) {
        throw const AccountDeletionBlockedException(
          AccountDeletionBlockReason.host,
        );
      }
      rethrow;
    }

    await signOut();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadFromServer());
  }

  // --------------------
  // Password recovery (OTP flow)
  // --------------------

  /// Step 1: email the user a recovery code.
  ///
  /// Supabase sends the project's "Reset Password" email; the template must
  /// expose the `{{ .Token }}` (6-digit OTP) for [resetPasswordWithOtp] to
  /// work. We don't pass `redirectTo` — this is a code flow, not a deep link.
  ///
  /// Resolves without error even for unknown emails (Supabase does not reveal
  /// whether the address exists), so the UI can show a neutral confirmation.
  Future<void> sendPasswordResetCode(String email) async {
    try {
      await supabase.auth
          .resetPasswordForEmail(email)
          .timeout(const Duration(seconds: 5));
    } on AuthException catch (e, st) {
      talker.handle(e, st);
      rethrow;
    }
  }

  /// Step 2: verify the recovery [token] and set [newPassword] in one shot.
  ///
  /// `verifyOTP` establishes a short-lived recovery session (fires
  /// `passwordRecovery`, which the listener deliberately ignores), then
  /// `updateUser` changes the password and fires `userUpdated`, which the
  /// listener turns into a signed-in state so the router navigates onward.
  Future<void> resetPasswordWithOtp({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    try {
      await supabase.auth
          .verifyOTP(type: OtpType.recovery, email: email, token: token)
          .timeout(const Duration(seconds: 5));

      await supabase.auth
          .updateUser(UserAttributes(password: newPassword))
          .timeout(const Duration(seconds: 5));
    } on AuthException catch (e, st) {
      talker.handle(e, st);
      rethrow;
    }
  }
}
