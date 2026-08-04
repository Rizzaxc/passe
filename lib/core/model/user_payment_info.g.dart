// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_payment_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserPaymentInfo _$UserPaymentInfoFromJson(Map json) => _UserPaymentInfo(
  id: json['id'] as String,
  bankId: json['bank_id'] as String,
  bankDisplayName: json['bank_display_name'] as String,
  value: json['value'] as String,
  accountName: json['account_name'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$UserPaymentInfoToJson(_UserPaymentInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bank_id': instance.bankId,
      'bank_display_name': instance.bankDisplayName,
      'value': instance.value,
      'account_name': ?instance.accountName,
      'created_at': instance.createdAt.toIso8601String(),
    };
