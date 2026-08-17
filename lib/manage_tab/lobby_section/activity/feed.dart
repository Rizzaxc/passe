// Feed item models + renderers — action-based; activity notes are the one
// intentionally short free-text action.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../../../ui/theme.dart';
import '../../../../ui/user_avatar.dart';
import '../../../auth/auth_controller.dart';
import '../../../core/format.dart';
import '../../../core/model/wall_post.dart';
import '../../../core/payment/pay_recipient.dart';
import '../../../feed_tab/post_card.dart';
import '../../../router.dart';
import 'feed_controller.dart';

// ─── Color tokens ──────────────────────────────────────────────
const _crimson = Color(0xFFDC143C);
const _crimsonTint = Color(0xFFFFEBED);
const _greenTint = Color(0xFFEEF2E4);
const _amberTint = Color(0xFFFDF3DC);
const _blueTint = Color(0xFFEBF5FF);
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
  // Posted by confirm_challenge_activity once BOTH lobbies have confirmed a
  // challenge match — the next entry after the accept-time 'scheduled' one,
  // not a rename of it (that fires earlier, on accept).
  matchConfirmed('match_confirmed', Icons.check_circle_outline),
  rescheduled('rescheduled', Icons.update_outlined),
  venueChanged('venue_changed', Icons.swap_horiz_outlined),
  cancelled('cancelled', Icons.event_busy_outlined),
  // Organizer override-confirmed a deadline-passed activity despite being
  // under confirmation_threshold (resolve_at_risk_activity_organizer).
  thresholdConfirmed('threshold_confirmed', Icons.verified_outlined),
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
    'come_early',
    'lobbyHub.feed.personal.comeEarly',
    FeedTone.amber,
    Icons.local_fire_department_outlined,
  ),
  late(
    'late',
    'lobbyHub.feed.personal.late',
    FeedTone.crimson,
    Icons.access_time_rounded,
  ),
  note(
    'note',
    'lobbyHub.feed.personal.note',
    FeedTone.blue,
    Icons.sticky_note_2_outlined,
  ),
  bringGear(
    'bring_gear',
    'lobbyHub.feed.personal.bringGear',
    FeedTone.green,
    Icons.sports_tennis_outlined,
  ),
  needLift(
    'need_lift',
    'lobbyHub.feed.personal.needLift',
    FeedTone.blue,
    Icons.directions_car_outlined,
  ),
  offerLift(
    'offer_lift',
    'lobbyHub.feed.personal.offerLift',
    FeedTone.blue,
    Icons.directions_car_outlined,
  ),
  paid(
    'paid',
    'lobbyHub.feed.personal.paid',
    FeedTone.green,
    Icons.account_balance_wallet_outlined,
  ),
  skip(
    'skip',
    'lobbyHub.feed.personal.skip',
    FeedTone.crimson,
    Icons.close_rounded,
  ),
  cheer(
    'cheer',
    'lobbyHub.feed.personal.cheer',
    FeedTone.neutral,
    Icons.emoji_emotions_outlined,
  ),
  remindCaptain(
    'remind_captain',
    'lobbyHub.feed.personal.remindCaptain',
    FeedTone.neutral,
    Icons.notifications_active_outlined,
  );

  final String db;
  final String label;
  final FeedTone tone;
  final IconData icon;

  const PersonalActionKind(this.db, this.label, this.tone, this.icon);

  static PersonalActionKind fromDb(String? raw) => PersonalActionKind.values
      .firstWhere((k) => k.db == raw, orElse: () => PersonalActionKind.cheer);
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
    final authorId = row['author_id'] as String?;
    final authorGeneratedAvatar = row['author_generated_avatar'] as String?;
    final time = _formatHm(DateTime.parse(row['created_at'] as String));

    switch (kind) {
      case 'update':
        return UpdateItem(
          author: author,
          authorId: authorId,
          authorGeneratedAvatar: authorGeneratedAvatar,
          time: time,
          title: payload['title'] as String,
          kind: UpdateKind.fromDb(payload['kind'] as String?),
          tone: FeedTone.fromDb(payload['tone'] as String?),
          fields: (payload['fields'] as List)
              .map<(String, String)>(
                (f) => ((f as List)[0] as String, f[1] as String),
              )
              .toList(),
        );

      case 'personal':
        final rawReactions = payload['reactions'] as List?;
        return PersonalItem(
          author: author,
          authorId: authorId,
          authorGeneratedAvatar: authorGeneratedAvatar,
          time: time,
          action: PersonalActionKind.fromDb(payload['action_kind'] as String?),
          detail: payload['detail'] as String?,
          reactions: rawReactions
              ?.map((r) => FeedReaction.fromJson(r as Map<String, dynamic>))
              .toList(),
          activityId: row['activity_id'] as String?,
        );

      case 'system':
        return SystemItem(text: payload['text'] as String);

      case 'poll':
        final tallies = (row['poll_tallies'] as Map?) ?? const {};
        final options = (payload['options'] as List).indexed.map<(String, int)>(
          (entry) {
            final (i, raw) = entry;
            final label = (raw as Map<String, dynamic>)['label'] as String;
            final count = (tallies['$i'] as num?)?.toInt() ?? 0;
            return (label, count);
          },
        ).toList();
        return PollItem(
          id: row['id'] as String,
          author: author,
          authorId: authorId,
          authorGeneratedAvatar: authorGeneratedAvatar,
          time: time,
          question: payload['question'] as String,
          options: options,
          totalMembers: (payload['total_members'] as num).toInt(),
          deadline: (payload['deadline'] as String?) ?? '',
          myVote: (row['my_vote'] as num?)?.toInt(),
        );

      case 'payment_request':
        final payeesRaw = row['payment_payees'] as List?;
        return PaymentRequestItem(
          id: row['id'] as String,
          author: author,
          authorId: authorId,
          authorGeneratedAvatar: authorGeneratedAvatar,
          time: time,
          type: payload['type'] as String,
          sourceActivityId: payload['source_activity_id'] as String?,
          recipientId: payload['recipient_id'] as String,
          costType: payload['cost_type'] as String?,
          totalAmount: payload['total_amount'] as num,
          perPersonAmount: payload['per_person_amount'] as num,
          note: payload['note'] as String?,
          payees:
              payeesRaw
                  ?.map((p) => PaymentPayee.fromJson(p as Map<String, dynamic>))
                  .toList() ??
              const [],
          activityId: row['activity_id'] as String?,
        );

      // `photo` is no longer a natively-written kind — lobby_feed_data
      // synthesises these rows from `wall_post` (see
      // schema/lobby_feed_wall_posts.sql), so the payload is a full wall post,
      // not the old {storage_path, caption} shape.
      case 'photo':
        return WallPostItem(post: WallPost.fromJson(payload));

      default:
        throw StateError('Unknown lobby feed kind: $kind');
    }
  }
}

