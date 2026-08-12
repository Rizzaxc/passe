import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_controller.dart';

part 'user_contact_controller.g.dart';

/// The signed-in user's own Zalo contact number (`user_contact.zalo`), kept out of the
/// broadly-readable `user.details` jsonb so its visibility (friends / freeplay hosts are
/// public) is enforced by `user_contact`'s RLS, not client code. Plain immediately-
/// persisted writes, same rationale as `PaymentInfoController` — no draft/commit batching
/// benefit here.
@riverpod
class UserContactController extends _$UserContactController {
  @override
  Future<String?> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return null;
    final response = await Supabase.instance.client
        .from('user_contact')
        .select('zalo')
        .eq('user_id', userId)
        .maybeSingle()
        .timeout(const Duration(seconds: 5));
    return response?['zalo'] as String?;
  }

  Future<void> setZalo(String? zalo) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    await Supabase.instance.client
        .from('user_contact')
        .upsert({'user_id': userId, 'zalo': zalo})
        .timeout(const Duration(seconds: 5));
    ref.invalidateSelf();
  }
}
