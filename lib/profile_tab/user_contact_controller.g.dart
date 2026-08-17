// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_contact_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The signed-in user's own contact info (`user_contact`: `zalo` + `zalo_public`), kept
/// out of the broadly-readable `user.details` jsonb so its visibility (owner, friends,
/// anyone if `zalo_public`, or a freeplay host is always public) is enforced by
/// `user_contact`'s RLS, not client code. [save] writes immediately — called from
/// `edit_zalo_sheet.dart`'s "Done" button.

@ProviderFor(UserContactController)
final userContactControllerProvider = UserContactControllerProvider._();

/// The signed-in user's own contact info (`user_contact`: `zalo` + `zalo_public`), kept
/// out of the broadly-readable `user.details` jsonb so its visibility (owner, friends,
/// anyone if `zalo_public`, or a freeplay host is always public) is enforced by
/// `user_contact`'s RLS, not client code. [save] writes immediately — called from
/// `edit_zalo_sheet.dart`'s "Done" button.
final class UserContactControllerProvider
    extends $AsyncNotifierProvider<UserContactController, UserContact> {
  /// The signed-in user's own contact info (`user_contact`: `zalo` + `zalo_public`), kept
  /// out of the broadly-readable `user.details` jsonb so its visibility (owner, friends,
  /// anyone if `zalo_public`, or a freeplay host is always public) is enforced by
  /// `user_contact`'s RLS, not client code. [save] writes immediately — called from
  /// `edit_zalo_sheet.dart`'s "Done" button.
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
    r'2b41419dd7d91291cba307415fd422dc8f207926';

/// The signed-in user's own contact info (`user_contact`: `zalo` + `zalo_public`), kept
/// out of the broadly-readable `user.details` jsonb so its visibility (owner, friends,
/// anyone if `zalo_public`, or a freeplay host is always public) is enforced by
/// `user_contact`'s RLS, not client code. [save] writes immediately — called from
/// `edit_zalo_sheet.dart`'s "Done" button.

abstract class _$UserContactController extends $AsyncNotifier<UserContact> {
  FutureOr<UserContact> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<UserContact>, UserContact>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<UserContact>, UserContact>,
              AsyncValue<UserContact>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
