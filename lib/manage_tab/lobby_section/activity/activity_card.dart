// A single activity card in the Planner tab — date/time/location/cost,
// challenge block, attached coach/referee, RSVP strip + control, quick
// actions, captain-only cancel. Extracted from the old pinned hero (one
// card was assumed per lobby); a lobby can now have several of these.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../auth/auth_controller.dart';
import '../../../../auth/guest_prompt.dart';
import '../../../../core/feature_flags.dart';
import '../../../../core/format.dart';
import '../../../../core/model/enum.dart';
import '../../../../feed_tab/compose_post_sheet.dart';
import '../../../../ui/dialog.dart';
import '../../../../ui/theme.dart';
import '../../../../ui/user_avatar.dart';
import '../../../professional/pending_activity_booking_state.dart';
import '../../../router.dart';
import '../challenges_controller.dart';
import '../invite_member_sheet.dart';
import '../schedule_activity_controller.dart';
import '../schedule_activity_sheet.dart';
import 'confirmation_controller.dart';
import 'feed.dart';
import 'feed_controller.dart';
import 'note_sheet.dart';
import 'payment_request_sheet.dart';
import 'upcoming_controller.dart';

// ─── Color tokens ──────────────────────────────────────────────
// Two accents only: crimson (brand / priority) and green (the one
// semantic "positive" state — going / confirmed). Everything else is
// neutral theme grays.
const _crimson = Color(0xFFDC143C);
const _crimsonTint = Color(0xFFFFEBED);
const _green = Color(0xFF959D54);
const _greenTint = Color(0xFFEEF2E4);
const _amber = Color(0xFFC58A1A);
const _amberTint = Color(0xFFFDF3DC);

// ─── Card ──────────────────────────────────────────────────────

class ActivityCard extends ConsumerWidget {
  final String lobbyId;
  final UpcomingActivity upcoming;
  final bool isLeader;

  /// One-shot visual pulse — set when this card is the target of a
  /// notification deep-link, so it's obvious which one the user was sent to.
  final bool highlighted;

  /// History reuses this card after the session ends. Past cards keep the
  /// session identity, attendees, post-session actions, and activity log, but
  /// suppress RSVP, editing, booking, invite, and cancel controls.
  final bool isPast;

  const ActivityCard({
    super.key,
    required this.lobbyId,
    required this.upcoming,
    required this.isLeader,
    this.highlighted = false,
    this.isPast = false,
  });

  List<String> get _wd => [
    'lobbyHub.schedule.weekdaysShort.monday'.tr(),
    'lobbyHub.schedule.weekdaysShort.tuesday'.tr(),
    'lobbyHub.schedule.weekdaysShort.wednesday'.tr(),
    'lobbyHub.schedule.weekdaysShort.thursday'.tr(),
    'lobbyHub.schedule.weekdaysShort.friday'.tr(),
    'lobbyHub.schedule.weekdaysShort.saturday'.tr(),
    'lobbyHub.schedule.weekdaysShort.sunday'.tr(),
  ];

  String get _activityId => upcoming.activity.id!;

  String _dateLabel() {
    final d = upcoming.nextStart.toLocal();
    return '${_wd[d.weekday - 1]}, ${d.day}/${d.month}';
  }

  String _timeLabel() {
    final start = upcoming.nextStart.toLocal();
    final startStr =
        '${start.hour.toString().padLeft(2, '0')}:'
        '${start.minute.toString().padLeft(2, '0')}';
    final end = upcoming.nextEnd?.toLocal();
    if (end == null) return startStr;
    final endStr =
        '${end.hour.toString().padLeft(2, '0')}:'
        '${end.minute.toString().padLeft(2, '0')}';
    return '$startStr – $endStr';
  }

  String? _costLabel() {
    final amount = upcoming.costAmount;
    if (upcoming.costType == null || amount == null) return null;
    return upcoming.costType == 'per_pax'
        ? '${formatVnd(amount)}đ/người'
        : '${formatVnd(amount)}đ (tổng)';
  }

