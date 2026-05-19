// Match history tab — stats header + filter pills + match cards
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';


const _crimson = Color(0xFFDC143C);
const _green = Color(0xFF959D54);
const _greenTint = Color(0xFFEEF2E4);
const _orange = Color(0xFFF97316);

// ─── Mock history data ──────────────────────────────────────────

class _Match {
  final String id;
  final String date;
  final String when;
  final String? opponent;
  final String opponentTag;
  final String result; // 'win' | 'loss' | 'practice'
  final List<(int, int)>? sets; // (us, them)
  final String? mvp;
  final String venue;
  final List<String> members;
  final String? note;

  const _Match({
    required this.id,
    required this.date,
    required this.when,
    this.opponent,
    required this.opponentTag,
    required this.result,
    this.sets,
    this.mvp,
    required this.venue,
    required this.members,
    this.note,
  });
}

const _mockHistory = [
  _Match(
    id: 'm-1',
    date: 'T7, 14/5',
    when: '18:00 – 20:00',
    opponent: 'Lobby Fire',
    opponentTag: 'thách đấu',
    result: 'win',
    sets: [(21, 15), (19, 21), (21, 17)],
    mvp: 'Minh',
    venue: 'NTĐ Bách Khoa · Sân 3',
    members: ['Trang', 'An', 'Long', 'Minh'],
  ),
  _Match(
    id: 'm-2',
    date: 'T7, 7/5',
    when: '18:00 – 20:00',
    opponent: 'Lobby Aces',
    opponentTag: 'thách đấu',
    result: 'loss',
    sets: [(18, 21), (21, 19), (14, 21)],
    mvp: 'An',
    venue: 'NTĐ Bách Khoa · Sân 2',
    members: ['Trang', 'An', 'Long', 'Phúc'],
  ),
  _Match(
    id: 'm-3',
    date: 'T4, 4/5',
    when: '19:00 – 21:00',
    opponent: null,
    opponentTag: 'tập nội bộ',
    result: 'practice',
    venue: 'NTĐ Bách Khoa · Sân 3',
    members: ['Trang', 'An', 'Minh', 'Long', 'Phúc'],
    note: '2 set giao hữu nội bộ',
  ),
  _Match(
    id: 'm-4',
    date: 'T7, 30/4',
    when: '17:00 – 19:00',
    opponent: 'Lobby Smash District 1',
    opponentTag: 'thách đấu',
    result: 'win',
    sets: [(21, 18), (21, 14)],
    mvp: 'Trang',
    venue: 'Sân Phú Thọ · Sân 5',
    members: ['Trang', 'An', 'Long', 'Minh'],
  ),
  _Match(
    id: 'm-5',
    date: 'T7, 23/4',
    when: '18:30 – 20:30',
    opponent: 'Lobby Drop Shot',
    opponentTag: 'thách đấu',
    result: 'loss',
    sets: [(19, 21), (21, 23)],
    mvp: 'Long',
    venue: 'NTĐ Bách Khoa · Sân 3',
    members: ['Trang', 'An', 'Long', 'Minh', 'Lan'],
  ),
];

// Computed stats
final _wins = _mockHistory.where((h) => h.result == 'win').length;
final _losses = _mockHistory.where((h) => h.result == 'loss').length;
final _total = _wins + _losses;
final _winRate = _total > 0 ? (_wins * 100 ~/ _total) : 0;

// ─── History view ───────────────────────────────────────────────

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  int _filterIndex = 0;

  List<_Match> get _filtered {
    return switch (_filterIndex) {
      1 => _mockHistory
          .where((h) => h.opponentTag == 'thách đấu')
          .toList(),
      2 => _mockHistory.where((h) => h.result == 'practice').toList(),
      3 => _mockHistory.where((h) => h.result == 'win').toList(),
      4 => _mockHistory.where((h) => h.result == 'loss').toList(),
      _ => _mockHistory,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final filtered = _filtered;

    return RefreshIndicator(
      onRefresh: () async {},
      child: CustomScrollView(
        slivers: [
          // Stats card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
              child: _StatsCard(colors: colors),
            ),
          ),

          // Filter pills
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                itemCount: 5,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (_, i) => _FilterPill(
                  label: const [
                    'Tất cả',
                    'Thách đấu',
                    'Tập nội bộ',
                    'Thắng',
                    'Thua',
                  ][i],
                  active: _filterIndex == i,
                  onTap: () => setState(() => _filterIndex = i),
                ),
              ),
            ),
          ),

          // Match cards
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
            sliver: SliverList.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) =>
                  _HistoryCard(match: filtered[i]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stats card ────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  final dynamic colors;
  const _StatsCard({required this.colors});

  @override
  Widget build(BuildContext context) {
    final c = context.theme.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
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
                        value: '${_mockHistory.length}',
                        label: 'trận',
                        color: c.foreground,
                      ),
                      _HStat(
                        value: '$_wins',
                        label: 'thắng',
                        color: _green,
                      ),
                      _HStat(
                        value: '$_losses',
                        label: 'thua',
                        color: _orange,
                      ),
                      _HStat(
                        value: '$_winRate%',
                        label: 'win rate',
                        color: _crimson,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: c.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border.withValues(alpha: 0.6)),
            ),
            child: const Center(
              child: Icon(Icons.sports_tennis, size: 28,
                  color: Color(0xFF71717A)),
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
  final _Match match;
  const _HistoryCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final isWin = match.result == 'win';
    final isLoss = match.result == 'loss';
    final isPractice = match.result == 'practice';

    final Color stripBg = isWin
        ? _greenTint
        : isLoss
            ? const Color(0x1AF97316)
            : colors.secondary;
    final Color stripFg = isWin
        ? _green
        : isLoss
            ? _orange
            : colors.mutedForeground;
    final String stripLabel =
        isWin ? 'Thắng' : isLoss ? 'Thua' : 'Tập nội bộ';

    // Set tallies
    int? usWins, themWins;
    if (match.sets != null) {
      usWins = match.sets!.where((s) => s.$1 > s.$2).length;
      themWins = match.sets!.where((s) => s.$2 > s.$1).length;
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                  isPractice ? Icons.groups_outlined : Icons.emoji_events_outlined,
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
                if (!isPractice && usWins != null)
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bách Khoa Smash',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: colors.foreground,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$usWins',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: isWin ? _green : colors.secondaryForeground,
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
                          color: colors.mutedForeground.withValues(alpha: 0.5),
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
                                color: isLoss ? _orange : colors.secondaryForeground,
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

                // Venue + members
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(FIcons.mapPin,
                        size: 11, color: colors.mutedForeground),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        match.venue,
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.mutedForeground,
                        ),
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
    final weWon = us > them;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: weWon ? _greenTint : const Color(0x1AF97316),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            'Set $setNum',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: weWon
                  ? _green.withValues(alpha: 0.7)
                  : _orange.withValues(alpha: 0.7),
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '$us–$them',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: weWon ? _green : _orange,
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