/// The activity a feed item is scoped to, if any. Only `PersonalItem`
/// (`late` reports and member notes) and `PaymentRequestItem` (always) ever
/// carry one — every
/// other kind (`update`, `poll`, `system`, wall posts) is lobby-wide and
/// returns null. Used to split the general Feed tab from each `ActivityCard`
/// 's own per-activity log — see `lib/manage_tab/CLAUDE.md`.
extension FeedItemActivityScope on FeedItem {
  String? get activityId => switch (this) {
    final PersonalItem p => p.activityId,
    final PaymentRequestItem pr => pr.activityId,
    _ => null,
  };
}

bool _isActivityScoped(FeedItem item) =>
    (item is PersonalItem || item is PaymentRequestItem) &&
    item.activityId != null;

/// The general Feed tab's view of a lobby's feed: everything except the
/// activity-scoped `personal` and `payment_request` items that now live in
/// their own `ActivityCard`'s expandable log (see `perActivityFeedItems`
/// below). Also
/// drops any `DayDivItem` left with nothing following it once those are
/// removed, so a day with only activity-scoped posts doesn't leave a bare
/// divider.
List<FeedItem> generalFeedItems(List<FeedItem> items) {
  final filtered = [
    for (final i in items)
      if (!_isActivityScoped(i)) i,
  ];
  final out = <FeedItem>[];
  for (var i = 0; i < filtered.length; i++) {
    final item = filtered[i];
    if (item is DayDivItem) {
      final hasContentAfter =
          i + 1 < filtered.length && filtered[i + 1] is! DayDivItem;
      if (!hasContentAfter) continue;
    }
    out.add(item);
  }
  return out;
}

