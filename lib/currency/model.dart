import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum DaPayMethod {
  @JsonValue('momo')
  momo('MoMo', 'M', Color(0xFFA50064)),
  @JsonValue('zalopay')
  zalopay('ZaloPay', 'Z', Color(0xFF0073E6)),
  @JsonValue('vietqr')
  vietqr('VietQR Banking', 'QR', Color(0xFF111111)),
  @JsonValue('apple')
  apple('Apple Pay', '', Color(0xFF000000)),
  @JsonValue('promo')
  promo('Khuyến mãi', '★', Color(0xFFF59E0B));

  final String label;
  final String badge;
  final Color badgeBg;

  const DaPayMethod(this.label, this.badge, this.badgeBg);
}

/// Kinds of in-app Đá spending entries.
///
/// `refund` is treated as an incoming Đá movement; everything else is outgoing.
@JsonEnum()
enum DaSpendKind {
  @JsonValue('confirm')
  confirm,
  @JsonValue('venue')
  venue,
  @JsonValue('coach')
  coach,
  @JsonValue('split')
  split,
  @JsonValue('fee')
  fee,
  @JsonValue('refund')
  refund;
}

@JsonEnum()
enum DaPurchaseStatus {
  @JsonValue('success')
  success,
  @JsonValue('failed')
  failed,
}

@JsonEnum()
enum DaSpendStatus {
  @JsonValue('settled')
  settled,
  @JsonValue('pending')
  pending,
}

/// Money → Đá movement.
class DaPurchase {
  final String id;
  final String date; // dd/MM
  final String time; // HH:mm
  final int amount; // base Đá
  final int bonus; // promo bonus Đá
  final int paid; // VND
  final DaPayMethod method;
  final String label;
  final DaPurchaseStatus status;

  const DaPurchase({
    required this.id,
    required this.date,
    required this.time,
    required this.amount,
    required this.bonus,
    required this.paid,
    required this.method,
    required this.label,
    required this.status,
  });

  int get totalDa => amount + bonus;
}

/// Đá → activity movement (or refund back to balance).
class DaSpending {
  final String id;
  final String date; // dd/MM
  final String time; // HH:mm
  final int amount;
  final DaSpendKind kind;
  final String label;
  final String detail;
  final DaSpendStatus status;

  const DaSpending({
    required this.id,
    required this.date,
    required this.time,
    required this.amount,
    required this.kind,
    required this.label,
    required this.detail,
    this.status = DaSpendStatus.settled,
  });

  bool get isIncoming => kind == DaSpendKind.refund;
}

class DaPackage {
  final String id;
  final int da;
  final int price; // VND
  final int bonus;
  final String? tag;

  const DaPackage({
    required this.id,
    required this.da,
    required this.price,
    required this.bonus,
    this.tag,
  });

  int get totalDa => da + bonus;
}
