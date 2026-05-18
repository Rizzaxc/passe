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

@freezed
abstract class LobbyDetails with _$LobbyDetails {
  const factory LobbyDetails({
    AgeGroup? ageGroup,
    int? skill,
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
