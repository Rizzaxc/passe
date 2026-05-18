import 'package:freezed_annotation/freezed_annotation.dart';

import 'enum.dart';

part 'sport_profile.freezed.dart';
part 'sport_profile.g.dart';

@freezed
abstract class SoccerProfile with _$SoccerProfile {
  const factory SoccerProfile({
    List<SoccerPosition>? position,
    List<SoccerPitch>? pitch,
    @JsonKey(name: 'elo_seed') EloSeed? eloSeed,
  }) = _SoccerProfile;

  factory SoccerProfile.fromJson(Map<String, dynamic> json) =>
      _$SoccerProfileFromJson(json);
}

@freezed
abstract class BasketballProfile with _$BasketballProfile {
  const factory BasketballProfile({
    List<BasketballPosition>? position,
    List<BasketballPitch>? pitch,
    @JsonKey(name: 'elo_seed') EloSeed? eloSeed,
  }) = _BasketballProfile;

  factory BasketballProfile.fromJson(Map<String, dynamic> json) =>
      _$BasketballProfileFromJson(json);
}

@freezed
abstract class BadmintonProfile with _$BadmintonProfile {
  const factory BadmintonProfile({
    @JsonKey(name: 'dominant_hand') DominantHand? dominantHand,
    List<RacketDiscipline>? discipline,
    @JsonKey(name: 'elo_seed') EloSeed? eloSeed,
  }) = _BadmintonProfile;

  factory BadmintonProfile.fromJson(Map<String, dynamic> json) =>
      _$BadmintonProfileFromJson(json);
}

@freezed
abstract class TennisProfile with _$TennisProfile {
  const factory TennisProfile({
    @JsonKey(name: 'dominant_hand') DominantHand? dominantHand,
    List<RacketDiscipline>? discipline,
    @JsonKey(name: 'elo_seed') EloSeed? eloSeed,
  }) = _TennisProfile;

  factory TennisProfile.fromJson(Map<String, dynamic> json) =>
      _$TennisProfileFromJson(json);
}

@freezed
abstract class PickleballProfile with _$PickleballProfile {
  const factory PickleballProfile({
    @JsonKey(name: 'dominant_hand') DominantHand? dominantHand,
    List<RacketDiscipline>? discipline,
    @JsonKey(name: 'elo_seed') EloSeed? eloSeed,
  }) = _PickleballProfile;

  factory PickleballProfile.fromJson(Map<String, dynamic> json) =>
      _$PickleballProfileFromJson(json);
}
