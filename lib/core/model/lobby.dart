import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'enum.dart';
import 'timeslot.dart';

part 'lobby.freezed.dart';
part 'lobby.g.dart';

@JsonEnum()
enum LobbyVisibility {
  @JsonValue('private')
  private,
  @JsonValue('discoverable')
  discoverable,
  @JsonValue('public')
  public;

  String getLocalizedName(BuildContext context) {
    return context.tr('lobby.visibility.$name');
  }
}

/// A member's role within a lobby (`lobby_member.role`). Captaincy itself
/// isn't part of this enum — it lives separately on `lobby.captain_id` —
/// this only distinguishes a plain member from a captain-appointed
/// coordinator (everything a captain can do except kick members or edit
/// lobby info; see `schema/lobby_coordinator_role.sql`).
enum LobbyMemberRole {
  member('member'),
  coordinator('coordinator');

  final String value;

  const LobbyMemberRole(this.value);

  static LobbyMemberRole fromValue(String? value) {
    for (final r in LobbyMemberRole.values) {
      if (r.value == value) return r;
    }
    return LobbyMemberRole.member;
  }

  String getLocalizedName(BuildContext context) {
    return context.tr('lobby.memberRole.$name');
  }
}

@freezed
abstract class LobbyDetails with _$LobbyDetails {
  const factory LobbyDetails({
    AgeGroup? ageGroup,
    int? skill,
    // True once a custom photo has been uploaded to the `lobby_avatar`
    // storage bucket at `<lobbyId>.jpg`. False/absent falls back to the
    // deterministic letter-square avatar (see `LobbyAvatar`).
    @Default(false) bool hasAvatar,
  }) = _LobbyDetails;

  factory LobbyDetails.fromJson(Map<String, dynamic> json) =>
      _$LobbyDetailsFromJson(json);
}

@freezed
abstract class Lobby with _$Lobby {
  const factory Lobby({
    String? id,
    @JsonKey(name: 'captain_id') String? captainId,
    @JsonKey(name: 'searchable_id') String? searchableId,
    required String name,
    @JsonKey(name: 'sport_id', fromJson: _sportFromJson, toJson: _sportToJson)
    required Sport sport,
    List<Timeslot>? playtime,
    LobbyDetails? details,
    @JsonKey(name: 'home_ground') String? homeGround,
    @Default(LobbyVisibility.discoverable) LobbyVisibility visibility,
  }) = _Lobby;

  factory Lobby.fromJson(Map<String, dynamic> json) => _$LobbyFromJson(json);
}

Sport _sportFromJson(dynamic value) => Sport.values[value as int];
int _sportToJson(Sport sport) => sport.index;
