import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_controller.dart';
import '../logger/talker.dart';
import '../notifications/notification_service.dart';
import '../router.dart';
import '../ui/main.dart';
import 'friendship_controller.dart';
import 'invite_to_passe.dart';
import 'user_page_controller.dart';

/// The friends hub: open requests, the friend list, and a username#tag search
/// to add someone new. Pushed from the Profile tab (below Industry &
/// Network) as a full page — matching the app's other profile sub-screens
/// (see `network_selection_screen.dart`) rather than a bottom sheet, since
/// this has the same multi-section depth as those.
class FriendsScreen extends ConsumerStatefulWidget {
  /// Prefills the search box and runs the search immediately — used when a
  /// caller (e.g. the Discover filter's `username#tag` shortcut) already
  /// knows the exact query, so there's no reason to wait for the debounce.
  final String? initialQuery;

  const FriendsScreen({super.key, this.initialQuery});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final _controller = TextEditingController();
  final _searchFocus = FocusNode();
  List<_UserResult>? _results;
  bool _searching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialQuery?.trim();
    if (initial != null && initial.isNotEmpty) {
      _controller.text = initial;
      WidgetsBinding.instance.addPostFrameCallback((_) => _search());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  /// Fires 1s after the user stops typing, rather than on a "Tìm" button —
  /// short enough to feel live, long enough that a fast typist doesn't fire
  /// a query per keystroke.
  void _onQueryChanged(String _) {
    _debounce?.cancel();
    if (_controller.text.trim().isEmpty) {
      setState(() => _results = null);
      return;
    }
    _debounce = Timer(const Duration(seconds: 1), _search);
  }

  /// Same query shape as `invite_member_sheet.dart` — `name`, `#tag`, or
  /// `name#tag`, partial and case-insensitive on the name.
  Future<void> _search() async {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return;

    setState(() {
      _searching = true;
      _results = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final tagOnly = raw.startsWith('#');
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
        query = query.ilike('username', '%$username%');
      }
      if (tagNumber != null && tagNumber.isNotEmpty) {
        query = query.eq('tag_number', tagNumber);
      }
      if (myId != null) query = query.neq('id', myId);

      final rows = await query.limit(10).timeout(const Duration(seconds: 5));

      if (!mounted) return;
      setState(() {
        _results = (rows as List).map((r) {
          final map = r as Map<String, dynamic>;
          final details = map['details'] as Map<String, dynamic>?;
          return _UserResult(
            id: map['id'] as String,
            username: map['username'] as String,
            tagNumber: map['tag_number'] as String,
            generatedAvatar: details?['generatedAvatar'] as String?,
          );
        }).toList();
      });
    } catch (e, st) {
      talker.handle(e, st, 'Friend search failed');
      if (!mounted) return;
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleX),
        variant: .destructive,
        title: Text('social.searchFailed'.tr()),
        alignment: .bottomCenter,
      );
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _openUser(String id, String name) {
    UserRoute(id: id, $extra: name).push(context);
  }

  /// Where a search result stands relative to the caller, so the row can
  /// offer the one action that makes sense instead of only a chevron.
  FriendState _stateFor(String userId, List<FriendUser> edges) {
    for (final e in edges) {
      if (e.userId != userId) continue;
      return switch (e.direction) {
        FriendDirection.friend => FriendState.friend,
        FriendDirection.incoming => FriendState.incoming,
        FriendDirection.outgoing => FriendState.outgoing,
      };
    }
    return FriendState.none;
  }

  Future<void> _refresh() async {
    ref.invalidate(friendshipControllerProvider);
    await ref.read(friendshipControllerProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final edges = ref.watch(friendshipControllerProvider);
    final incoming = ref.watch(incomingFriendRequestsProvider);
    final friends = ref.watch(friendsProvider);
    final edgeList = edges.value ?? const <FriendUser>[];

    return FScaffold(
      header: FHeader.nested(
        title: Text('social.friends'.tr()),
        prefixes: [
          FHeaderAction.back(onPress: () => Navigator.of(context).pop()),
        ],
      ),
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              PSearchField(
                controller: _controller,
                focusNode: _searchFocus,
                hint: 'social.searchHint'.tr(),
                onChange: _onQueryChanged,
              ),

              if (_searching)
                const Center(child: FCircularProgress())
              else if (_results != null) ...[
                PSectionHeader(title: 'social.searchResults'.tr()),
                if (_results!.isEmpty)
                  Text(
                    'social.noResults'.tr(),
                    style: context.theme.typography.body.sm.copyWith(
                      color: context.theme.colors.mutedForeground,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  )
                else
                  for (final r in _results!)
                    _PersonRow(
                      userId: r.id,
                      username: r.username,
                      tagNumber: r.tagNumber,
                      generatedAvatar: r.generatedAvatar,
                      onTap: () => _openUser(r.id, r.username),
                      action: _SearchResultAction(
                        userId: r.id,
                        state: _stateFor(r.id, edgeList),
                        friendshipId: edgeList
                            .where((e) => e.userId == r.id)
                            .firstOrNull
                            ?.friendshipId,
                      ),
                    ),
              ],

              const InviteToPasseCard(),

              if (edges.isLoading && !edges.hasValue)
                const Center(child: FCircularProgress())
              else if (edges.hasError && !edges.hasValue)
                PEmptySectionPlaceholder(
                  subtitle: 'social.friendsLoadFailed'.tr(),
                  actions: [
                    FButton(
                      size: .sm,
                      variant: .outline,
                      prefix: const Icon(FLucideIcons.refreshCw),
                      onPress: () =>
                          ref.invalidate(friendshipControllerProvider),
                      child: Text('social.retry'.tr()),
                    ),
                  ],
                )
              else ...[
                if (incoming.isNotEmpty) ...[
                  PSectionHeader(title: 'social.incomingRequests'.tr()),
                  for (final f in incoming)
                    _RequestRow(
                      friend: f,
                      onTap: () => _openUser(f.userId, f.username),
                    ),
                ],
                PSectionHeader(title: 'social.friends'.tr()),
                if (friends.isEmpty)
                  // Was a dead end: a sentence and nothing to do about it.
                  PEmptySectionPlaceholder(
                    subtitle: 'social.noFriends'.tr(),
                    actions: [
                      FButton(
                        size: .sm,
                        prefix: const Icon(FLucideIcons.share2),
                        onPress: () => shareInviteToPasse(context, ref),
                        child: Text('social.invitePasse.title'.tr()),
                      ),
                      FButton(
                        size: .sm,
                        variant: .outline,
                        prefix: const Icon(FLucideIcons.search),
                        onPress: () => _searchFocus.requestFocus(),
                        child: Text('social.searchByHandle'.tr()),
                      ),
                    ],
                  )
                else
                  for (final f in friends)
                    _PersonRow(
                      userId: f.userId,
                      username: f.username,
                      tagNumber: f.tagNumber,
                      generatedAvatar: f.generatedAvatar,
                      onTap: () => _openUser(f.userId, f.username),
                    ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

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

class _PersonRow extends StatelessWidget {
  final String userId;
  final String username;
  final String tagNumber;
  final String? generatedAvatar;
  final VoidCallback onTap;

  /// Replaces the chevron when set — e.g. a search result's "Kết bạn".
  final Widget? action;

  const _PersonRow({
    required this.userId,
    required this.username,
    required this.tagNumber,
    required this.onTap,
    this.generatedAvatar,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return FTile(
      prefix: PUserAvatar(
        userId: userId,
        username: username,
        generatedAvatar: generatedAvatar,
        radius: 16,
      ),
      // Name + tag share one Text.rich inside the tile's title slot so the
      // pair ellipsizes together rather than the tag being pushed off alone.
      title: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: username),
            TextSpan(
              text: ' #$tagNumber',
              style: context.theme.typography.body.xs.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      suffix: action ?? const Icon(FLucideIcons.chevronRight),
      onPress: onTap,
    );
  }
}

/// The inline relationship action on a search result — the same states as
/// `/user/:id`'s CTA, compressed to one small control so adding someone
/// doesn't take a detour through their page.
class _SearchResultAction extends ConsumerStatefulWidget {
  final String userId;
  final FriendState state;
  final String? friendshipId;

  const _SearchResultAction({
    required this.userId,
    required this.state,
    this.friendshipId,
  });

  @override
  ConsumerState<_SearchResultAction> createState() =>
      _SearchResultActionState();
}

class _SearchResultActionState extends ConsumerState<_SearchResultAction> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e, st) {
      talker.handle(e, st, 'Friend search action failed');
      if (!mounted) return;
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleX),
        variant: .destructive,
        title: Text('social.actionFailed'.tr()),
        alignment: .bottomCenter,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _add() async {
    final notifier = ref.read(friendshipControllerProvider.notifier);
    await _run(() => notifier.sendRequest(widget.userId));
    if (!mounted) return;
    await ref
        .read(notificationServiceProvider)
        .maybePromptAndRegister(context, ref);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    if (user == null || user.isGuest) {
      return const Icon(FLucideIcons.chevronRight);
    }
    if (_busy) return const FCircularProgress();
    final notifier = ref.read(friendshipControllerProvider.notifier);

    return switch (widget.state) {
      FriendState.none => FButton(
        size: .sm,
        prefix: const Icon(FLucideIcons.userPlus, size: 14),
        onPress: _add,
        child: Text('social.addFriendShort'.tr()),
      ),
      FriendState.outgoing => FButton(
        size: .sm,
        variant: .outline,
        onPress: null,
        child: Text('social.requestSent'.tr()),
      ),
      FriendState.incoming => FButton(
        size: .sm,
        onPress: widget.friendshipId == null
            ? null
            : () => _run(
                () => notifier.respond(widget.friendshipId!, accept: true),
              ),
        child: Text('social.accept'.tr()),
      ),
      FriendState.friend => Text(
        'social.friendLabel'.tr(),
        style: context.theme.typography.body.xs.copyWith(
          color: context.theme.colors.mutedForeground,
        ),
      ),
      FriendState.blocked => const Icon(FLucideIcons.chevronRight),
    };
  }
}

class _RequestRow extends ConsumerStatefulWidget {
  final FriendUser friend;
  final VoidCallback onTap;

  const _RequestRow({required this.friend, required this.onTap});

  @override
  ConsumerState<_RequestRow> createState() => _RequestRowState();
}

class _RequestRowState extends ConsumerState<_RequestRow> {
  bool _busy = false;

  Future<void> _respond(bool accept) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(friendshipControllerProvider.notifier)
          .respond(widget.friend.friendshipId, accept: accept);
    } catch (e, st) {
      talker.handle(e, st, 'Respond to friend request failed');
      if (!mounted) return;
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleX),
        variant: .destructive,
        title: Text('social.actionFailed'.tr()),
        alignment: .bottomCenter,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.friend;
    return FTile(
      prefix: PUserAvatar(
        userId: f.userId,
        username: f.username,
        generatedAvatar: f.generatedAvatar,
        radius: 16,
      ),
      title: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: f.username),
            TextSpan(
              text: ' #${f.tagNumber}',
              style: context.theme.typography.body.xs.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      suffix: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          FButton.icon(
            size: .sm,
            onPress: _busy ? null : () => _respond(true),
            child: const Icon(FLucideIcons.check, size: 14),
          ),
          FButton.icon(
            size: .sm,
            variant: .outline,
            onPress: _busy ? null : () => _respond(false),
            child: const Icon(FLucideIcons.x, size: 14),
          ),
        ],
      ),
      onPress: widget.onTap,
    );
  }
}
