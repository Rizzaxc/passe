// Match history tab — stats header + filter pills + match cards
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'match.dart';
import 'match_history_controller.dart';
import 'record_match_sheet.dart';

const _crimson = Color(0xFFDC143C);
const _green = Color(0xFF959D54);
const _greenTint = Color(0xFFEEF2E4);
const _orange = Color(0xFFF97316);
const _slate = Color(0xFF71717A);
const _slateTint = Color(0x1A71717A);

enum _HistoryFilter { all, challenge, practice, win, loss, draw }

// ─── History view ───────────────────────────────────────────────

class HistoryView extends ConsumerStatefulWidget {
  final String lobbyId;
  final String lobbyName;
  final bool canRecord;

  const HistoryView({
    super.key,
    required this.lobbyId,
    this.lobbyName = '',
    this.canRecord = false,
  });

  @override
  ConsumerState<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends ConsumerState<HistoryView> {
  _HistoryFilter _filter = _HistoryFilter.all;

  List<LobbyMatch> _applyFilter(List<LobbyMatch> matches) {
    return switch (_filter) {
      // A "challenge" is any competitive (non-practice) match — derived from
      // the result enum, not a display-string match.
      _HistoryFilter.challenge =>
        matches.where((h) => !h.isPractice).toList(),
      _HistoryFilter.practice => matches.where((h) => h.isPractice).toList(),
      _HistoryFilter.win => matches.where((h) => h.isWin).toList(),
      _HistoryFilter.loss => matches.where((h) => h.isLoss).toList(),
      _HistoryFilter.draw => matches.where((h) => h.isDraw).toList(),
      _HistoryFilter.all => matches,
    };
  }

  @override
  Widget build(BuildContext context) {
    final matchesAsync =
        ref.watch(lobbyMatchHistoryControllerProvider(widget.lobbyId));
    final matches = matchesAsync.value ?? const <LobbyMatch>[];
    final stats = LobbyMatchStats.from(matches);
    final filtered = _applyFilter(matches);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(lobbyMatchHistoryControllerProvider(widget.lobbyId));
        await ref.read(
          lobbyMatchHistoryControllerProvider(widget.lobbyId).future,
        );
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Stats card — 4-px horizontal inset (FTabs is already wrapped
          // by Padding(horizontal: 14) at the page level) so the card edge
          // lines up with the tab pill edge.
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
              child: _StatsCard(stats: stats),
            ),
          ),

          // Record-match CTA (captain-only).
          if (widget.canRecord)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                child: FButton(
                  variant: .outline,
                  onPress: () =>
                      showRecordMatchSheet(context, widget.lobbyId),
                  prefix: const Icon(FLucideIcons.plus, size: 16),
                  child: Text('manageTab.recordMatch.cta'.tr()),
                ),
              ),
            ),

          // Filter pills
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                itemCount: _HistoryFilter.values.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final f = _HistoryFilter.values[i];
                  return _FilterPill(
                    label: _filterLabel(f),
                    active: _filter == f,
                    onTap: () => setState(() => _filter = f),
                  );
                },
              ),
            ),
          ),

          // Match cards
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 20),
            sliver: SliverList.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) =>
                  _HistoryCard(match: filtered[i], lobbyName: widget.lobbyName),
            ),
          ),
        ],
      ),
    );
  }

  static String _filterLabel(_HistoryFilter f) => switch (f) {
        _HistoryFilter.all => 'Tất cả',
        _HistoryFilter.challenge => 'Thách đấu',
        _HistoryFilter.practice => 'Tập nội bộ',
        _HistoryFilter.win => 'Thắng',
        _HistoryFilter.loss => 'Thua',
        _HistoryFilter.draw => 'Hoà',
      };
}

// ─── Stats card ────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  final LobbyMatchStats stats;

  const _StatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final c = context.theme.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: c.border),
        borderRadius: context.theme.style.borderRadius.md,
        boxShadow: context.theme.style.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'THÀNH TÍCH',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: c.mutedForeground,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: Row(
              spacing: 14,
              children: [
                _HStat(
                  value: '${stats.total}',
                  label: 'trận',
                  color: c.foreground,
                ),
                _HStat(
                  value: '${stats.wins}',
                  label: 'thắng',
                  color: _green,
                ),
                _HStat(
                  value: '${stats.losses}',
                  label: 'thua',
                  color: _orange,
                ),
                if (stats.draws > 0)
                  _HStat(
                    value: '${stats.draws}',
                    label: 'hoà',
                    color: _slate,
                  ),
                _HStat(
                  value: '${stats.winRate}%',
                  label: 'win rate',
                  color: _crimson,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _HStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: -0.4,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: context.theme.colors.mutedForeground,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ─── Filter pill ───────────────────────────────────────────────

class _FilterPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? _crimson : context.theme.colors.secondary,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active
                ? const Color(0xFFFFF1F2)
                : context.theme.colors.secondaryForeground,
          ),
        ),
      ),
    );
  }
}