/// One `ActivityCard`'s own action log — `personal` actions and
/// `payment_request` items scoped to [activityId], oldest-first, with no day
/// dividers (a single session's log is short enough not to need them).
List<FeedItem> perActivityFeedItems(List<FeedItem> items, String activityId) =>
    [
      for (final i in items)
        if (i.activityId == activityId) i,
    ];

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
  final String? authorId;
  final String? authorGeneratedAvatar;
  final String time;
  final String title;
  final UpdateKind kind;
  final FeedTone tone;
  final List<(String, String)> fields;
  const UpdateItem({
    required this.author,
    required this.authorId,
    this.authorGeneratedAvatar,
    required this.time,
    required this.title,
    required this.kind,
    required this.tone,
    required this.fields,
  });
}

final class PersonalItem extends FeedItem {
  final String author;
  final String? authorId;
  final String? authorGeneratedAvatar;
  final String time;
  final PersonalActionKind action;
  final String? detail;
  final List<FeedReaction>? reactions;

  /// The activity this action refers to — set for `late` and `note`, which
  /// are posted from a specific `ActivityCard`. `remind_captain` and any
  /// other personal action posted with no activity context stay null, which
  /// keeps them on the general Feed tab — see `FeedItem.activityId` / the
  /// Planner tab's per-card log.
  final String? activityId;

  const PersonalItem({
    required this.author,
    required this.authorId,
    this.authorGeneratedAvatar,
    required this.time,
    required this.action,
    this.detail,
    this.reactions,
    this.activityId,
  });
}

final class SystemItem extends FeedItem {
  final String text;
  const SystemItem({required this.text});
}

final class PollItem extends FeedItem {
  final String id;
  final String author;
  final String? authorId;
  final String? authorGeneratedAvatar;
  final String time;
  final String question;
  final List<(String, int)> options; // (label, voteCount)
  final int totalMembers;
  final String deadline;
  final int? myVote; // option index the caller voted for, null if none yet
  const PollItem({
    required this.id,
    required this.author,
    required this.authorId,
    this.authorGeneratedAvatar,
    required this.time,
    required this.question,
    required this.options,
    required this.totalMembers,
    required this.deadline,
    required this.myVote,
  });
}

/// A wall post attached to one of this lobby's activities, surfaced inline in
/// the lobby feed. There is no separate lobby-photo entity — this is the same
/// row the Home feed and the author's wall render.
final class WallPostItem extends FeedItem {
  final WallPost post;
  const WallPostItem({required this.post});
}

enum PaymentPayeeStatus {
  outstanding,
  paidDirect,
  clearedTogether;

  static PaymentPayeeStatus fromDb(String? value) => switch (value) {
    'paid_direct' => paidDirect,
    'cleared_together' => clearedTogether,
    _ => outstanding,
  };

  bool get isResolved => this != outstanding;
}

/// One tagged member on a [PaymentRequestItem]. New request rows are
/// outstanding automatically; they can be cleared here or together from the
/// lobby-wide money sheet.
class PaymentPayee {
  final String userId;
  final String username;
  final String? generatedAvatar;
  final num amountOwed;
  final PaymentPayeeStatus status;

  const PaymentPayee({
    required this.userId,
    required this.username,
    this.generatedAvatar,
    required this.amountOwed,
    required this.status,
  });

