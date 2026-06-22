// Feed item models + renderers — action-based, no free-text chat
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../../../ui/theme.dart';

// ─── Color tokens ──────────────────────────────────────────────
const _crimson = Color(0xFFDC143C);
const _crimsonTint = Color(0xFFFFEBED);
const _greenTint = Color(0xFFEEF2E4);
const _amberTint = Color(0xFFFDF3DC);
const _blueTint = Color(0xFFEBF5FF);
const _orange = Color(0xFFF97316);
const _amber = Color(0xFFC58A1A);

// ─── Feed item sealed hierarchy ─────────────────────────────────
//
// Items carry SEMANTIC kinds (PersonalActionKind, UpdateKind, FeedTone),
// not presentation values. The renderers below resolve a kind to the
// design's color / icon vocabulary. This keeps the DB row schema stable
// across design changes — see schema/lobby_feed_and_match.sql.

/// Captain-update categories (left half of the update card).
///
/// `db` is the string stored in `lobby_feed_item.payload.kind`.
enum UpdateKind {
  scheduled('scheduled', Icons.calendar_month_outlined),
  coachBooked('coach_booked', Icons.school_outlined),
  refereeBooked('referee_booked', Icons.sports_score_outlined),
  rescheduled('rescheduled', Icons.update_outlined),
  venueChanged('venue_changed', Icons.swap_horiz_outlined),
  other('other', Icons.campaign_outlined);

  final String db;
  final IconData icon;

  const UpdateKind(this.db, this.icon);

  static UpdateKind fromDb(String? raw) => UpdateKind.values.firstWhere(
        (k) => k.db == raw,
        orElse: () => UpdateKind.other,
      );
}

/// Personal-action categories. Mirrors the picker catalog in
/// `trigger_bar.dart` — every id the user can pick has an entry here.
enum PersonalActionKind {
  comeEarly(
      'come_early', 'Đến sớm khởi động', FeedTone.amber,
      Icons.local_fire_department_outlined),
  late('late', 'Đến muộn', FeedTone.crimson, Icons.access_time_rounded),
  bringGear(
      'bring_gear', 'Mang thêm gear', FeedTone.green,
      Icons.sports_tennis_outlined),
  needLift(
      'need_lift', 'Cần đi nhờ', FeedTone.blue,
      Icons.directions_car_outlined),
  offerLift(
      'offer_lift', 'Cho đi nhờ', FeedTone.blue,
      Icons.directions_car_outlined),
  paid(
      'paid', 'Đã chuyển tiền sân', FeedTone.green,
      Icons.account_balance_wallet_outlined),
  skip('skip', 'Vắng buổi này', FeedTone.crimson, Icons.close_rounded),
  cheer(
      'cheer', 'Tăng động năng lượng', FeedTone.neutral,
      Icons.emoji_emotions_outlined);

  final String db;
  final String label;
  final FeedTone tone;
  final IconData icon;

  const PersonalActionKind(this.db, this.label, this.tone, this.icon);

  static PersonalActionKind fromDb(String? raw) =>
      PersonalActionKind.values.firstWhere(
        (k) => k.db == raw,
        orElse: () => PersonalActionKind.cheer,
      );
}

/// Soft palette tones used by update cards, personal cards and chip
/// tags. Each tone resolves to a foreground + background colour pair.
enum FeedTone {
  crimson(_crimson, _crimsonTint),
  green(pbGreen, _greenTint),
  amber(_amber, _amberTint),
  blue(pbBlue, _blueTint),
  neutral(Color(0xFF52525B), Color(0xFFF4F4F5));

  final Color fg;
  final Color bg;

  const FeedTone(this.fg, this.bg);

  static FeedTone fromDb(String? raw) => FeedTone.values.firstWhere(
        (t) => t.name == raw,
        orElse: () => FeedTone.neutral,
      );
}

/// Single reaction tally on a personal card (e.g. `(emoji: '👍', count: 3)`).
class FeedReaction {
  final String emoji;
  final int count;