  String? _costWordsLabel() {
    final amount = upcoming.costAmount;
    if (upcoming.costType == null || amount == null) return null;
    return upcoming.costType == 'per_pax'
        ? 'lobbyHub.activity.costPerPersonWords'.tr(
            namedArgs: {'amount': formatVndWords(amount)},
          )
        : 'lobbyHub.activity.costTotalWords'.tr(
            namedArgs: {'amount': formatVndWords(amount)},
          );
  }

  String? _deadlineLabel() {
    final deadline = upcoming.confirmationDeadline;
    if (deadline == null) return null;
    final d = deadline.toLocal();
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return 'lobbyHub.activity.deadline'.tr(
      namedArgs: {'time': '${_wd[d.weekday - 1]}, ${d.day}/${d.month} $hh:$mm'},
    );
  }

  Future<void> _copyAddress(BuildContext context) async {
    final name = upcoming.locationName;
    if (name == null) return;
    final district = upcoming.locationDistrict;
    final text = district == null ? name : '$name, $district';
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.copy),
        title: Text('lobbyHub.activity.addressCopied'.tr()),
        alignment: .bottomCenter,
      );
    }
  }

  /// Hands off to whatever maps app the device has, same pattern as
  /// `lib/home_tab/location_section/main.dart`'s `_openDirections` — Apple
  /// Maps on iOS, a `geo:` intent (native app chooser) on Android, falling
  /// back to a Google Maps web URL. Unlike a Location venue, an activity's
  /// location can legitimately have no geocode yet (e.g. a lobby homeground
  /// scraped without lat/lon), so this falls back to the old copy-to-
  /// clipboard behavior instead of a dead/disabled button.
  Future<void> _openDirections(BuildContext context) async {
    final lat = upcoming.locationLat;
    final lon = upcoming.locationLon;
    if (lat == null || lon == null) {
      await _copyAddress(context);
      return;
    }

    final label = Uri.encodeComponent(upcoming.locationName ?? '');
    final nativeUri = defaultTargetPlatform == TargetPlatform.iOS
        ? Uri.parse('https://maps.apple.com/?daddr=$lat,$lon&q=$label')
        : Uri.parse('geo:$lat,$lon?q=$lat,$lon($label)');
    final webUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lon',
    );

    var launched = false;
    try {
      if (await canLaunchUrl(nativeUri)) {
        launched = await launchUrl(
          nativeUri,
          mode: LaunchMode.externalApplication,
        );
      }
      if (!launched) {
        launched = await launchUrl(
          webUri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (_) {
      launched = false;
    }

    if (!launched && context.mounted) {
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleX),
        variant: .destructive,
        title: Text('lobbyHub.activity.mapFailed'.tr()),
        alignment: .bottomCenter,
      );
    }
  }

  void _openReschedule(BuildContext context) {
    showScheduleActivitySheet(context, lobbyId, existing: upcoming);
  }

  void _bookCoach(BuildContext context, WidgetRef ref) {
    ref.read(pendingActivityBookingStateProvider.notifier).set(_activityId);
    const HomeProfessionalRoute().go(context);
  }

  Future<void> _postLate(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(lobbyFeedControllerProvider(lobbyId).notifier)
          .postPersonalAction('late', activityId: _activityId);
    } on AlreadyMarkedLateException {
      if (context.mounted) {
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.circleCheck),
          title: Text('lobbyHub.activity.lateDuplicate'.tr()),
          alignment: .bottomCenter,
        );
      }
    } catch (e, st) {
      Talker().handle(e, st, 'Post personal action failed');
      if (context.mounted) {
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.circleX),
          variant: .destructive,
          title: Text('lobbyHub.activity.postFailed'.tr()),
          alignment: .bottomCenter,
        );
      }
    }
  }

  void _openActivityNote(BuildContext context, WidgetRef ref) {
    if (!ensureSignedIn(context, ref)) return;
    showActivityNoteSheet(context, lobbyId: lobbyId, activityId: _activityId);
  }

  void _confirmCancel(BuildContext context, WidgetRef ref) {
    showFDialog(
      context: context,
      builder: (dialogCtx, style, animation) => PConfirmDialog(
        animation: animation,
        title: Text('lobbyHub.activity.cancelTitle'.tr()),
        body: Text('lobbyHub.activity.cancelBody'.tr()),
        direction: Axis.horizontal,
        actions: [
          FButton(
            variant: .outline,
            onPress: () => Navigator.of(dialogCtx).pop(),
            child: Text('lobbyHub.common.cancel'.tr()),
          ),
          FButton(
            variant: .destructive,
            onPress: () {
              Navigator.of(dialogCtx).pop();
              _doCancel(context, ref);
            },
            child: Text('lobbyHub.activity.cancelAction'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _doCancel(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(scheduleActivityControllerProvider(lobbyId).notifier)
          .cancel(_activityId);
    } catch (e, st) {
      Talker().handle(e, st, 'Cancel activity failed');
      if (context.mounted) {
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.circleX),
          variant: .destructive,
          title: Text('lobbyHub.activity.cancelFailed'.tr()),
          alignment: .bottomCenter,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final activityId = _activityId;
    final status = ref
        .watch(activityConfirmationControllerProvider(activityId))
        .value;
    final costLabel = _costLabel();
    final costWordsLabel = _costWordsLabel();
    final deadlineLabel = isPast ? null : _deadlineLabel();

    // Light select-watch on the already-fetched lobby feed (shared with the
    // Feed tab and every other card via the same lobbyId-keyed provider) —
    // no extra round-trip. Backed server-side by
    // the partial unique indexes for `late` and `note`; this is what makes
    // each one-shot action disappear once the member has used it.
    final myId = ref.watch(currentUserIdProvider);
    final myActivityActions = ref.watch(
      lobbyFeedControllerProvider(lobbyId).select(
        (async) => async.value
            ?.whereType<PersonalItem>()
            .where((i) => i.activityId == activityId && i.authorId == myId)
            .map((i) => i.action)
            .toSet(),
      ),
    );
    final alreadyLate =
        myActivityActions?.contains(PersonalActionKind.late) ?? false;
    final alreadyNoted =
        myActivityActions?.contains(PersonalActionKind.note) ?? false;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: highlighted ? 1.0 : 0.0, end: 0.0),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOut,
      builder: (context, pulse, child) {
        final borderColor =
            Color.lerp(colors.border, _crimson, pulse) ?? colors.border;
        return Container(
          margin: const EdgeInsets.fromLTRB(4, 0, 4, 12),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: pulse > 0.05 ? 2 : 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: child,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Crimson top strip — the one "this is a scheduled activity" signal.
          Container(height: 3, color: _crimson),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date + time
                Text(
                  _dateLabel(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF09090B),
                    letterSpacing: -0.5,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _timeLabel(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _crimson,
                    letterSpacing: -0.2,
                    height: 1.2,
                  ),
                ),
                if (upcoming.locationName != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        FLucideIcons.mapPin,
                        size: 14,
                        color: colors.mutedForeground,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        flex: 2,
                        child: Text(
                          upcoming.locationName!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: colors.secondaryForeground,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (upcoming.locationDistrict != null) ...[
                        Text(
                          ' · ',
                          style: TextStyle(
                            color: colors.mutedForeground.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            upcoming.locationDistrict!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: colors.mutedForeground,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                if (costLabel != null ||
                    deadlineLabel != null ||
                    upcoming.recurrenceDayOfWeek != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (upcoming.recurrenceDayOfWeek != null)
                        _Tag(
                          text: 'lobbyHub.activity.weekly'.tr(),
                          icon: Icons.repeat,
                          tone: 'neutral',
                        ),
                      if (costLabel != null)
                        _Tag(
                          text: 'lobbyHub.activity.cost'.tr(
                            namedArgs: {'amount': costLabel},
                          ),
                          icon: Icons.account_balance_wallet_outlined,
                          tone: 'neutral',
                        ),
                      if (deadlineLabel != null)
                        _Tag(
                          text: deadlineLabel,
                          icon: Icons.alarm_outlined,
                          tone: 'neutral',
                        ),
                    ],
                  ),
                  if (costWordsLabel != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      costWordsLabel,
                      style: context.theme.typography.body.xs.copyWith(
                        color: colors.mutedForeground,
                      ),
                    ),
                  ],
                ],
                // Lobby-vs-lobby match: who we're playing, and the manager
                // actions that turn an accepted challenge into a real one.
                if (ClientFeatureFlags.challengerFlow &&
                    !isPast &&
                    upcoming.challenge != null) ...[
                  const SizedBox(height: 10),
                  _ChallengeBlock(
                    lobbyId: lobbyId,
                    upcoming: upcoming,
                    challenge: upcoming.challenge!,
                    isLeader: isLeader,
                  ),
                ],
                // The hired referee, when there is one. A coach is never
                // attached to a lobby session any more — coaching is a course.
                if (upcoming.referee != null) ...[
                  const SizedBox(height: 10),
                  _AttachedProRow(
                    label: 'lobbyHub.activity.referee'.tr(),
                    icon: Icons.sports,
                    pro: upcoming.referee!,
                  ),
                ],
                const SizedBox(height: 12),
                // Confirmation summary — status from
                // ActivityConfirmationController. While loading we render
                // the avatar strip with no count so the layout doesn't pop.
                Row(
                  children: [
                    _RsvpAvatarRow(activityId: activityId),
                    const SizedBox(width: 10),
                    Expanded(child: _ConfirmationSummary(status: status)),
                  ],
                ),
                const SizedBox(height: 10),
                // RSVP segmented control — going / maybe / out are all
                // persisted (activity_confirmation.attendance); only
                // "going" counts toward the confirmation threshold. Once the
                // activity is confirmed, a member who's already "going" is
                // locked in — the DB (RLS on activity_confirmation) rejects
                // the change/retract either way, but locking it client-side
                // avoids a round-trip just to show an error.
                if (!isPast)
                  _RsvpControl(
                    value: status?.myAttendance?.value ?? '',
                    locked:
                        status?.activityConfirmed == true &&
                        status?.myAttendance == Attendance.going,
                    onChange: (v) async {
                      final next = Attendance.fromValue(v);
                      if (next == null) return;
                      if (!ensureSignedIn(context, ref)) return;
                      try {
                        await ref
                            .read(
                              activityConfirmationControllerProvider(
                                activityId,
                              ).notifier,
                            )
                            .setAttendance(activityId, next);
                      } catch (e, st) {
                        // Most likely: the activity got confirmed between this
                        // card's last load and the tap, and the DB's RLS (see
                        // schema/activity_confirmation_lock_after_confirmed.sql)
                        // rejected locking-in-a-"going"-member's change.
                        Talker().handle(e, st, 'setAttendance failed');
                        if (!context.mounted) return;
                        showFToast(
                          context: context,
                          icon: const Icon(FLucideIcons.circleX),
                          variant: .destructive,
                          title: Text('lobbyHub.activity.rsvpFailed'.tr()),
                          alignment: .bottomCenter,
                        );
                      }
                    },
                    onLockedTap: () => showFToast(
                      context: context,
                      icon: const Icon(FLucideIcons.lock),
                      title: Text('lobbyHub.activity.rsvpLocked'.tr()),
                      alignment: .bottomCenter,
                    ),
                  ),
                const SizedBox(height: 12),
                // Quick actions
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const ClampingScrollPhysics(),
                        child: Row(
                          children: [
                            if (!alreadyNoted) ...[
                              _QuickAction(
                                icon: Icons.sticky_note_2_outlined,
                                label: 'lobbyHub.activity.note'.tr(),
                                onTap: () => _openActivityNote(context, ref),
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (upcoming.locationName != null) ...[
                              _QuickAction(
                                icon: Icons.navigation_outlined,
                                label: 'lobbyHub.activity.directions'.tr(),
                                onTap: () => _openDirections(context),
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (!isPast && isLeader) ...[
                              // Opens the full schedule form (time, location,
                              // recurrence, cost, confirmation) — covers a
                              // location-less activity too, so there's no
                              // separate "add location" entry point.
                              _QuickAction(
                                icon: Icons.calendar_month_outlined,
                                label: 'lobbyHub.activity.edit'.tr(),
                                onTap: () => _openReschedule(context),
                              ),
                              const SizedBox(width: 6),
                              _QuickAction(
                                icon: Icons.school_outlined,
                                label: 'lobbyHub.activity.bookPro'.tr(),
                                onTap: () => _bookCoach(context, ref),
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (!isPast)
                              _QuickAction(
                                icon: Icons.person_add_alt_1_outlined,
                                label: 'lobbyHub.activity.invite'.tr(),
                                onTap: () =>
                                    showInviteMemberSheet(context, lobbyId),
                              ),
                            if (!isPast &&
                                status?.myAttendance == Attendance.going &&
                                !alreadyLate) ...[
                              const SizedBox(width: 6),
                              _QuickAction(
                                icon: Icons.access_time_rounded,
                                label: 'lobbyHub.activity.late'.tr(),
                                onTap: () => _postLate(context, ref),
                              ),
                            ],
                            if (isPast &&
                                status?.myAttendance == Attendance.going) ...[
                              const SizedBox(width: 6),
                              _QuickAction(
                                icon: Icons.add_photo_alternate_outlined,
                                label: 'lobbyHub.activity.postFeed'.tr(),
                                onTap: () => showComposePostSheet(
                                  context,
                                  lobbyId: lobbyId,
                                  activityId: activityId,
                                ),
                              ),
                              const SizedBox(width: 6),
                              _QuickAction(
                                icon: Icons.local_cafe_outlined,
                                label: 'lobbyHub.activity.requestMoney'.tr(),
                                onTap: () => showPaymentRequestSheet(
                                  context,
                                  lobbyId: lobbyId,
                                  activityId: activityId,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (!isPast && isLeader) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _confirmCancel(context, ref),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.more_horiz_rounded,
                            size: 18,
                            color: colors.secondaryForeground,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                _ActivityFeedLog(
                  lobbyId: lobbyId,
                  activityId: activityId,
                  initiallyExpanded: isPast && costLabel != null,
                  settlementDueAt: isPast && costLabel != null
                      ? (upcoming.nextEnd ?? upcoming.nextStart).add(
                          const Duration(minutes: 15),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Per-activity action log (notes, late reports, payments) ───────────────

/// Collapsed-by-default log of this activity's own scoped `personal` and
/// `payment_request` feed items — the actions a member fires from *this*
/// card, as opposed to lobby-wide `update`/poll/photo posts which stay on
/// the general Feed tab. See `perActivityFeedItems` in `feed.dart`.
class _ActivityFeedLog extends ConsumerStatefulWidget {
  final String lobbyId;
  final String activityId;
  final bool initiallyExpanded;
  final DateTime? settlementDueAt;

  const _ActivityFeedLog({
    required this.lobbyId,
    required this.activityId,
    this.initiallyExpanded = false,
    this.settlementDueAt,
  });

  @override
  ConsumerState<_ActivityFeedLog> createState() => _ActivityFeedLogState();
}

class _ActivityFeedLogState extends ConsumerState<_ActivityFeedLog> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          // The row below has a Spacer() filling the gap between the label
          // and the chevron — with the default `deferToChild` behavior nothing
          // in that empty middle claims the hit, so most of the row silently
          // eats taps. `opaque` makes the whole box (not just its painted
          // children) respond.
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 14,
                  color: colors.mutedForeground,
                ),
                const SizedBox(width: 6),
                Text(
                  'lobbyHub.activity.log'.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.secondaryForeground,
                  ),
                ),
                const Spacer(),
                Icon(
                  _expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 18,
                  color: colors.mutedForeground,
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          _ActivityFeedLogBody(
            lobbyId: widget.lobbyId,
            activityId: widget.activityId,
            settlementDueAt: widget.settlementDueAt,
          ),
      ],
    );
  }
}

class _ActivityFeedLogBody extends ConsumerWidget {
  final String lobbyId;
  final String activityId;
  final DateTime? settlementDueAt;

  const _ActivityFeedLogBody({
    required this.lobbyId,
    required this.activityId,
    this.settlementDueAt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final feedAsync = ref.watch(lobbyFeedControllerProvider(lobbyId));

    return feedAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'lobbyHub.activity.logFailed'.tr(),
          style: TextStyle(fontSize: 11.5, color: colors.mutedForeground),
        ),
      ),
      data: (items) {
        final scoped = perActivityFeedItems(items, activityId);
        final hasAutomaticSplit = scoped.any(
          (item) => item is PaymentRequestItem && item.type == 'split',
        );
        final settlementMessage = hasAutomaticSplit
            ? null
            : _settlementMessage(settlementDueAt);
        if (scoped.isEmpty && settlementMessage == null) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'lobbyHub.activity.logEmpty'.tr(),
              style: TextStyle(
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
                color: colors.mutedForeground,
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (settlementMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  settlementMessage,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: colors.mutedForeground,
                  ),
                ),
              ),
            for (final item in scoped)
              FeedItemWidget(item: item, lobbyId: lobbyId),
          ],
        );
      },
    );
  }

  String? _settlementMessage(DateTime? dueAt) {
    if (dueAt == null) return null;
    final localDue = dueAt.toLocal();
    if (DateTime.now().isBefore(localDue)) {
      final hh = localDue.hour.toString().padLeft(2, '0');
      final mm = localDue.minute.toString().padLeft(2, '0');
      return 'lobbyHub.activity.settlementAt'.tr(
        namedArgs: {'time': '$hh:$mm'},
      );
    }
    return 'lobbyHub.activity.settlementPending'.tr();
  }
}

// ─── Challenge block ────────────────────────────────────────────

/// The challenge half of the card: opponent + MMR, and the two manager
/// actions that move an accepted challenge forward.
///
/// "Xác nhận trận" is the manager half of official — the RPC refuses until
/// RSVP quorum is met, and the match only becomes `scheduled` once *both*
/// lobbies confirm. "Đặt trọng tài" is home-side only (the home team hires
/// the official) and reuses the existing `PendingActivityBookingState`
/// hand-off, which already attaches the resulting booking to
/// `referee_booking_id` by the booked pro's role.
class _ChallengeBlock extends ConsumerWidget {
  final String lobbyId;
  final UpcomingActivity upcoming;
  final ChallengeContext challenge;
  final bool isLeader;

  const _ChallengeBlock({
    required this.lobbyId,
    required this.upcoming,
    required this.challenge,
    required this.isLeader,
  });

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final activityId = upcoming.activity.id;
    if (activityId == null) return;
    try {
      await ref
          .read(confirmChallengeActivityControllerProvider(lobbyId).notifier)
          .confirm(activityId);
    } catch (e, st) {
      Talker().handle(e, st, 'confirm challenge activity failed');
      if (!context.mounted) return;
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleX),
        variant: .destructive,
        title: Text(confirmChallengeErrorMessage(e)),
        alignment: .bottomCenter,
      );
    }
  }

  void _bookReferee(BuildContext context, WidgetRef ref) {
    final activityId = upcoming.activity.id;
    if (activityId != null) {
      ref.read(pendingActivityBookingStateProvider.notifier).set(activityId);
    }
    const HomeProfessionalRoute().go(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final busy = ref.watch(confirmChallengeActivityControllerProvider(lobbyId));
    final confirmed = upcoming.managerConfirmedAt != null;
    final locked = challenge.status == 'scheduled';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _crimsonTint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.sports_kabaddi_outlined,
                size: 16,
                color: _crimson,
              ),
              const SizedBox(width: 8),
              // Opponent names are user-supplied and unbounded — this whole
              // group has to be able to shrink before the MMR chip does.
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text:
                            '${challenge.weAreHome ? 'lobbyHub.activity.home'.tr() : 'lobbyHub.activity.away'.tr()} ',
                        style: TextStyle(color: colors.mutedForeground),
                      ),
                      TextSpan(
                        text: challenge.opponentName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: _crimson),
                ),
              ),
              if (challenge.opponentMmr != null) ...[
                const SizedBox(width: 6),
                Text(
                  '${challenge.opponentMmr} MMR',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ],
          ),
          if (isLeader && !locked) ...[
            const SizedBox(height: 8),
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: FButton(
                    size: .sm,
                    variant: confirmed ? .outline : .primary,
                    onPress: (busy || confirmed)
                        ? null
                        : () => _confirm(context, ref),
                    child: Text(
                      confirmed
                          ? 'lobbyHub.activity.waitingOpponent'.tr()
                          : 'lobbyHub.activity.confirmMatch'.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // Only the home side hires the official.
                if (challenge.weAreHome && upcoming.referee == null)
                  Expanded(
                    child: FButton(
                      size: .sm,
                      variant: .outline,
                      onPress: () => _bookReferee(context, ref),
                      child: Text(
                        'lobbyHub.activity.bookReferee'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (locked && upcoming.referee == null) ...[
            const SizedBox(height: 6),
            Text(
              'lobbyHub.activity.unratedWarning'.tr(),
              style: TextStyle(fontSize: 11, color: colors.mutedForeground),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── RSVP avatar strip ──────────────────────────────────────────

class _RsvpAvatarRow extends ConsumerWidget {
  final String activityId;
  const _RsvpAvatarRow({required this.activityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // `activity_confirmation_status` only returns aggregate counts, so
    // this is a small separate query (activityAttendeesProvider) just
    // for the sample of who's going/maybe. Empty/loading/error all
    // render nothing — this strip is decorative, not load-bearing.
    final attendees =
        ref.watch(activityAttendeesProvider(activityId)).value ?? const [];
    if (attendees.isEmpty) return const SizedBox.shrink();

    return Row(
      spacing: 5,
      children: [
        for (final a in attendees)
          _RsvpAvatar(
            userId: a.userId,
            username: a.username,
            generatedAvatar: a.generatedAvatar,
            going: a.attendance == Attendance.going,
          ),
      ],
    );
  }
}

/// Status reads from the ring color (green = going, gray = anything else).
class _RsvpAvatar extends StatelessWidget {
  final String userId;
  final String username;
  final String? generatedAvatar;
  final bool going;

  const _RsvpAvatar({
    required this.userId,
    required this.username,
    this.generatedAvatar,
    required this.going,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final ringColor = going ? _green : colors.border;
    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: 2),
      ),
      child: PUserAvatar(
        userId: userId,
        username: username,
        generatedAvatar: generatedAvatar,
        radius: 11,
      ),
    );
  }
}

// ─── Confirmation summary text ─────────────────────────────────

/// Renders the "N/threshold" copy next to the avatar strip. When [status]
/// is null (still loading) we show nothing to avoid flicker; when there's
/// no threshold we just show the bare count.
class _ConfirmationSummary extends StatelessWidget {
  final ActivityConfirmationStatus? status;

  const _ConfirmationSummary({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final s = status;
    if (s == null) return const SizedBox.shrink();

    final label = s.threshold != null
        ? '${s.confirmedCount}/${s.threshold}'
        : '${s.confirmedCount}';
    final color = s.activityConfirmed ? _green : colors.secondaryForeground;

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        Icon(
          s.activityConfirmed ? Icons.check_circle : Icons.check_circle_outline,
          size: 14,
          color: color,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ─── RSVP segmented control ────────────────────────────────────

class _RsvpControl extends StatelessWidget {
  final String value;
  final bool locked;
  final ValueChanged<String> onChange;
  final VoidCallback? onLockedTap;

  const _RsvpControl({
    required this.value,
    this.locked = false,
    required this.onChange,
    this.onLockedTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          _RsvpBtn(
            id: 'going',
            label: 'lobbyHub.activity.going'.tr(),
            icon: Icons.check_rounded,
            active: value == 'going',
            tone: 'green',
            locked: locked,
            onTap: onChange,
            onLockedTap: onLockedTap,
          ),
          _RsvpBtn(
            id: 'maybe',
            label: 'lobbyHub.activity.maybe'.tr(),
            icon: Icons.help_outline_rounded,
            active: value == 'maybe',
            tone: 'neutral',
            locked: locked,
            onTap: onChange,
            onLockedTap: onLockedTap,
          ),
          _RsvpBtn(
            id: 'out',
            label: 'lobbyHub.activity.out'.tr(),
            icon: Icons.close_rounded,
            active: value == 'out',
            tone: 'neutral',
            locked: locked,
            onTap: onChange,
            onLockedTap: onLockedTap,
          ),
        ],
      ),
    );
  }
}

class _RsvpBtn extends StatelessWidget {
  final String id;
  final String label;
  final IconData icon;
  final bool active;
  final String tone;
  final bool locked;
  final ValueChanged<String> onTap;
  final VoidCallback? onLockedTap;

  const _RsvpBtn({
    required this.id,
    required this.label,
    required this.icon,
    required this.active,
    required this.tone,
    this.locked = false,
    required this.onTap,
    this.onLockedTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    // Only "going" gets the green semantic accent — "maybe" / "out" are
    // both neutral, differentiated by their icon rather than a hue.
    final fg = tone == 'green' ? _green : colors.secondaryForeground;
    final bg = tone == 'green' ? _greenTint : colors.secondary;

    return Expanded(
      child: GestureDetector(
        onTap: locked ? onLockedTap : () => onTap(id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: active ? bg : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (active && locked)
                Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: Icon(Icons.lock_outline, size: 12, color: fg),
                )
              else
                Icon(
                  icon,
                  size: 14,
                  color: active ? fg : colors.mutedForeground,
                ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                    color: active ? fg : colors.secondaryForeground,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Quick action chip ─────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: colors.mutedForeground),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: colors.secondaryForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Attached professional (referee / coach) ───────────────────

class _AttachedProRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final AttachedProfessional pro;

  const _AttachedProRow({
    required this.label,
    required this.icon,
    required this.pro,
  });

  (String, Color, Color) _statusStyle(BuildContext context) {
    final colors = context.theme.colors;
    return switch (pro.status) {
      ProfessionalBookingStatus.requested => (
        'lobbyHub.activity.bookingPending'.tr(),
        _amber,
        _amberTint,
      ),
      ProfessionalBookingStatus.confirmed => (
        'lobbyHub.activity.bookingConfirmed'.tr(),
        _green,
        _greenTint,
      ),
      ProfessionalBookingStatus.completed => (
        'lobbyHub.activity.bookingCompleted'.tr(),
        _green,
        _greenTint,
      ),
      // rejected / cancelled_by_client / cancelled_by_pro
      _ => (
        'lobbyHub.activity.bookingCancelled'.tr(),
        colors.mutedForeground,
        colors.secondary,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final (statusLabel, statusFg, statusBg) = _statusStyle(context);

    return GestureDetector(
      onTap: () =>
          ProfessionalDetailRoute(id: pro.professionalId).push(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: colors.secondary.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: colors.secondaryForeground),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.mutedForeground,
              ),
            ),
            const SizedBox(width: 8),
            // Name (+ verified) — the flexible span that ellipsizes first.
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      pro.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF09090B),
                      ),
                    ),
                  ),
                  if (pro.verified) ...[
                    const SizedBox(width: 3),
                    const Icon(
                      FLucideIcons.badgeCheck,
                      size: 13,
                      color: pbBlue,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: statusFg,
                ),
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              FLucideIcons.chevronRight,
              size: 14,
              color: colors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Inline tag ────────────────────────────────────────────────

class _Tag extends StatelessWidget {
  final String text;
  final IconData? icon;
  final String tone;

  const _Tag({required this.text, this.icon, this.tone = 'neutral'});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final Color fg = tone == 'crimson'
        ? _crimson
        : tone == 'green'
        ? _green
        : colors.secondaryForeground;
    final Color bg = tone == 'crimson'
        ? _crimsonTint
        : tone == 'green'
        ? _greenTint
        : colors.secondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
