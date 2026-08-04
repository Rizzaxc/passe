import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/user_payment_info.dart';

/// The single read path for payment info, own or someone else's.
///
/// Goes through the `get_payment_info` RPC (`schema/user_payment_info.sql`)
/// rather than a direct table select — the table has no RLS policies at
/// all, so a raw select always returns nothing. The RPC decrypts the
/// account/phone number from Supabase Vault and re-checks authorization
/// itself: self is always allowed; anyone else only if they're a friend or
/// lobby mate of [userId] (and not blocked).
Future<List<UserPaymentInfo>> fetchUserPaymentInfo(String userId) => Supabase
    .instance.client
    .rpc('get_payment_info', params: {'p_user_id': userId})
    .timeout(const Duration(seconds: 5))
    .then(
      (rows) => (rows as List)
          .map((r) => UserPaymentInfo.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
