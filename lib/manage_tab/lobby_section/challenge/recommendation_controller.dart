import 'package:easy_localization/easy_localization.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/auth_controller.dart';
import '../../../core/model/challenge.dart';

part 'recommendation_controller.g.dart';

/// The verdict this user already cast on one match, if any.
///
/// `lobby_recommendation` is public-readable — the tallies are the point, and
/// an anonymous denouncement is a different, worse product — so this is a plain
/// select rather than an RPC.
@riverpod
Future<LobbyRecommendationKind?> myRecommendation(
  Ref ref,
  String matchId,
) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final row = await Supabase.instance.client
      .from('lobby_recommendation')
      .select('kind')
      .eq('match_id', matchId)
      .eq('voter_id', userId)
      .maybeSingle()
      .timeout(const Duration(seconds: 5));

  return LobbyRecommendationKind.fromDb(row?['kind'] as String?);
}

/// Cast (or change) a post-match verdict on the opposing lobby.
///
/// Changeable inside the 24h window on purpose: a first impression written in
/// the car park is worth less than one written after the group chat has caught
/// up, and a verdict nobody can revise is one people hesitate to give at all.
@riverpod
class RecommendLobbyController extends _$RecommendLobbyController {
  @override
  bool build(String matchId) => false; // in-flight flag

  Future<void> cast({
    required String subjectLobbyId,
    required LobbyRecommendationKind kind,
  }) async {
    state = true;
    try {
      await Supabase.instance.client
          .rpc(
            'recommend_lobby',
            params: {
              'p_match_id': matchId,
              'p_subject_lobby_id': subjectLobbyId,
              'p_kind': kind.rpcValue,
            },
          )
          .timeout(const Duration(seconds: 5));
      ref.invalidate(myRecommendationProvider(matchId));
    } finally {
      state = false;
    }
  }
}

/// Maps `recommend_lobby`'s guards onto Vietnamese copy.
String recommendErrorMessage(Object e) {
  final msg = e.toString();
  if (msg.contains('window to vouch has closed')) {
    return 'challenge.verdictSheet.errorClosed'.tr();
  }
  if (msg.contains('only players who confirmed')) {
    return 'challenge.verdictSheet.errorNotPlayer'.tr();
  }
  if (msg.contains('your own lobby')) {
    return 'challenge.verdictSheet.errorOwnLobby'.tr();
  }
  return 'challenge.verdictSheet.errorGeneric'.tr();
}
