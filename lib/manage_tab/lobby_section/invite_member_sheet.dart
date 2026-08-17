import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../auth/auth_controller.dart';
import '../../router.dart';
import '../../social/friendship_controller.dart';
import '../../ui/main.dart';
import 'invite_link/invite_link_card.dart';
import 'lobby_detail_controller.dart';
import 'members/controller.dart';

void showInviteMemberSheet(BuildContext context, String lobbyId) {
  showPSheet(
    context: context,
    builder: (_) => _InviteMemberSheet(lobbyId: lobbyId),
  );
}

class _InviteMemberSheet extends ConsumerStatefulWidget {
  final String lobbyId;
  const _InviteMemberSheet({required this.lobbyId});

  @override
  ConsumerState<_InviteMemberSheet> createState() => _InviteMemberSheetState();
}

class _InviteMemberSheetState extends ConsumerState<_InviteMemberSheet> {
  final _userController = TextEditingController();
  List<_UserResult>? _searchResults;
  bool _searching = false;
  bool _sending = false;

  @override
  void dispose() {
    _userController.dispose();
    super.dispose();
  }

  // ── Username / tag search ──────────────────────────────────────

  Future<void> _search() async {
    final raw = _userController.text.trim();
    if (raw.isEmpty) return;

    setState(() {
      _searching = true;
      _searchResults = null;
    });

    try {
      final supabase = Supabase.instance.client;

      final bool tagOnly = raw.startsWith('#');
      final parts = raw.split('#');
      final username = tagOnly ? null : parts[0].trim();
      final tagNumber = parts.length > 1
          ? parts[1].trim()
          : (tagOnly ? parts[0].replaceAll('#', '').trim() : null);

      final myId = ref.read(currentUserIdProvider);

      var query = supabase
          .from('user')
          .select('id, username, tag_number, details');
      if (username != null && username.isNotEmpty) {
        // Partial (case-insensitive) match so users don't need the exact name.
        query = query.ilike('username', '%$username%');
      }
      if (tagNumber != null && tagNumber.isNotEmpty) {
        query = query.eq('tag_number', tagNumber);
      }
      // Never surface yourself as an invite target.
      if (myId != null) {
        query = query.neq('id', myId);
      }
      final rows = await query.limit(10).timeout(const Duration(seconds: 5));

      if (!mounted) return;
      setState(() {
        _searchResults = (rows as List).map((r) {
          final details = r['details'] as Map<String, dynamic>?;
          return _UserResult(
            id: r['id'] as String,
            username: r['username'] as String,
            tagNumber: r['tag_number'] as String,
            generatedAvatar: details?['generatedAvatar'] as String?,
          );
        }).toList();
      });
    } catch (e, st) {
      Talker().handle(e, st, 'User search failed');
      if (!mounted) return;
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleX),
        variant: .destructive,
        title: Text('error'.tr()),
        alignment: .bottomCenter,
      );
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _inviteUser(_UserResult user) async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return;

