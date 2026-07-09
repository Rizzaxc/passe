import 'package:freezed_annotation/freezed_annotation.dart';

part 'vitality_score.freezed.dart';
part 'vitality_score.g.dart';

/// Supabase returns `numeric`/`real` columns defensively — parse either a
/// JSON number or a numeric string, keeping null as null.
double? _toNullableDouble(Object? v) => switch (v) {
  null => null,
  final num n => n.toDouble(),
  _ => double.tryParse(v.toString()),
};

double _toDouble(Object? v) => _toNullableDouble(v) ?? 0;

/// The signed-in user's most recent Vitality Score, from the
/// `vitality_score_summary` RPC. Balances intensity (training load trend) and
/// consistency, normalized against the user's own trailing history — see
/// `schema/vitality_score.sql`.
@freezed
abstract class VitalityScore with _$VitalityScore {
  const VitalityScore._();

  const factory VitalityScore({
    required DateTime date,
    @JsonKey(fromJson: _toNullableDouble) double? score,
    @JsonKey(name: 'consistency_component', fromJson: _toNullableDouble)
    double? consistencyComponent,
    @JsonKey(name: 'load_component', fromJson: _toNullableDouble)
    double? loadComponent,
    @JsonKey(name: 'recovery_component', fromJson: _toNullableDouble)
    double? recoveryComponent,
    @JsonKey(name: 'volume_component', fromJson: _toNullableDouble)
    double? volumeComponent,
    @Default(0)
    @JsonKey(name: 'streak_bonus', fromJson: _toDouble)
    double streakBonus,
    @JsonKey(fromJson: _toNullableDouble) double? ctl,
    @JsonKey(fromJson: _toNullableDouble) double? atl,
  }) = _VitalityScore;

  factory VitalityScore.fromJson(Map<String, dynamic> json) =>
      _$VitalityScoreFromJson(json);

  /// `false` when the user has under 14 days of eligible history — the score
  /// is a cold-start `NULL`, not a low number.
  bool get hasEnoughData => score != null;
}
