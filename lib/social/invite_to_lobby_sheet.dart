import 'package:easy_localization/easy_localization.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_controller.dart';
import '../logger/talker.dart';
import '../manage_tab/lobby_section/feed/lobby_controller.dart';
import '../manage_tab/lobby_section/feed/lobby_form_sheet.dart';
import '../ui/main.dart';

/// `/user/:id` ▸ "Mời vào lobby": the reverse of the lobby invite sheet —
/// start from a friend and pick which of your lobbies to bring them into.
/// Sends the same `invite` befriend record `invite_member_sheet.dart` does.
Future<void> showInviteToLobbySheet(
  BuildContext context, {
  required String userId,
  required String username,
}) {
  return showPSheet<void>(
    context: context,
    builder: (_) => _InviteToLobbySheet(userId: userId, username: username),
  );
}

/// Ids of the caller's lobbies [userId] already belongs to. The caller can
/// read their own lobbies' rosters, which is all this needs. Keyed by a
/// comma-joined id string, not a List — a List key compares by identity and
/// would refetch on every rebuild.
final _targetMembershipsProvider = FutureProvider.autoDispose
    .family<Set<String>, (String, String)>((ref, args) async {
      final (userId, joinedIds) = args;
      final lobbyIds = joinedIds.isEmpty
          ? const <String>[]
          : joinedIds.split(',');
      if (lobbyIds.isEmpty) return const {};
      final rows = await Supabase.instance.client
          .from('lobby_member')
          .select('lobby_id')
          .eq('user_id', userId)
          .inFilter('lobby_id', lobbyIds)
          .timeout(const Duration(seconds: 5));
      return {for (final r in rows as List) r['lobby_id'] as String};
    });

class _InviteToLobbySheet extends ConsumerStatefulWidget {
  final String userId;
  final String username;

  const _InviteToLobbySheet({required this.userId, required this.username});

  @override
  ConsumerState<_InviteToLobbySheet> createState() =>
      _InviteToLobbySheetState();
}

class _InviteToLobbySheetState extends ConsumerState<_InviteToLobbySheet> {
  final Set<String> _invited = {};
  String? _sendingTo;

  Future<void> _invite(LobbyListItem item) async {
    final me = ref.read(currentUserIdProvider);
    final lobbyId = item.lobby.id;
    if (me == null || lobbyId == null) return;
    setState(() => _sendingTo = lobbyId);
    try {
      await Supabase.instance.client
          .from('lobby_befriend_record')
          .insert({
            'initiator_user_id': me,
            'target_user_id': widget.userId,
            'target_lobby_id': lobbyId,
            'interaction_type': 'invite',
          })
          .timeout(const Duration(seconds: 5));
      if (!mounted) return;
      setState(() => _invited.add(lobbyId));
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.userPlus),
        title: Text(
          'social.inviteToLobbySent'.tr(
            namedArgs: {'name': widget.username, 'lobby': item.lobby.name},
          ),
        ),
        alignment: .bottomCenter,
      );
    } catch (e, st) {
      talker.handle(e, st, 'Invite friend to lobby failed');
      if (!mounted) return;
      final alreadyMember = e.toString().contains('already a member');
      showFToast(
        context: context,
        icon: Icon(alreadyMember ? FLucideIcons.info : FLucideIcons.circleX),
        variant: alreadyMember
            ? FToastVariant.primary
            : FToastVariant.destructive,
        title: Text(
          alreadyMember
              ? 'lobby.inviteUser.alreadyMember'.tr()
              : 'lobby.inviteUser.failed'.tr(),
        ),
        alignment: .bottomCenter,
      );
    } finally {
      if (mounted) setState(() => _sendingTo = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final lobbiesAsync = ref.watch(userLobbiesControllerProvider);
    final lobbies = lobbiesAsync.value ?? const <LobbyListItem>[];
    final membershipsAsync = ref.watch(
      _targetMembershipsProvider((
        widget.userId,
        ([for (final l in lobbies) ?l.lobby.id]..sort()).join(','),
      )),
    );

    Widget body;
    if (lobbiesAsync.isLoading || membershipsAsync.isLoading) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: FCircularProgress()),
      );
    } else if (lobbiesAsync.hasError || membershipsAsync.hasError) {
      body = PEmptySectionPlaceholder(subtitle: 'errorGeneric'.tr());
    } else {
      final already = membershipsAsync.value ?? const <String>{};
      final candidates = [
        for (final l in lobbies)
          if (!already.contains(l.lobby.id)) l,
      ];
      body = candidates.isEmpty
          ? PEmptySectionPlaceholder(
              subtitle: 'social.inviteToLobbyEmpty'.tr(
                namedArgs: {'name': widget.username},
              ),
              actions: [
                FButton(
                  size: .sm,
                  prefix: const Icon(FLucideIcons.plus),
                  onPress: () {
                    Navigator.of(context).pop();
                    createLobbyAndOpen(context, ref);
                  },
                  child: Text('social.inviteToLobbyCreate'.tr()),
                ),
              ],
            )
          : FTileGroup(
              children: [
                for (final item in candidates)
                  FTile(
                    prefix: LobbyAvatar(
                      lobbyId: item.lobby.id,
                      name: item.lobby.name,
                      hasAvatar: item.lobby.details?.hasAvatar ?? false,
                      size: 36,
                      borderRadius: BorderRadius.circular(10),
                      backgroundColor: colors.secondary,
                      foregroundColor: colors.primary,
                    ),
                    title: Text(
                      item.lobby.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${item.lobby.sport.getLocalizedName(context)} · '
                      '${'social.memberCount'.tr(namedArgs: {'count': '${item.memberCount}'})}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    suffix: _invited.contains(item.lobby.id)
                        ? Text(
                            'social.inviteToLobbyPending'.tr(),
                            style: context.theme.typography.body.xs.copyWith(
                              color: colors.mutedForeground,
                            ),
                          )
                        : _sendingTo == item.lobby.id
                        ? const FCircularProgress()
                        : const Icon(FLucideIcons.userPlus, size: 18),
                    onPress:
                        _invited.contains(item.lobby.id) || _sendingTo != null
                        ? null
                        : () => _invite(item),
                  ),
              ],
            );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          PSheetTitle(
            label: 'social.inviteToLobbyTitle'.tr(
              namedArgs: {'name': widget.username},
            ),
            trailing: FButton.icon(
              variant: .ghost,
              onPress: () => Navigator.of(context).pop(),
              child: const Icon(FLucideIcons.x),
            ),
          ),
          body,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
