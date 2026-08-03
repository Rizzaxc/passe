import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/auth_controller.dart';
import '../../core/model/enum.dart';
import 'feed/lobby_controller.dart';

part 'incoming_invites_controller.g.dart';

/// A pending befriend record where the current user is the target — either a
/// lobby captain inviting them (`invite`) or another user proposing to pair
/// up into a brand-new lobby (`pair`). Accepting flips `status` to `accepted`;
/// a DB trigger (`lobby_befriend_accepted_trigger_fn`) then adds membership
/// or creates the paired lobby.
class IncomingInvite {
  final String id;
  final LobbyBefriendKind kind;
  final String inviterUsername;
  final String inviterTag;

  /// The lobby the user is invited into — only set for `invite`. `pair`
  /// creates a fresh lobby on accept, so there's no lobby name to show yet.
  final String? lobbyName;

  /// The sport this invite/pair is for, when resolvable (lobby sport for an
  /// invite, `details.sport_id` for a pair). Used for the sport chip.
  final Sport? sport;

  const IncomingInvite({
    required this.id,
    required this.kind,
    required this.inviterUsername,
    required this.inviterTag,
    this.lobbyName,
    this.sport,
  });
}

enum LobbyBefriendKind { invite, pair }

@riverpod
class IncomingInvitesController extends _$IncomingInvitesController {
  final supabase = Supabase.instance.client;

  @override
  Future<List<IncomingInvite>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const [];

    final response = await supabase
        .from('lobby_befriend_record')
        .select(
          'id, interaction_type, details, '
          'initiator:user!lobby_befriend_record_initiator_user_id_fkey(username, tag_number), '
          'lobby:lobby!lobby_befriend_record_target_lobby_id_fkey(name, sport_id)',
        )
        .eq('target_user_id', userId)
        .inFilter('interaction_type', ['invite', 'pair'])
        .eq('status', 'pending')
        .timeout(const Duration(seconds: 5));

    return (response as List).map((row) {
      final map = row as Map<String, dynamic>;
      final initiator = map['initiator'] as Map<String, dynamic>?;
      final lobby = map['lobby'] as Map<String, dynamic>?;
      final isPair = map['interaction_type'] == 'pair';

      int? sportId;
      if (lobby?['sport_id'] != null) {
        sportId = lobby!['sport_id'] as int;
      } else if (isPair) {
        final details = map['details'] as Map<String, dynamic>?;
        final raw = details?['sport_id'];
        if (raw is int) sportId = raw;
      }
      // Sport encodes its DB id as the enum index (others=0, soccer=1, …).
      final sport = (sportId != null && sportId >= 0 && sportId < Sport.values.length)
          ? Sport.values[sportId]
          : null;

      return IncomingInvite(
        id: map['id'] as String,
        kind: isPair ? LobbyBefriendKind.pair : LobbyBefriendKind.invite,
        inviterUsername: initiator?['username'] as String? ?? 'Guest',
        inviterTag: initiator?['tag_number'] as String? ?? '0000',
        lobbyName: lobby?['name'] as String?,
        sport: sport,
      );
    }).toList();
  }

  Future<void> accept(String recordId) async {
    await supabase
        .from('lobby_befriend_record')
        .update({'status': 'accepted'})
        .eq('id', recordId)
        .timeout(const Duration(seconds: 5));
    ref.invalidateSelf();
    // The trigger just added membership / created a lobby — refresh the list.
    ref.invalidate(userLobbiesControllerProvider);
  }

  Future<void> decline(String recordId) async {
    await supabase
        .from('lobby_befriend_record')
        .update({'status': 'declined'})
        .eq('id', recordId)
        .timeout(const Duration(seconds: 5));
    ref.invalidateSelf();
  }
}
