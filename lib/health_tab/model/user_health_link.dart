import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

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
  }) = _UserHealthLink;

  factory UserHealthLink.fromJson(Map<String, dynamic> json) =>
      _$UserHealthLinkFromJson(json);
}
