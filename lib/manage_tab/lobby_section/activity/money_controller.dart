import 'dart:math';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'money_controller.g.dart';

num _jsonNum(Object? value) => switch (value) {
  final num number => number,
  final String text => num.parse(text),
  _ => throw FormatException('Expected a number, got $value'),
};

class LobbyMoneyEntry {
  final String id;
  final DateTime activityDate;
  final num signedAmount;

  const LobbyMoneyEntry({
    required this.id,
    required this.activityDate,
    required this.signedAmount,
  });

  factory LobbyMoneyEntry.fromJson(Map<String, dynamic> json) =>
      LobbyMoneyEntry(
        id: json['obligation_id'] as String,
        activityDate: DateTime.parse(json['activity_date'] as String).toLocal(),
        signedAmount: _jsonNum(json['signed_amount']),
      );
}

class LobbyMoneyBalance {
  final String userId;
  final String username;
  final String? generatedAvatar;
  final num signedTotal;
  final List<LobbyMoneyEntry> entries;

  const LobbyMoneyBalance({
    required this.userId,
    required this.username,
    this.generatedAvatar,
    required this.signedTotal,
    required this.entries,
  });

  factory LobbyMoneyBalance.fromJson(Map<String, dynamic> json) =>
      LobbyMoneyBalance(
        userId: json['counterparty_id'] as String,
        username: json['username'] as String,
        generatedAvatar: json['generated_avatar'] as String?,
        signedTotal: _jsonNum(json['signed_total']),
        entries: (json['entries'] as List)
            .map(
              (entry) =>
                  LobbyMoneyEntry.fromJson(entry as Map<String, dynamic>),
            )
            .toList(),
      );
}

@riverpod
class LobbyMoneyController extends _$LobbyMoneyController {
  final _supabase = Supabase.instance.client;

  @override
  Future<List<LobbyMoneyBalance>> build(String lobbyId) async {
    final response = await _supabase
        .rpc('lobby_money_data', params: {'p_lobby_id': lobbyId})
        .timeout(const Duration(seconds: 5));
    return (response as List)
        .map((row) => LobbyMoneyBalance.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> settle(
    String counterpartyId, {
    required String idempotencyKey,
  }) async {
    await _supabase
        .rpc(
          'settle_lobby_money',
          params: {
            'p_lobby_id': lobbyId,
            'p_counterparty_id': counterpartyId,
            'p_idempotency_key': idempotencyKey,
          },
        )
        .timeout(const Duration(seconds: 5));

    ref.invalidateSelf();
    await future;
  }
}

String lobbyMoneyIdempotencyKey() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}