  const FeedReaction({required this.emoji, required this.count});

  factory FeedReaction.fromJson(Map<String, dynamic> j) => FeedReaction(
        emoji: j['emoji'] as String,
        count: (j['count'] as num).toInt(),
      );

  String get display => '$emoji $count';
}

sealed class FeedItem {
  const FeedItem();

  /// Parse a row returned by the `lobby_feed_data` RPC into a concrete
  /// `FeedItem`. `pollTallies` is an inline `{option_index: count}` map
  /// emitted by the RPC for poll rows; the function pulls option labels
  /// from the row's own payload to assemble the `(label, votes)` tuples
  /// the renderer expects.
  static FeedItem fromRow(Map<String, dynamic> row) {
    final kind = row['kind'] as String;
    final payload = row['payload'] as Map<String, dynamic>;
    final author = (row['author_username'] as String?) ?? '';
    final time = _formatHm(DateTime.parse(row['created_at'] as String));

    switch (kind) {
      case 'update':
        return UpdateItem(
          author: author,
          time: time,
          title: payload['title'] as String,
          kind: UpdateKind.fromDb(payload['kind'] as String?),
          tone: FeedTone.fromDb(payload['tone'] as String?),
          fields: (payload['fields'] as List)
              .map<(String, String)>(
                  (f) => ((f as List)[0] as String, f[1] as String))
              .toList(),
          ctaLabel: payload['cta_label'] as String?,
        );

      case 'personal':
        final rawReactions = payload['reactions'] as List?;
        return PersonalItem(
          author: author,
          time: time,
          action: PersonalActionKind.fromDb(payload['action_kind'] as String?),
          detail: payload['detail'] as String?,
          reactions: rawReactions
              ?.map((r) => FeedReaction.fromJson(r as Map<String, dynamic>))
              .toList(),
        );

      case 'system':
        return SystemItem(
          text: payload['text'] as String,
          hasApprove: (payload['has_approve'] as bool?) ?? false,
        );

      case 'poll':
        final tallies = (row['poll_tallies'] as Map?) ?? const {};
        final options = (payload['options'] as List).indexed
            .map<(String, int)>((entry) {
          final (i, raw) = entry;
          final label = (raw as Map<String, dynamic>)['label'] as String;
          final count = (tallies['$i'] as num?)?.toInt() ?? 0;
          return (label, count);
        }).toList();
        return PollItem(
          id: row['id'] as String,
          author: author,
          time: time,
          question: payload['question'] as String,
          options: options,
          totalMembers: (payload['total_members'] as num).toInt(),
          deadline: (payload['deadline'] as String?) ?? '',
        );

      case 'photo':
        return PhotoItem(
          author: author,
          time: time,
          storagePath: payload['storage_path'] as String,
          caption: payload['caption'] as String?,
        );

      default:
        throw StateError('Unknown lobby feed kind: $kind');
    }
  }
}

