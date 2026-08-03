import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'activity/main.dart';
import 'history/view.dart';
import 'lobby_avatar.dart';
import 'lobby_detail_controller.dart';
import 'lobby_info_sheet.dart';

const _crimson = Color(0xFFDC143C);
const _crimsonTint = Color(0xFFFFEBED);

class LobbyDetailPage extends ConsumerStatefulWidget {
  final String lobbyId;
  final String? lobbyName;

  const LobbyDetailPage({super.key, required this.lobbyId, this.lobbyName});

  @override
  ConsumerState<LobbyDetailPage> createState() => _LobbyDetailPageState();
}

class _LobbyDetailPageState extends ConsumerState<LobbyDetailPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final infoAsync = ref.watch(lobbyDetailControllerProvider(widget.lobbyId));
    final colors = context.theme.colors;

    final lobbyName = infoAsync.value?.lobby.name ?? widget.lobbyName ?? '';
    // The activity tab's actions (schedule/reschedule/cancel, poll,
    // invite-to-challenge) are all coordinator-eligible — none of them
    // are kicking or editing lobby info — so this passes "can manage",
    // not strictly "is captain".
    final canManage =
        ref.watch(myLobbyPermissionProvider(widget.lobbyId)).value?.canManage ??
        false;
    final sport = infoAsync.value?.lobby.sport;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Custom header — avatar + name only, with overflow access
            // to the info sheet. Back nav is handled by system gesture.
            _LobbyHeader(
              lobbyId: widget.lobbyId,
              lobbyName: lobbyName,
              hasAvatar: infoAsync.value?.lobby.details?.hasAvatar ?? false,
              onInfoTap: () {
                if (infoAsync.value != null) {
                  showLobbyInfoSheet(context, infoAsync.value!, widget.lobbyId);
                }
              },
            ),

            // Tabs — horizontal padding matches the 14-px inset the
            // hero / feed / history cards use, so the tab indicator's
            // edges line up with the content underneath.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: FTabs(
                  expands: true,
                  contentPhysics: const NeverScrollableScrollPhysics(),
                  control: FTabControl.lifted(
                    index: _currentIndex,
                    onChange: (i) => setState(() => _currentIndex = i),
                  ),
                  children: [
                    FTabEntry(
                      label: const Icon(FLucideIcons.activity),
                      child: ActivityTab(
                        lobbyId: widget.lobbyId,
                        isLeader: canManage,
                        sport: sport,
                        captainId: infoAsync.value?.lobby.captainId,
                      ),
                    ),
                    FTabEntry(
                      label: const Icon(FLucideIcons.clock),
                      child: HistoryView(
                        lobbyId: widget.lobbyId,
                        lobbyName: lobbyName,
                        canRecord: ref
                                .watch(myLobbyPermissionProvider(widget.lobbyId))
                                .value
                                ?.isCaptain ??
                            false,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ────────────────────────────────────────────────────

/// Slim lobby-detail header: oversize letter avatar + name, with a
/// single overflow trigger for the info sheet. No back button —
/// system back gesture handles navigation — and no captain / sport /
/// member-count signage; those live in the info sheet now.
class _LobbyHeader extends StatelessWidget {
  static const _avatarSize = 56.0;

  final String lobbyId;
  final String lobbyName;
  final bool hasAvatar;
  final VoidCallback onInfoTap;

  const _LobbyHeader({
    required this.lobbyId,
    required this.lobbyName,
    required this.hasAvatar,
    required this.onInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return Container(
      color: colors.background,
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      child: Row(
        children: [
          // Avatar — enlarged so the lobby reads as the page's identity at
          // a glance. Falls back to a letter square when no photo is set.
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: LobbyAvatar(
              lobbyId: lobbyId,
              name: lobbyName,
              hasAvatar: hasAvatar,
              size: _avatarSize,
              borderRadius: BorderRadius.circular(14),
              backgroundColor: _crimsonTint,
              foregroundColor: _crimson,
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Text(
              lobbyName,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: colors.foreground,
                letterSpacing: -0.3,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),

          IconButton(
            onPressed: onInfoTap,
            icon: Icon(
              Icons.more_horiz_rounded,
              size: 22,
              color: colors.secondaryForeground,
            ),
            padding: const EdgeInsets.all(7),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ],
      ),
    );
  }
}
