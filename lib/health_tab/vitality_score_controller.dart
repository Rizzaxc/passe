import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_controller.dart';
import 'model/vitality_score.dart';

part 'vitality_score_controller.g.dart';

/// The signed-in user's most recent Vitality Score (read-only; the evaluator
/// runs on sync, not here). `null` for guests or before the first sync.
/// Pull-to-refresh invalidates this.
@riverpod
Future<VitalityScore?> vitalityScoreSummary(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final rows = await Supabase.instance.client
      .rpc('vitality_score_summary', params: {'p_user_id': userId})
      .timeout(const Duration(seconds: 5));

  final list = rows as List;
  if (list.isEmpty) return null;
  return VitalityScore.fromJson(list.first as Map<String, dynamic>);
}