String _formatHm(DateTime t) {
  final local = t.toLocal();
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

/// Synthetic divider injected client-side between days. Never persisted.
final class DayDivItem extends FeedItem {
  final String label;
  const DayDivItem(this.label);
}

final class UpdateItem extends FeedItem {
  final String author;
  final String time;
  final String title;
  final UpdateKind kind;
  final FeedTone tone;
  final List<(String, String)> fields;
  final String? ctaLabel;
  const UpdateItem({
    required this.author,
    required this.time,
    required this.title,
    required this.kind,
    required this.tone,
    required this.fields,
    this.ctaLabel,
  });
}

final class PersonalItem extends FeedItem {
  final String author;
  final String time;
  final PersonalActionKind action;
  final String? detail;
  final List<FeedReaction>? reactions;
  const PersonalItem({
    required this.author,
    required this.time,
    required this.action,
    this.detail,
    this.reactions,
  });
}

final class SystemItem extends FeedItem {
  final String text;
  final bool hasApprove;
  const SystemItem({required this.text, this.hasApprove = false});
}

final class PollItem extends FeedItem {
  final String id;
  final String author;
  final String time;
  final String question;
  final List<(String, int)> options; // (label, voteCount)
  final int totalMembers;
  final String deadline;
  const PollItem({
    required this.id,
    required this.author,
    required this.time,
    required this.question,
    required this.options,
    required this.totalMembers,
    required this.deadline,
  });
}

final class PhotoItem extends FeedItem {
  final String author;
  final String time;
  final String storagePath;
  final String? caption;
  const PhotoItem({
    required this.author,
    required this.time,
    required this.storagePath,
    this.caption,
  });
}

// ─── Feed item widget router ────────────────────────────────────

class FeedItemWidget extends StatelessWidget {
  final FeedItem item;
  const FeedItemWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return switch (item) {
      final DayDivItem d => _DayDivider(item: d),
      final UpdateItem u => _UpdateCard(item: u),
      final PersonalItem p => _PersonalCard(item: p),
      final SystemItem s => _SystemEvent(item: s),
      final PollItem po => _PollCard(item: po),
      final PhotoItem ph => _PhotoCard(item: ph),
    };
  }
}

// ─── Day divider ───────────────────────────────────────────────