  factory PaymentPayee.fromJson(Map<String, dynamic> j) => PaymentPayee(
    userId: j['user_id'] as String,
    username: j['username'] as String,
    generatedAvatar: j['generated_avatar'] as String?,
    amountOwed: j['amount_owed'] is num
        ? j['amount_owed'] as num
        : num.parse(j['amount_owed'] as String),
    status: PaymentPayeeStatus.fromDb(
      j['status'] as String? ??
          ((j['paid'] as bool? ?? false) ? 'paid_direct' : null),
    ),
  );
}

/// A payment request — either `split` (chia tiền, auto-created after a
/// session with a cost ends) or `ancillary` (đòi tiền trà đá, started by hand
/// by any attendee). `recipientId` is who the money is owed to; `payees` is
/// who owes it. See schema/lobby_payment_requests.sql.
final class PaymentRequestItem extends FeedItem {
  final String id;
  final String author;
  final String? authorId;
  final String? authorGeneratedAvatar;
  final String time;
  final String type; // 'split' | 'ancillary'
  final String? sourceActivityId;
  final String recipientId;
  final String? costType; // 'per_pax' | 'total' — split only
  final num totalAmount;
  final num perPersonAmount;
  final String? note;
  final List<PaymentPayee> payees;

  /// The activity this request is billing for — a real `lobby_feed_item
  /// .activity_id` column now, distinct from `sourceActivityId`
  /// (`payload->>'source_activity_id'`, kept for the amount/split math and
  /// display). Both create paths always set this, so a payment request is
  /// always activity-scoped and never appears in the general Feed tab.
  final String? activityId;

  const PaymentRequestItem({
    required this.id,
    required this.author,
    required this.authorId,
    this.authorGeneratedAvatar,
    required this.time,
    required this.type,
    required this.sourceActivityId,
    required this.recipientId,
    required this.costType,
    required this.totalAmount,
    required this.perPersonAmount,
    required this.note,
    required this.payees,
    this.activityId,
  });

  bool get isFullyPaid =>
      payees.isNotEmpty && payees.every((p) => p.status.isResolved);
}

// ─── Feed item widget router ────────────────────────────────────

class FeedItemWidget extends StatelessWidget {
  final FeedItem item;
  final String lobbyId;
  final String? captainId;
  const FeedItemWidget({
    super.key,
    required this.item,
    required this.lobbyId,
    this.captainId,
  });

  @override
  Widget build(BuildContext context) {
    return switch (item) {
      final DayDivItem d => _DayDivider(item: d),
      final UpdateItem u => _UpdateCard(item: u, captainId: captainId),
      final PersonalItem p => _PersonalCard(item: p, captainId: captainId),
      final SystemItem s => _SystemEvent(item: s),
      final PollItem po => _PollCard(
        item: po,
        lobbyId: lobbyId,
        captainId: captainId,
      ),
      final PaymentRequestItem pr => _PaymentRequestCard(
        item: pr,
        lobbyId: lobbyId,
        captainId: captainId,
      ),
      final WallPostItem w => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: PostCard(post: w.post),
      ),
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
  final String? authorId;
  final String? authorGeneratedAvatar;
  final String? captainId;
  final String time;

  const _AuthorRow({
    required this.name,
    required this.authorId,
    this.authorGeneratedAvatar,
    required this.captainId,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final authorId = this.authorId;
    final isLeader =
        authorId != null && captainId != null && authorId == captainId;

    final identity = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (authorId != null)
          PUserAvatar(
            userId: authorId,
            username: name,
            generatedAvatar: authorGeneratedAvatar,
            radius: 14,
          )
        else
          // Author row with no id at all (e.g. a deleted account) — nothing
          // to resolve a real avatar from, so this stays a plain initial.
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _memberColor(name),
            ),
            alignment: Alignment.center,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
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
            child: Text(
              'lobbyHub.feed.captain'.tr(),
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: _crimson,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ],
    );

    return Row(
      children: [
        authorId == null
            ? identity
            : GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    UserRoute(id: authorId, $extra: name).push(context),
                child: identity,
              ),
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
  final String? captainId;
  const _PersonalCard({required this.item, required this.captainId});

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
          _AuthorRow(
            name: item.author,
            authorId: item.authorId,
            authorGeneratedAvatar: item.authorGeneratedAvatar,
            captainId: captainId,
            time: item.time,
          ),
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
                          item.action.label.tr(),
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
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.background,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: colors.border.withValues(alpha: 0.8),
                        ),
                      ),
                      child: Text(
                        r.display,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
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
  final String? captainId;
  const _UpdateCard({required this.item, required this.captainId});

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
          _AuthorRow(
            name: item.author,
            authorId: item.authorId,
            authorGeneratedAvatar: item.authorGeneratedAvatar,
            captainId: captainId,
            time: item.time,
          ),
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
                      horizontal: 12,
                      vertical: 8,
                    ),
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
        ],
      ),
    );
  }
}

