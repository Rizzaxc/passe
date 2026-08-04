import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_payment_info.freezed.dart';
part 'user_payment_info.g.dart';

/// A user's bank/e-wallet transfer target (`get_payment_info` RPC result).
///
/// The account/phone number is decrypted server-side from Supabase Vault —
/// see `schema/user_payment_info.sql`. There is no direct table access; this
/// model only ever comes from `fetchUserPaymentInfo`
/// (`lib/core/payment/payment_info_repository.dart`).
@freezed
abstract class UserPaymentInfo with _$UserPaymentInfo {
  const factory UserPaymentInfo({
    required String id,
    @JsonKey(name: 'bank_id') required String bankId,
    @JsonKey(name: 'bank_display_name') required String bankDisplayName,
    required String value,
    @JsonKey(name: 'account_name') String? accountName,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _UserPaymentInfo;

  factory UserPaymentInfo.fromJson(Map<String, dynamic> json) =>
      _$UserPaymentInfoFromJson(json);
}
