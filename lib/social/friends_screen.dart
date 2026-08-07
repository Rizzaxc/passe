import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../auth/auth_controller.dart';
import '../router.dart';
import '../ui/main.dart';
import 'friendship_controller.dart';

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
      Talker().handle(e, st, 'Friend search failed');
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

  @override
  Widget build(BuildContext context) {
    final edges = ref.watch(friendshipControllerProvider);
    final incoming = ref.watch(incomingFriendRequestsProvider);
    final friends = ref.watch(friendsProvider);

    return FScaffold(
      header: FHeader(
        title: Text('social.friends'.tr()),
        suffixes: [
          FHeaderAction.back(onPress: () => Navigator.of(context).pop()),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            PSearchField(
              controller: _controller,
              hint: 'social.searchHint'.tr(),
              onChange: _onQueryChanged,
            ),

            if (_searching)
              const Center(child: CircularProgressIndicator())
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
                  ),
            ],

            if (edges.isLoading)
              const Center(child: CircularProgressIndicator())
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
                PEmptySectionPlaceholder(subtitle: 'social.noFriends'.tr())
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

  const _PersonRow({
    required this.userId,
    required this.username,
    required this.tagNumber,
    required this.onTap,
    this.generatedAvatar,
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
      suffix: const Icon(FLucideIcons.chevronRight),
      onPress: onTap,
    );
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
      Talker().handle(e, st, 'Respond to friend request failed');
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
      title: Text(f.username, maxLines: 1, overflow: TextOverflow.ellipsis),
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