// ─── Poll card ─────────────────────────────────────────────────

class _PollCard extends ConsumerStatefulWidget {
  final PollItem item;
  final String lobbyId;
  final String? captainId;
  const _PollCard({
    required this.item,
    required this.lobbyId,
    required this.captainId,
  });

  @override
  ConsumerState<_PollCard> createState() => _PollCardState();
}

class _PollCardState extends ConsumerState<_PollCard> {
  // Optimistic local override so the tap feels instant; cleared once the
  // real vote lands (the provider refetch brings item.myVote back in sync).
  int? _pendingVote;
  bool _voting = false;

  Future<void> _vote(int index) async {
    if (_voting) return;
    setState(() {
      _pendingVote = index;
      _voting = true;
    });
    try {
      await ref
          .read(lobbyFeedControllerProvider(widget.lobbyId).notifier)
          .vote(widget.item.id, index);
    } catch (e, st) {
      Talker().handle(e, st, 'Poll vote failed');
      if (mounted) {
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.circleX),
          variant: .destructive,
          title: Text('lobbyHub.poll.voteFailed'.tr()),
          alignment: .bottomCenter,
        );
      }
    } finally {
      if (mounted) setState(() => _voting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final voted = _pendingVote ?? widget.item.myVote;
    // While a vote is in flight and the refetch hasn't caught up yet, bump
    // the chosen option by one so the tap feels instant; once the real
    // tallies land (myVote == _pendingVote) this stops applying on its own.
    final isPendingBump =
        _voting && _pendingVote != null && widget.item.myVote != _pendingVote;
    final total =
        widget.item.options.fold<int>(0, (s, o) => s + o.$2) +
        (isPendingBump ? 1 : 0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AuthorRow(
            name: widget.item.author,
            authorId: widget.item.authorId,
            authorGeneratedAvatar: widget.item.authorGeneratedAvatar,
            captainId: widget.captainId,
            time: widget.item.time,
          ),
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
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    color: _blueTint,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.bar_chart_rounded,
                          size: 13,
                          color: pbBlue,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'lobbyHub.poll.badge'.tr(),
                          style: const TextStyle(
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
                              votes:
                                  widget.item.options[i].$2 +
                                  (isPendingBump && voted == i ? 1 : 0),
                              total: total,
                              selected: voted == i,
                              onTap: () => _vote(i),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          'lobbyHub.poll.votes'.tr(
                            namedArgs: {
                              'current': '$total',
                              'total': '${widget.item.totalMembers}',
                            },
                          ),
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

// ─── Payment request card (chia tiền / đòi tiền trà đá) ────────

class _PaymentRequestCard extends ConsumerStatefulWidget {
  final PaymentRequestItem item;
  final String lobbyId;
  final String? captainId;
  const _PaymentRequestCard({
    required this.item,
    required this.lobbyId,
    required this.captainId,
  });

  @override
  ConsumerState<_PaymentRequestCard> createState() =>
      _PaymentRequestCardState();
}

class _PaymentRequestCardState extends ConsumerState<_PaymentRequestCard> {
  bool _marking = false;

  Future<void> _markPaid() async {
    if (_marking) return;
    setState(() => _marking = true);
    try {
      await ref
          .read(lobbyFeedControllerProvider(widget.lobbyId).notifier)
          .markPaymentRequestPaid(widget.item.id);
    } catch (e, st) {
      Talker().handle(e, st, 'Mark payment request paid failed');
      if (mounted) {
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.circleX),
          variant: .destructive,
          title: Text('lobbyHub.feed.paidConfirmFailed'.tr()),
          alignment: .bottomCenter,
        );
      }
    } finally {
      if (mounted) setState(() => _marking = false);
    }
  }

  Future<void> _pay(num amount) async {
    await payRecipient(
      context,
      recipientUserId: widget.item.recipientId,
      amount: amount,
      note: widget.item.note ?? 'lobbyHub.feed.splitFallback'.tr(),
      emptyMessage: 'lobbyHub.feed.recipientMissing'.tr(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final item = widget.item;
    final currentUserId = ref.watch(currentUserIdProvider);
    PaymentPayee? myPayee;
    if (currentUserId != null) {
      for (final p in item.payees) {
        if (p.userId == currentUserId) {
          myPayee = p;
          break;
        }
      }
    }
    final isSplit = item.type == 'split';
    final fg = item.isFullyPaid ? pbGreen : _amber;
    final bg = item.isFullyPaid ? _greenTint : _amberTint;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AuthorRow(
            name: item.author,
            authorId: item.authorId,
            authorGeneratedAvatar: item.authorGeneratedAvatar,
            captainId: widget.captainId,
            time: item.time,
          ),
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
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    color: bg,
                    child: Row(
                      children: [
                        Icon(
                          isSplit
                              ? Icons.pie_chart_outline_rounded
                              : Icons.local_cafe_outlined,
                          size: 13,
                          color: fg,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isSplit
                              ? 'lobbyHub.feed.split'.tr()
                              : 'lobbyHub.feed.request'.tr(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: fg,
                            letterSpacing: 0.7,
                          ),
                        ),
                        const Spacer(),
                        if (item.isFullyPaid)
                          Text(
                            'lobbyHub.feed.collected'.tr(),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: fg,
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
                        if (item.note != null && item.note!.isNotEmpty) ...[
                          Text(
                            item.note!,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF09090B),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                        Text(
                          'lobbyHub.feed.perPersonTotal'.tr(
                            namedArgs: {
                              'perPerson':
                                  '${formatVnd(item.perPersonAmount)}đ',
                              'total': '${formatVnd(item.totalAmount)}đ',
                            },
                          ),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: colors.mutedForeground,
                          ),
                        ),
                        const SizedBox(height: 9),
                        for (final payee in item.payees)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => UserRoute(
                                      id: payee.userId,
                                      $extra: payee.username,
                                    ).push(context),
                                    child: Row(
                                      children: [
                                        PUserAvatar(
                                          userId: payee.userId,
                                          username: payee.username,
                                          generatedAvatar:
                                              payee.generatedAvatar,
                                          radius: 11,
                                        ),
                                        const SizedBox(width: 7),
                                        Expanded(
                                          child: Text(
                                            payee.username,
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        switch (payee.status) {
                                          PaymentPayeeStatus.outstanding =>
                                            '${formatVnd(payee.amountOwed)}đ',
                                          PaymentPayeeStatus.paidDirect =>
                                            'lobbyHub.feed.sent'.tr(),
                                          PaymentPayeeStatus.clearedTogether =>
                                            'lobbyHub.feed.cleared'.tr(),
                                        },
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: payee.status.isResolved
                                              ? pbGreen
                                              : colors.mutedForeground,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (payee.status.isResolved) ...[
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.check_circle,
                                    size: 14,
                                    color: pbGreen,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        if (myPayee case final payee?
                            when payee.status ==
                                PaymentPayeeStatus.outstanding) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: FButton(
                                  variant: .outline,
                                  onPress: () => _pay(payee.amountOwed),
                                  child: Text('lobbyHub.feed.payNow'.tr()),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FButton(
                                  onPress: _marking ? null : _markPaid,
                                  child: _marking
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text('lobbyHub.feed.paid'.tr()),
                                ),
                              ),
                            ],
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

// ─── Photo card ────────────────────────────────────────────────
