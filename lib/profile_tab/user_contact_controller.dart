import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_controller.dart';
import '../core/model/user_contact.dart';

part 'user_contact_controller.g.dart';

/// The signed-in user's own contact info (`user_contact`: `zalo` + `zalo_public`), kept
/// out of the broadly-readable `user.details` jsonb so its visibility (owner, friends,
/// anyone if `zalo_public`, or a freeplay host is always public) is enforced by
/// `user_contact`'s RLS, not client code. Draft/commit like `NetworkController` /
/// `IndustryController` — edited locally by [updateDraft] (from `edit_zalo_sheet.dart`),
/// only persisted when [commit] runs as part of `ProfileController.commit()`.
@riverpod
class UserContactController extends _$UserContactController {
  UserContact? _initialContact;

  @override
  Future<UserContact> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const UserContact();
    final response = await Supabase.instance.client
        .from('user_contact')
        .select('zalo, zalo_public')
        .eq('user_id', userId)
        .maybeSingle()
        .timeout(const Duration(seconds: 5));
    final contact = response == null
        ? const UserContact()
        : UserContact.fromJson(response);
    _initialContact ??= contact;
    return contact;
  }

  void updateDraft(UserContact contact) {
    state = AsyncData(contact);
  }

  bool get hasUncommittedChanges {
    final initial = _initialContact;
    if (initial == null) return false;
    return state.value != initial;
  }

  void discardChanges() {
    final initial = _initialContact;
    if (initial != null) state = AsyncData(initial);
  }

  void reset() {
    _initialContact = null;
    ref.invalidateSelf();
  }

  Future<void> commit() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final contact = state.value ?? const UserContact();
    await Supabase.instance.client
        .from('user_contact')
        .upsert({
          'user_id': userId,
          'zalo': contact.zalo,
          'zalo_public': contact.zaloPublic,
        })
        .timeout(const Duration(seconds: 5));
    _initialContact = contact;
  }
}
