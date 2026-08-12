// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_contact_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The signed-in user's own Zalo contact number (`user_contact.zalo`), kept out of the
/// broadly-readable `user.details` jsonb so its visibility (friends / freeplay hosts are
/// public) is enforced by `user_contact`'s RLS, not client code. Plain immediately-
/// persisted writes, same rationale as `PaymentInfoController` — no draft/commit batching
/// benefit here.

@ProviderFor(UserContactController)
final userContactControllerProvider = UserContactControllerProvider._();

/// The signed-in user's own Zalo contact number (`user_contact.zalo`), kept out of the
/// broadly-readable `user.details` jsonb so its visibility (friends / freeplay hosts are
/// public) is enforced by `user_contact`'s RLS, not client code. Plain immediately-
/// persisted writes, same rationale as `PaymentInfoController` — no draft/commit batching
/// benefit here.
final class UserContactControllerProvider
    extends $AsyncNotifierProvider<UserContactController, String?> {
  /// The signed-in user's own Zalo contact number (`user_contact.zalo`), kept out of the
  /// broadly-readable `user.details` jsonb so its visibility (friends / freeplay hosts are
  /// public) is enforced by `user_contact`'s RLS, not client code. Plain immediately-
  /// persisted writes, same rationale as `PaymentInfoController` — no draft/commit batching
  /// benefit here.
  UserContactControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userContactControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userContactControllerHash();

  @$internal
  @override
  UserContactController create() => UserContactController();
}

String _$userContactControllerHash() =>
    r'3edca3b21efa7f5fdc5d7c1d86e613664f8da200';

/// The signed-in user's own Zalo contact number (`user_contact.zalo`), kept out of the
/// broadly-readable `user.details` jsonb so its visibility (friends / freeplay hosts are
/// public) is enforced by `user_contact`'s RLS, not client code. Plain immediately-
/// persisted writes, same rationale as `PaymentInfoController` — no draft/commit batching
/// benefit here.

abstract class _$UserContactController extends $AsyncNotifier<String?> {
  FutureOr<String?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<String?>, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<String?>, String?>,
              AsyncValue<String?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
