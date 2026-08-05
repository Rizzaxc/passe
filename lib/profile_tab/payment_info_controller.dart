import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_controller.dart';
import '../core/model/user_payment_info.dart';
import '../core/payment/payment_info_repository.dart';
import '../core/payment/vietqr_bank.dart';

part 'payment_info_controller.g.dart';

/// The signed-in user's own payment info — capped to one row per user
/// (`user_payment_info_user_id_key`), so this list is always 0 or 1 long.
/// Plain immediately-persisted writes (add upserts, delete clears), unlike
/// `ProfileController`'s draft/commit pattern, since there's no batching
/// benefit here and an add can involve picking a bank from a live form.
@riverpod
class PaymentInfoController extends _$PaymentInfoController {
  @override
  Future<List<UserPaymentInfo>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return [];
    return fetchUserPaymentInfo(userId);
  }

  Future<void> add({
    required VietqrBank bank,
    required String accountNumber,
    String? accountName,
  }) async {
    await Supabase.instance.client.rpc(
      'add_payment_info',
      params: {
        'p_bank_id': bank.bin,
        'p_bank_display_name': bank.shortName,
        'p_value': accountNumber,
        'p_account_name': accountName,
      },
    ).timeout(const Duration(seconds: 5));

    ref.invalidateSelf();
  }

  Future<void> delete(UserPaymentInfo entry) async {
    await Supabase.instance.client
        .rpc('delete_payment_info', params: {'p_id': entry.id})
        .timeout(const Duration(seconds: 5));

    ref.invalidateSelf();
  }
}
