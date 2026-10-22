import 'package:easy_localization/easy_localization.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/auth_controller.dart';
import '../../logger/talker.dart';
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

  /// Users invited from this sheet in this session — their rows flip to
  /// "Đã mời" instead of the sheet closing after each one.
  final Set<String> _invited = {};

  /// Friends ticked in the shortlist, sent together by one button.
  final Set<String> _selectedFriends = {};

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
      talker.handle(e, st, 'User search failed');
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

  /// Inserts one `invite` befriend record. Returns null on success, or the
  /// error kind for the caller to report.
  Future<_InviteError?> _sendInvite(String userId) async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return _InviteError.failed;
    try {
      await Supabase.instance.client
          .from('lobby_befriend_record')
          .insert({
            'initiator_user_id': currentUserId,
            'target_user_id': userId,
            'target_lobby_id': widget.lobbyId,
            'interaction_type': 'invite',
          })
          .timeout(const Duration(seconds: 5));
      return null;
    } catch (e, st) {
      talker.handle(e, st, 'Invite user failed');
      return e.toString().contains('already a member')
          ? _InviteError.alreadyMember
          : _InviteError.failed;
    }
  }

  void _toast(String title, {bool error = false}) {
    showFToast(
      context: context,
      icon: Icon(error ? FLucideIcons.circleX : FLucideIcons.userPlus),
      variant: error ? FToastVariant.destructive : FToastVariant.primary,
      title: Text(title),
      alignment: .bottomCenter,
    );
  }

  Future<void> _inviteUser(_UserResult user) async {
    setState(() => _sending = true);
    final error = await _sendInvite(user.id);
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (error == null) _invited.add(user.id);
    });
    switch (error) {
      case null:
        _toast(
          'lobby.inviteUser.success'.tr(namedArgs: {'username': user.username}),
        );
      case _InviteError.alreadyMember:
        _toast('lobby.inviteUser.alreadyMember'.tr());
      case _InviteError.failed:
        _toast('lobby.inviteUser.failed'.tr(), error: true);
    }
  }

  /// Sends every ticked friend in one go and reports the outcome once,
  /// naming anyone it couldn't reach rather than failing the whole batch.
  Future<void> _inviteSelected(List<FriendUser> candidates) async {
    final targets = [
      for (final f in candidates)
        if (_selectedFriends.contains(f.userId)) f,
    ];
    if (targets.isEmpty) return;
    setState(() => _sending = true);
    final results = await Future.wait([
      for (final f in targets) _sendInvite(f.userId),
    ]);
    if (!mounted) return;
    final failed = <String>[];
    setState(() {
      _sending = false;
      for (var i = 0; i < targets.length; i++) {
        final f = targets[i];
        _selectedFriends.remove(f.userId);
        if (results[i] == null) {
          _invited.add(f.userId);
        } else {
          failed.add(f.username);
        }
      }
    });
    final sent = targets.length - failed.length;
    if (failed.isEmpty) {
      _toast('lobby.inviteUser.batchSuccess'.tr(namedArgs: {'count': '$sent'}));
    } else {
      _toast(
        'lobby.inviteUser.batchPartial'.tr(
          namedArgs: {'count': '$sent', 'names': failed.join(', ')},
        ),
        error: sent == 0,
      );
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
              final invited = _invited.contains(f.userId);
              return _FriendShortlistCard(
                friend: f,
                busy: _sending,
                invited: invited,
                selected: _selectedFriends.contains(f.userId),
                onToggle: invited
                    ? null
                    : () => setState(() {
                        if (!_selectedFriends.remove(f.userId)) {
                          _selectedFriends.add(f.userId);
                        }
                      }),
              );
            },
          ),
        ),
        if (_selectedFriends.isNotEmpty)
          FButton(
            onPress: _sending ? null : () => _inviteSelected(candidates),
            prefix: _sending ? null : const Icon(FLucideIcons.send),
            child: _sending
                ? const FCircularProgress()
                : Text(
                    'lobby.inviteUser.sendSelected'.tr(
                      namedArgs: {'count': '${_selectedFriends.length}'},
                    ),
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
              InviteLinkCard(lobbyId: widget.lobbyId, canManage: canManage)
            else
              // Members otherwise just see the link card missing, with no
              // hint that it exists or who can make one.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Icon(
                    FLucideIcons.info,
                    size: 16,
                    color: colors.mutedForeground,
                  ),
                  Expanded(
                    child: Text(
                      'lobby.inviteLink.managersOnly'.tr(),
                      style: context.theme.typography.body.xs.copyWith(
                        color: colors.mutedForeground,
                      ),
                    ),
                  ),
                ],
              ),

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
                          ? const FCircularProgress()
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
                              invited: _invited.contains(_searchResults![i].id),
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

enum _InviteError { alreadyMember, failed }

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
  final bool selected;
  final bool invited;
  final VoidCallback? onToggle;

  const _FriendShortlistCard({
    required this.friend,
    required this.busy,
    required this.selected,
    required this.invited,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: busy ? null : onToggle,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Opacity(
                  opacity: invited ? 0.5 : 1,
                  child: PUserAvatar(
                    userId: friend.userId,
                    username: friend.username,
                    generatedAvatar: friend.generatedAvatar,
                    radius: 24,
                    // Own tap target nested inside the card's select-tap
                    // area — wins the gesture arena, so the avatar opens the
                    // profile while the name below toggles selection (see
                    // root CLAUDE.md's user-row rule).
                    onTap: () => UserRoute(
                      id: friend.userId,
                      $extra: friend.username,
                    ).push(context),
                  ),
                ),
                if (selected || invited)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: invited ? colors.mutedForeground : colors.primary,
                        border: Border.all(color: colors.background, width: 2),
                      ),
                      child: Icon(
                        FLucideIcons.check,
                        size: 12,
                        color: colors.primaryForeground,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              invited ? 'lobby.inviteUser.invited'.tr() : friend.username,
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
  final bool invited;
  final VoidCallback onInvite;

  const _UserRow({
    required this.user,
    required this.busy,
    required this.invited,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (invited)
            Text(
              'lobby.inviteUser.invited'.tr(),
              style: context.theme.typography.body.xs.copyWith(
                color: colors.mutedForeground,
              ),
            )
          else
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