    setState(() => _sending = true);
    try {
      await Supabase.instance.client
          .from('lobby_befriend_record')
          .insert({
            'initiator_user_id': currentUserId,
            'target_user_id': user.id,
            'target_lobby_id': widget.lobbyId,
            'interaction_type': 'invite',
          })
          .timeout(const Duration(seconds: 5));

      if (!mounted) return;
      Navigator.of(context).pop();
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.userPlus),
        title: Text(
          'lobby.inviteUser.success'.tr(namedArgs: {'username': user.username}),
        ),
        alignment: .bottomCenter,
      );
    } catch (e, st) {
      Talker().handle(e, st, 'Invite user failed');
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('already a member')) {
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.info),
          title: Text('lobby.inviteUser.alreadyMember'.tr()),
          alignment: .bottomCenter,
        );
      } else {
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.circleX),
          variant: .destructive,
          title: Text('lobby.inviteUser.failed'.tr()),
          alignment: .bottomCenter,
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ── Friend shortlist ──────────────────────────────────────────

  Widget _buildFriendShortlist(BuildContext context) {
    final friends = ref.watch(friendsProvider);
    if (friends.isEmpty) return const SizedBox.shrink();

    // Wait for the member list so a current member never flashes in the
    // shortlist before being filtered out.
    final memberIds = ref
        .watch(lobbyMembersControllerProvider(widget.lobbyId))
        .value
        ?.map((m) => m.userId)
        .toSet();
    if (memberIds == null) return const SizedBox.shrink();

    final candidates = friends
        .where((f) => !memberIds.contains(f.userId))
        .take(25)
        .toList();
    if (candidates.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Text(
          'lobby.inviteUser.friendsShortlist'.tr(),
          style: context.theme.typography.body.sm.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(
          height: 78,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: candidates.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final f = candidates[i];
              return _FriendShortlistCard(
                friend: f,
                busy: _sending,
                onInvite: () => _inviteUser(
                  _UserResult(
                    id: f.userId,
                    username: f.username,
                    tagNumber: f.tagNumber,
                    generatedAvatar: f.generatedAvatar,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final canManage =
        ref.watch(myLobbyPermissionProvider(widget.lobbyId)).value?.canManage ??
        false;

    // Content alone (title + search box) is short enough to shrink-wrap
    // to a sliver of the screen; floor it at half height so the sheet
    // reads as a deliberate surface rather than a barely-there strip.
    // The ConstrainedBox sits *inside* the scroll view so it only sets a
    // floor on the content, not the ambient (possibly unbounded) height
    // the scroll view itself is laid out with.
    final minHeight = MediaQuery.sizeOf(context).height * 0.5;

    return SingleChildScrollView(
      primary: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            PSheetTitle(
              label: 'lobby.inviteMember'.tr(),
              trailing: FButton.icon(
                variant: .ghost,
                onPress: () => Navigator.of(context).pop(),
                child: const Icon(FLucideIcons.x),
              ),
            ),

            // The same manager-only instant-join link flow exposed in Lobby
            // Info. Keeping it here makes the Invite Member action the single
            // place for both direct invites and shareable links.
            if (canManage)
              InviteLinkCard(lobbyId: widget.lobbyId, canManage: canManage),

            // Non-member friends, invitable in one tap instead of searching.
            _buildFriendShortlist(context),

            // Username / tag input + search button
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 6,
              children: [
                Text(
                  'lobby.inviteUser.label'.tr(),
                  style: context.theme.typography.body.sm.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 8,
                  children: [
                    Expanded(
                      child: FTextField(
                        hint: 'lobby.inviteUser.hint'.tr(),
                        control: FTextFieldControl.managed(
                          controller: _userController,
                        ),
                      ),
                    ),
                    FButton(
                      variant: .outline,
                      onPress: _searching ? null : _search,
                      child: _searching
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('lobby.inviteUser.search'.tr()),
                    ),
                  ],
                ),
                Text(
                  'lobby.inviteUser.description'.tr(),
                  style: context.theme.typography.body.xs.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ),

            // Search results
            if (_searchResults != null)
              _searchResults!.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'lobby.inviteUser.notFound'.tr(
                          namedArgs: {'name': _userController.text.trim()},
                        ),
                        style: context.theme.typography.body.sm.copyWith(
                          color: colors.mutedForeground,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: context.theme.style.borderRadius.md,
                        border: Border.all(color: colors.border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < _searchResults!.length; i++) ...[
                            _UserRow(
                              user: _searchResults![i],
                              busy: _sending,
                              onInvite: () => _inviteUser(_searchResults![i]),
                            ),
                            if (i < _searchResults!.length - 1)
                              Divider(
                                height: 1,
                                indent: 48,
                                color: colors.border.withValues(alpha: 0.5),
                              ),
                          ],
                        ],
                      ),
                    ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── Models / helpers ────────────────────────────────────────────

class _UserResult {
  final String id;
  final String username;
  final String tagNumber;
  final String? generatedAvatar;

  const _UserResult({
    required this.id,
    required this.username,
    required this.tagNumber,
    this.generatedAvatar,
  });
}

class _FriendShortlistCard extends StatelessWidget {
  final FriendUser friend;
  final bool busy;
  final VoidCallback onInvite;

  const _FriendShortlistCard({
    required this.friend,
    required this.busy,
    required this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return GestureDetector(
      onTap: busy ? null : onInvite,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PUserAvatar(
              userId: friend.userId,
              username: friend.username,
              generatedAvatar: friend.generatedAvatar,
              radius: 24,
              // Own tap target nested inside the card's invite-tap area —
              // wins the gesture arena over the card's GestureDetector, so
              // the avatar opens the profile while the rest of the card
              // still triggers the invite (see root CLAUDE.md's user-row rule).
              onTap: () => UserRoute(id: friend.userId, $extra: friend.username)
                  .push(context),
            ),
            const SizedBox(height: 6),
            Text(
              friend.username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: context.theme.typography.body.xs.copyWith(
                color: colors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final _UserResult user;
  final bool busy;
  final VoidCallback onInvite;

  const _UserRow({
    required this.user,
    required this.busy,
    required this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () =>
                  UserRoute(id: user.id, $extra: user.username).push(context),
              child: Row(
                children: [
                  PUserAvatar(
                    userId: user.id,
                    username: user.username,
                    generatedAvatar: user.generatedAvatar,
                    radius: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: user.username,
                            style: context.theme.typography.body.sm.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text: ' #${user.tagNumber}',
                            style: context.theme.typography.body.xs.copyWith(
                              color: colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          FButton.icon(
            size: .sm,
            onPress: busy ? null : onInvite,
            child: const Icon(FLucideIcons.userPlus, size: 14),
          ),
        ],
      ),
    );
  }
}
