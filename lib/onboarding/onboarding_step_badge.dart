import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Small "X/Y" progress pill shown on each follow-up step's header so the
/// multi-stage post-signup guide (story → profile → coach marks → get
/// started) reads as a bounded, finishing sequence rather than sheets
/// popping up unannounced. Kept against a fixed 4-step total even for a
/// guest, who skips the signed-in-only profile step — an occasional gap in
/// the numbering is a smaller cost than tracking two different totals.
class OnboardingStepBadge extends StatelessWidget {
  final int step;
  final int total;

  /// Use on a dark/overlay background (the coach-mark tour) instead of a
  /// sheet's normal surface.
  final bool light;

  const OnboardingStepBadge({
    super.key,
    required this.step,
    required this.total,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = light ? Colors.white70 : context.theme.colors.mutedForeground;
    return Text(
      '$step/$total',
      style: context.theme.typography.body.sm
          .copyWith(color: color, fontWeight: FontWeight.w600),
    );
  }
}
