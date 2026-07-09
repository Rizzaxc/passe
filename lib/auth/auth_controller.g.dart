// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(currentUserId)
final currentUserIdProvider = CurrentUserIdProvider._();

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

final class CurrentUserIdProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
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
  CurrentUserIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserIdHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return currentUserId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$currentUserIdHash() => r'207df8e12be8bb30c45ab64407e9547605e266d1';

@ProviderFor(AuthController)
final authControllerProvider = AuthControllerProvider._();

final class AuthControllerProvider
    extends $AsyncNotifierProvider<AuthController, PasseUser?> {
  AuthControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authControllerHash();

  @$internal
  @override
  AuthController create() => AuthController();
}

String _$authControllerHash() => r'624370e38bda585a437fd990348c4d93235f9208';

abstract class _$AuthController extends $AsyncNotifier<PasseUser?> {
  FutureOr<PasseUser?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<PasseUser?>, PasseUser?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PasseUser?>, PasseUser?>,
              AsyncValue<PasseUser?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
