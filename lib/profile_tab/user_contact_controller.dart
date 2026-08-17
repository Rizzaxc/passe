import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_controller.dart';
import '../core/model/user_contact.dart';
import 'write_failure_support.dart';

part 'user_contact_controller.g.dart';

/// The signed-in user's own contact info (`user_contact`: `zalo` + `zalo_public`), kept
/// out of the broadly-readable `user.details` jsonb so its visibility (owner, friends,
/// anyone if `zalo_public`, or a freeplay host is always public) is enforced by
/// `user_contact`'s RLS, not client code. [save] writes immediately — called from
/// `edit_zalo_sheet.dart`'s "Done" button.
@riverpod
class UserContactController extends _$UserContactController {
  late final _failures = WriteFailureHandler(ref);

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
    return response == null
        ? const UserContact()
        : UserContact.fromJson(response);
  }

  Future<void> save(UserContact contact) async {
    state = AsyncData(contact);

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    try {
      await Supabase.instance.client
          .from('user_contact')
          .upsert({
            'user_id': userId,
            'zalo': contact.zalo,
            'zalo_public': contact.zaloPublic,
          })
          .timeout(const Duration(seconds: 5));
    } catch (e, st) {
      _failures.handle(
        e,
        st,
        logMessage: 'Error saving user contact',
        resync: () => ref.invalidateSelf(),
      );
    }
  }
}