class _DayDivider extends StatelessWidget {
  final DayDivItem item;
  const _DayDivider({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
      child: Row(
        children: [
          Expanded(child: Divider(color: colors.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              item.label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: colors.mutedForeground,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Expanded(child: Divider(color: colors.border)),
        ],
      ),
    );
  }
}

// ─── Author row (shared) ───────────────────────────────────────

class _AuthorRow extends StatelessWidget {
  final String name;
  final String time;

  const _AuthorRow({required this.name, required this.time});

  static const _captainName = 'Trang';

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final isLeader = name == _captainName;

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _memberColor(name),
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          name,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isLeader ? _crimson : colors.secondaryForeground,
          ),
        ),
        if (isLeader) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: _crimsonTint,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'ĐỘI TRƯỞNG',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: _crimson,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
        const Spacer(),
        Text(
          time,
          style: TextStyle(
            fontSize: 10.5,
            fontStyle: FontStyle.italic,
            color: colors.mutedForeground.withValues(alpha: 0.7),
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

// ─── Personal action card ──────────────────────────────────────

class _PersonalCard extends StatelessWidget {
  final PersonalItem item;
  const _PersonalCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final fg = item.action.tone.fg;
    final bg = item.action.tone.bg;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AuthorRow(name: item.author, time: item.time),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 35),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: fg.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: fg.withValues(alpha: 0.3)),
                    ),
                    child: Icon(item.action.icon, size: 14, color: fg),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.action.label,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: fg,
                          ),
                        ),
                        if (item.detail != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.detail!,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: colors.secondaryForeground,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (item.reactions != null && item.reactions!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 35),
              child: Row(
                children: [
                  for (final r in item.reactions!)
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.background,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: colors.border.withValues(alpha: 0.8)),
                      ),
                      child: Text(
                        r.display,
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Captain update card ───────────────────────────────────────

class _UpdateCard extends StatelessWidget {
  final UpdateItem item;
  const _UpdateCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final fgColor = item.tone.fg;
    final bgColor = item.tone.bg;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AuthorRow(name: item.author, time: item.time),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 35),
            child: Container(
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    color: bgColor,
                    child: Row(
                      children: [
                        Icon(item.kind.icon, size: 13, color: fgColor),
                        const SizedBox(width: 6),
                        Text(
                          item.title.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: fgColor,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final (label, value) in item.fields)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                SizedBox(
                                  width: 64,
                                  child: Text(
                                    label.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                      color: colors.mutedForeground,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    value,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF09090B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (item.ctaLabel != null) ...[
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: pbGreen,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                item.ctaLabel!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}

// ─── System event (join request etc.) ─────────────────────────

class _SystemEvent extends StatelessWidget {
  final SystemItem item;
  const _SystemEvent({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Container(
      margin: const EdgeInsets.fromLTRB(4, 6, 4, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: _crimsonTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(FLucideIcons.userPlus, size: 15, color: _crimson),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.text,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: colors.secondaryForeground,
              ),
            ),
          ),
          if (item.hasApprove) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () {},
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _greenTint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Đồng Ý',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: pbGreen,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () {},
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0x25F97316),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Từ Chối',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _orange,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Poll card ─────────────────────────────────────────────────

class _PollCard extends StatefulWidget {
  final PollItem item;
  const _PollCard({required this.item});

  @override
  State<_PollCard> createState() => _PollCardState();
}

class _PollCardState extends State<_PollCard> {
  int? _voted;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final total = widget.item.options.fold<int>(0, (s, o) => s + o.$2) +
        (_voted != null ? 1 : 0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AuthorRow(name: widget.item.author, time: widget.item.time),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 35),
            child: Container(
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                  )
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    color: _blueTint,
                    child: Row(
                      children: [
                        const Icon(Icons.bar_chart_rounded,
                            size: 13, color: pbBlue),
                        const SizedBox(width: 6),
                        const Text(
                          'BÌNH CHỌN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: pbBlue,
                            letterSpacing: 0.7,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          widget.item.deadline,
                          style: TextStyle(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            color: colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.question,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF09090B),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 9),
                        for (var i = 0; i < widget.item.options.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _PollOption(
                              label: widget.item.options[i].$1,
                              votes: widget.item.options[i].$2 +
                                  (_voted == i ? 1 : 0),
                              total: total,
                              selected: _voted == i,
                              onTap: () => setState(() => _voted = i),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          '$total/${widget.item.totalMembers} đã bình chọn',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PollOption extends StatelessWidget {
  final String label;
  final int votes;
  final int total;
  final bool selected;
  final VoidCallback onTap;

  const _PollOption({
    required this.label,
    required this.votes,
    required this.total,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? votes / total : 0.0;
    final colors = context.theme.colors;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 40,
        child: Stack(
          children: [
            // Background
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: selected ? _blueTint : colors.background,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: selected
                        ? pbBlue
                        : colors.border.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
            // Progress fill
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: pct,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Container(
                    color: selected ? _blueTint : colors.secondary,
                  ),
                ),
              ),
            ),
            // Label + count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected ? pbBlue : const Color(0xFF09090B),
                      ),
                    ),
                  ),
                  Text(
                    '$votes · ${(pct * 100).round()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Photo card ────────────────────────────────────────────────

class _PhotoCard extends StatelessWidget {
  final PhotoItem item;
  const _PhotoCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AuthorRow(name: item.author, time: item.time),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 35),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 240,
                    height: 160,
                    child: CustomPaint(painter: _CourtPhotoPainter()),
                  ),
                ),
                if (item.caption != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    item.caption!,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: colors.secondaryForeground,
                      height: 1.4,
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

class _CourtPhotoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Dark court background
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xFF3D4760), Color(0xFF1C2334)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Wood floor
    canvas.drawRect(
      Rect.fromLTRB(0, size.height * 0.69, size.width, size.height),
      Paint()..color = const Color(0xFFA6804A),
    );

    // Court lines
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final court = Rect.fromLTWH(
      size.width * 0.17,
      size.height * 0.74,
      size.width * 0.66,
      size.height * 0.24,
    );
    canvas.drawRect(court, linePaint);
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.74),
      Offset(size.width * 0.5, size.height * 0.98),
      linePaint,
    );
    // Net line
    canvas.drawLine(
      Offset(size.width * 0.17, size.height * 0.86),
      Offset(size.width * 0.83, size.height * 0.86),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..strokeWidth = 2.0,
    );
  }

  @override
  bool shouldRepaint(_CourtPhotoPainter old) => false;
}
