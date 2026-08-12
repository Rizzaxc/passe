// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sport_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SoccerProfile _$SoccerProfileFromJson(Map json) => _SoccerProfile(
  position: (json['position'] as List<dynamic>?)
      ?.map((e) => $enumDecode(_$SoccerPositionEnumMap, e))
      .toList(),
  pitch: (json['pitch'] as List<dynamic>?)
      ?.map((e) => $enumDecode(_$SoccerPitchEnumMap, e))
      .toList(),
  eloSeed: $enumDecodeNullable(_$EloSeedEnumMap, json['elo_seed']),
);

Map<String, dynamic> _$SoccerProfileToJson(_SoccerProfile instance) =>
    <String, dynamic>{
      'position': ?instance.position
          ?.map((e) => _$SoccerPositionEnumMap[e]!)
          .toList(),
      'pitch': ?instance.pitch?.map((e) => _$SoccerPitchEnumMap[e]!).toList(),
      'elo_seed': ?_$EloSeedEnumMap[instance.eloSeed],
    };

const _$SoccerPositionEnumMap = {
  SoccerPosition.forward: 'forward',
  SoccerPosition.midfielder: 'midfielder',
  SoccerPosition.defender: 'defender',
  SoccerPosition.keeper: 'keeper',
};

const _$SoccerPitchEnumMap = {
  SoccerPitch.futsal: 'futsal',
  SoccerPitch.fiveASide: '5v5',
  SoccerPitch.sevenASide: '7v7',
};

const _$EloSeedEnumMap = {
  EloSeed.beginner: 'beginner',
  EloSeed.casual: 'casual',
  EloSeed.fair: 'fair',
  EloSeed.good: 'good',
  EloSeed.advanced: 'advanced',
};

_BasketballProfile _$BasketballProfileFromJson(Map json) => _BasketballProfile(
  position: (json['position'] as List<dynamic>?)
      ?.map((e) => $enumDecode(_$BasketballPositionEnumMap, e))
      .toList(),
  pitch: (json['pitch'] as List<dynamic>?)
      ?.map((e) => $enumDecode(_$BasketballPitchEnumMap, e))
      .toList(),
  eloSeed: $enumDecodeNullable(_$EloSeedEnumMap, json['elo_seed']),
);

Map<String, dynamic> _$BasketballProfileToJson(
  _BasketballProfile instance,
) => <String, dynamic>{
  'position': ?instance.position
      ?.map((e) => _$BasketballPositionEnumMap[e]!)
      .toList(),
  'pitch': ?instance.pitch?.map((e) => _$BasketballPitchEnumMap[e]!).toList(),
  'elo_seed': ?_$EloSeedEnumMap[instance.eloSeed],
};

const _$BasketballPositionEnumMap = {
  BasketballPosition.guard: 'guard',
  BasketballPosition.forward: 'forward',
  BasketballPosition.center: 'center',
};

const _$BasketballPitchEnumMap = {
  BasketballPitch.indoor: 'indoor',
  BasketballPitch.outdoor: 'outdoor',
};

_BadmintonProfile _$BadmintonProfileFromJson(Map json) => _BadmintonProfile(
  dominantHand: $enumDecodeNullable(
    _$DominantHandEnumMap,
    json['dominant_hand'],
  ),
  discipline: (json['discipline'] as List<dynamic>?)
      ?.map((e) => $enumDecode(_$RacketDisciplineEnumMap, e))
      .toList(),
  eloSeed: $enumDecodeNullable(_$EloSeedEnumMap, json['elo_seed']),
);

Map<String, dynamic> _$BadmintonProfileToJson(_BadmintonProfile instance) =>
    <String, dynamic>{
      'dominant_hand': ?_$DominantHandEnumMap[instance.dominantHand],
      'discipline': ?instance.discipline
          ?.map((e) => _$RacketDisciplineEnumMap[e]!)
          .toList(),
      'elo_seed': ?_$EloSeedEnumMap[instance.eloSeed],
    };

const _$DominantHandEnumMap = {
  DominantHand.left: 'left',
  DominantHand.right: 'right',
};

const _$RacketDisciplineEnumMap = {
  RacketDiscipline.singles: 'singles',
  RacketDiscipline.doubles: 'doubles',
};

_TennisProfile _$TennisProfileFromJson(Map json) => _TennisProfile(
  dominantHand: $enumDecodeNullable(
    _$DominantHandEnumMap,
    json['dominant_hand'],
  ),
  discipline: (json['discipline'] as List<dynamic>?)
      ?.map((e) => $enumDecode(_$RacketDisciplineEnumMap, e))
      .toList(),
  eloSeed: $enumDecodeNullable(_$EloSeedEnumMap, json['elo_seed']),
);

Map<String, dynamic> _$TennisProfileToJson(_TennisProfile instance) =>
    <String, dynamic>{
      'dominant_hand': ?_$DominantHandEnumMap[instance.dominantHand],
      'discipline': ?instance.discipline
          ?.map((e) => _$RacketDisciplineEnumMap[e]!)
          .toList(),
      'elo_seed': ?_$EloSeedEnumMap[instance.eloSeed],
    };

_PickleballProfile _$PickleballProfileFromJson(Map json) => _PickleballProfile(
  dominantHand: $enumDecodeNullable(
    _$DominantHandEnumMap,
    json['dominant_hand'],
  ),
  discipline: (json['discipline'] as List<dynamic>?)
      ?.map((e) => $enumDecode(_$RacketDisciplineEnumMap, e))
      .toList(),
  eloSeed: $enumDecodeNullable(_$EloSeedEnumMap, json['elo_seed']),
);

Map<String, dynamic> _$PickleballProfileToJson(_PickleballProfile instance) =>
    <String, dynamic>{
      'dominant_hand': ?_$DominantHandEnumMap[instance.dominantHand],
      'discipline': ?instance.discipline
          ?.map((e) => _$RacketDisciplineEnumMap[e]!)
          .toList(),
      'elo_seed': ?_$EloSeedEnumMap[instance.eloSeed],
    };