// ─── Match card ────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final LobbyMatch match;
  final String lobbyName;

  const _HistoryCard({required this.match, required this.lobbyName});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final isWin = match.isWin;
    final isLoss = match.isLoss;
    final isDraw = match.isDraw;
    final isPractice = match.isPractice;
    final isScoreless = match.isScorelessEncounter;

    final Color stripBg = isWin
        ? _greenTint
        : isLoss
            ? const Color(0x1AF97316)
            : isDraw
                ? _slateTint
                : colors.secondary;
    final Color stripFg = isWin
        ? _green
        : isLoss
            ? _orange
            : isDraw
                ? _slate
                : colors.mutedForeground;
    final String stripLabel = isWin
        ? 'Thắng'
        : isLoss
            ? 'Thua'
            : isDraw
                ? 'Hoà'
                // A scoreless encounter is still a challenge — the match was
                // played, just unrefereed — so it reads differently from an
                // internal scrimmage even though both share `result: practice`.
                : isScoreless
                    ? 'Không tính điểm'
                    : 'Tập nội bộ';

    // Set tallies
    int? usWins, themWins;
    if (match.sets != null) {
      usWins = match.sets!.where((s) => s.$1 > s.$2).length;
      themWins = match.sets!.where((s) => s.$2 > s.$1).length;
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.border),
        borderRadius: context.theme.style.borderRadius.md,
        boxShadow: context.theme.style.shadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Result strip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: stripBg,
            child: Row(
              children: [
                Icon(
                  isPractice && !isScoreless
                      ? Icons.groups_outlined
                      : Icons.emoji_events_outlined,
                  size: 12,
                  color: stripFg,
                ),
                const SizedBox(width: 6),
                Text(
                  stripLabel.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: stripFg,
                    letterSpacing: 0.7,
                  ),
                ),
                Flexible(
                  child: Text(
                    ' · ${match.opponentTag}',
                    style: TextStyle(
                      fontSize: 10,
                      color: stripFg.withValues(alpha: 0.7),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '${match.date} · ${match.when}',
                    style: TextStyle(
                      fontSize: 10,
                      color: colors.mutedForeground,
                    ),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Matchup
                if (isScoreless)
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: colors.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.sports_outlined,
                            size: 18, color: colors.mutedForeground),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'vs ${match.opponent ?? match.opponentTag}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: colors.foreground,
                              ),
                            ),
                            Text(
                              'Không có trọng tài — trận không tính điểm',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: colors.mutedForeground,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else if (!isPractice && usWins != null)
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lobbyName.isNotEmpty ? lobbyName : 'lobby.us'.tr(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: colors.foreground,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$usWins',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: isWin
                                    ? _green
                                    : colors.secondaryForeground,
                                letterSpacing: -0.5,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'vs',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color:
                              colors.mutedForeground.withValues(alpha: 0.5),
                          letterSpacing: 0.7,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              match.opponent ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: colors.secondaryForeground,
                              ),
                              textAlign: TextAlign.right,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$themWins',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: isLoss
                                    ? _orange
                                    : colors.secondaryForeground,
                                letterSpacing: -0.5,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else if (isPractice)
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: colors.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.groups_outlined,
                            size: 18, color: colors.mutedForeground),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tập nội bộ',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: colors.foreground,
                              ),
                            ),
                            if (match.note != null)
                              Text(
                                match.note!,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: colors.mutedForeground,
                                  height: 1.4,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                // Set breakdown
                if (match.sets != null && !isPractice) ...[
                  const SizedBox(height: 10),
                  Row(
                    spacing: 6,
                    children: [
                      for (var i = 0; i < match.sets!.length; i++)
                        Expanded(
                          child: _SetChip(
                            setNum: i + 1,
                            us: match.sets![i].$1,
                            them: match.sets![i].$2,
                          ),
                        ),
                    ],
                  ),
                ],

                // Venue (+ referee, when this match had one) + members
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(FLucideIcons.mapPin,
                        size: 11, color: colors.mutedForeground),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        match.refereeName != null
                            ? '${match.venue} · TT ${match.refereeName}'
                            : match.venue,
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.mutedForeground,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _MemberAvatars(members: match.members),
                  ],
                ),

                // MVP
                if (match.mvp != null) ...[
                  const SizedBox(height: 9),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: colors.border.withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 12, color: Color(0xFFC58A1A)),
                        const SizedBox(width: 7),
                        Text(
                          'MVP',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: colors.mutedForeground,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _memberColor(match.mvp!),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            match.mvp![0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          match.mvp!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.foreground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SetChip extends StatelessWidget {
  final int setNum;
  final int us;
  final int them;

  const _SetChip({
    required this.setNum,
    required this.us,
    required this.them,
  });

  @override
  Widget build(BuildContext context) {
    final Color tone = us > them
        ? _green
        : us < them
            ? _orange
            : _slate;
    final Color tint = us > them
        ? _greenTint
        : us < them
            ? const Color(0x1AF97316)
            : _slateTint;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            'Set $setNum',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: tone.withValues(alpha: 0.7),
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '$us–$them',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: tone,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberAvatars extends StatelessWidget {
  final List<String> members;
  const _MemberAvatars({required this.members});

  @override
  Widget build(BuildContext context) {
    final shown = members.take(4).toList();
    final overflow = members.length - shown.length;

    return Row(
      children: [
        for (var i = 0; i < shown.length; i++)
          Transform.translate(
            offset: Offset(i * -6, 0),
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _memberColor(shown[i]),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                shown[i][0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        if (overflow > 0)
          Transform.translate(
            offset: Offset(shown.length * -6, 0),
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF4F4F5),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                '+$overflow',
                style: const TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF71717A),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

Color _memberColor(String name) {
  const palette = [
    Color(0xFF6366F1),
    Color(0xFF0EA5E9),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
    Color(0xFF8B5CF6),
  ];
  return palette[name.hashCode.abs() % palette.length];
}
