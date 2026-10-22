/// Which of the five levels a lobby's MMR falls in — drives the MMR tile's
/// 5-step meter (no word: outside the skill picker the number speaks for
/// itself). Bands are centred on the self-declared Elo seeds in
/// `schema/elo_seed_five_tiers.sql` (beginner 700 … advanced 1500, 200
/// apart), with the cut-offs halfway between neighbouring seeds, so the meter
/// lines up with the skill picker's 5 steps.
enum MmrTier {
  newcomer(800),
  weak(1000),
  average(1200),
  good(1400),
  strong(null);

  /// Exclusive upper bound; null for the open-ended top band.
  final int? below;

  const MmrTier(this.below);

  static MmrTier fromMmr(int mmr) =>
      values.firstWhere((t) => t.below == null || mmr < t.below!);

  /// 1-based position, for the segmented meter.
  int get level => index + 1;
}
