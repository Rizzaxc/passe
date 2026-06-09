import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_health_link.freezed.dart';
part 'user_health_link.g.dart';

enum HealthPlatform {
  @JsonValue('apple_health')
  appleHealth,
  @JsonValue('google_fit')
  googleFit,
  @JsonValue('health_connect')
  healthConnect;

  /// Returns the database value for this platform
  String get dbValue {
    return switch (this) {
      HealthPlatform.appleHealth => 'apple_health',
      HealthPlatform.googleFit => 'google_fit',
      HealthPlatform.healthConnect => 'health_connect',
    };
  }
}

@freezed
abstract class UserHealthLink with _$UserHealthLink {
  const factory UserHealthLink({
    @JsonKey(name: 'user_id') required String userId,
    required HealthPlatform platform,
    @JsonKey(name: 'linked_at') required DateTime linkedAt,
    @JsonKey(name: 'last_sync_at') DateTime? lastSyncAt,

    // Optional user-declared HR thresholds (bpm). Null → app estimates them.
    @JsonKey(name: 'max_heart_rate') int? maxHeartRate,
    @JsonKey(name: 'lt1_bpm') int? lt1Bpm,
    @JsonKey(name: 'lt2_bpm') int? lt2Bpm,
  }) = _UserHealthLink;

  factory UserHealthLink.fromJson(Map<String, dynamic> json) =>
      _$UserHealthLinkFromJson(json);
}
