import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'confirmation_controller.dart';

part 'activity_at_risk_response_controller.g.dart';

/// Resolution state of an activity's deadline-passed "at risk" prompt, for
/// the notification card's inline action gating.
enum ActivityAtRiskStatus {
  /// Still awaiting the organizer's or a member's action.
  pending,

  /// Organizer override-confirmed — locked in regardless of turnout.
  confirmed,

  /// Cancelled (organizer action or the kickoff auto-cancel sweep) — the
  /// activity row itself no longer exists.
  cancelled,
}

/// Cheap status-only read for the notification list row's inline state —
/// mirrors `lobbyInviteStatus`'s pattern (avoid pulling full RSVP counts just
/// to know whether to show action buttons or a resolved hint).
@riverpod
Future<ActivityAtRiskStatus> activityAtRiskStatus(
  Ref ref,
  String activityId,
) async {
  final row = await Supabase.instance.client
      .from('activity')
      .select('threshold_override_at')
      .eq('id', activityId)
      .maybeSingle()
      .timeout(const Duration(seconds: 5));
  if (row == null) return ActivityAtRiskStatus.cancelled;
  return row['threshold_override_at'] != null
      ? ActivityAtRiskStatus.confirmed
      : ActivityAtRiskStatus.pending;
}

/// Resolve an "at risk" activity from the notification card — either side of
/// the two-tier action split (see schema/activity_threshold_enforcement.sql):
/// a maybe/never-responded member committing going/out, or the
/// organizer/coordinator overriding-confirm or cancelling. Both bypass the
/// post-deadline RLS freeze via their own SECURITY DEFINER RPC.
///
/// `keepAlive: true` for the same reason as `LobbyInviteResponseController`
/// — only `.notifier` is read here, no active watcher keeps a plain
/// autoDispose instance alive through the `await` gap.
@Riverpod(keepAlive: true)
class ActivityAtRiskResponseController
    extends _$ActivityAtRiskResponseController {
  final supabase = Supabase.instance.client;

  @override
  void build() {}

  Future<void> respondMember(String activityId, {required bool going}) async {
    await supabase
        .rpc(
          'resolve_at_risk_activity_rsvp',
          params: {
            'p_activity_id': activityId,
            'p_attendance': going ? 'going' : 'out',
          },
        )
        .timeout(const Duration(seconds: 5));
    ref.invalidate(activityAtRiskStatusProvider(activityId));
    ref.invalidate(activityConfirmationControllerProvider(activityId));
  }

  Future<void> respondOrganizer(
    String activityId, {
    required bool confirm,
  }) async {
    await supabase
        .rpc(
          'resolve_at_risk_activity_organizer',
          params: {
            'p_activity_id': activityId,
            'p_action': confirm ? 'confirm' : 'cancel',
          },
        )
        .timeout(const Duration(seconds: 5));
    ref.invalidate(activityAtRiskStatusProvider(activityId));
    ref.invalidate(activityConfirmationControllerProvider(activityId));
  }
}
