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
/// `user_contact`'s RLS, not client code. Draft/commit like `NetworkController` /
/// `IndustryController` — edited locally by [updateDraft] (from `edit_zalo_sheet.dart`),
/// only persisted when [commit] runs as part of `ProfileController.commit()`.

@ProviderFor(UserContactController)
final userContactControllerProvider = UserContactControllerProvider._();

/// The signed-in user's own contact info (`user_contact`: `zalo` + `zalo_public`), kept
/// out of the broadly-readable `user.details` jsonb so its visibility (owner, friends,
/// anyone if `zalo_public`, or a freeplay host is always public) is enforced by
/// `user_contact`'s RLS, not client code. Draft/commit like `NetworkController` /
/// `IndustryController` — edited locally by [updateDraft] (from `edit_zalo_sheet.dart`),
/// only persisted when [commit] runs as part of `ProfileController.commit()`.
final class UserContactControllerProvider
    extends $AsyncNotifierProvider<UserContactController, UserContact> {
  /// The signed-in user's own contact info (`user_contact`: `zalo` + `zalo_public`), kept
  /// out of the broadly-readable `user.details` jsonb so its visibility (owner, friends,
  /// anyone if `zalo_public`, or a freeplay host is always public) is enforced by
  /// `user_contact`'s RLS, not client code. Draft/commit like `NetworkController` /
  /// `IndustryController` — edited locally by [updateDraft] (from `edit_zalo_sheet.dart`),
  /// only persisted when [commit] runs as part of `ProfileController.commit()`.
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
    r'5ac4950f6d3ca5c52250329c6f042c64d689b71a';

/// The signed-in user's own contact info (`user_contact`: `zalo` + `zalo_public`), kept
/// out of the broadly-readable `user.details` jsonb so its visibility (owner, friends,
/// anyone if `zalo_public`, or a freeplay host is always public) is enforced by
/// `user_contact`'s RLS, not client code. Draft/commit like `NetworkController` /
/// `IndustryController` — edited locally by [updateDraft] (from `edit_zalo_sheet.dart`),
/// only persisted when [commit] runs as part of `ProfileController.commit()`.

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
