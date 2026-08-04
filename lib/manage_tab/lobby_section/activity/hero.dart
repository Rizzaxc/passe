// Pinned activity hero — empty state and expanded state
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../../../auth/auth_controller.dart';
import '../../../../auth/guest_prompt.dart';
import '../../../../core/model/enum.dart';
import '../../../../core/payment/pay_recipient.dart';
import '../../../../ui/button_styles.dart';
import '../../../../ui/theme.dart';
import '../../../router.dart';
import '../invite_challenge_sheet.dart';
import '../invite_member_sheet.dart';
import '../schedule_activity_controller.dart';
import '../schedule_activity_sheet.dart';
import 'confirmation_controller.dart';
import 'feed_controller.dart';
import 'upcoming_controller.dart';

// ─── Color tokens ──────────────────────────────────────────────
// Two accents only: crimson (brand / pinned / priority) and green
// (the one semantic "positive" state — going / confirmed). Everything
// else in the hero is neutral theme grays.
const _crimson = Color(0xFFDC143C);
const _crimsonTint = Color(0xFFFFEBED);
const _green = Color(0xFF959D54);
const _greenTint = Color(0xFFEEF2E4);
const _amber = Color(0xFFC58A1A);
const _amberTint = Color(0xFFFDF3DC);

// ─── Entry point ───────────────────────────────────────────────

class ActivityHero extends ConsumerWidget {
  final String lobbyId;
  final UpcomingActivity? upcoming;
  final Sport? sport;
  final bool isLeader;
  final String? captainId;

  /// True once the feed below has scrolled away from the newest message
  /// (i.e. the user overscrolled into older history) — collapses the
  /// hero down to date + hour + confirmed count to give the feed more
  /// room, matching how a persistent header would shrink.
  final bool compact;

  const ActivityHero({
    super.key,
    required this.lobbyId,
    required this.upcoming,
    required this.sport,
    required this.isLeader,
    this.captainId,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = upcoming;
    if (activity == null) {
      return _HeroEmpty(lobbyId: lobbyId, isLeader: isLeader);
    }

    // Member-confirmation state for the current user + activity-level
    // confirmation roll-up. "Có Mặt" maps to a confirmation row; the
    // other RSVP states are local-only personal indicators that don't
    // touch the DB until we model attendance vs. confirmation
    // separately.
    final activityId = activity.activity.id!;
    final status = ref
        .watch(activityConfirmationControllerProvider(activityId))
        .value;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: _HeroExpanded(
        key: ValueKey(compact),
        lobbyId: lobbyId,
        upcoming: activity,
        sport: sport,
        isLeader: isLeader,
        captainId: captainId,
        status: status,
        compact: compact,
      ),
    );
  }
}

// ─── Empty state ───────────────────────────────────────────────

class _HeroEmpty extends ConsumerWidget {
  final String lobbyId;
  final bool isLeader;

  const _HeroEmpty({required this.lobbyId, required this.isLeader});

  Future<void> _remindCaptain(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(lobbyFeedControllerProvider(lobbyId).notifier)
          .postPersonalAction('remind_captain');
    } catch (e, st) {
      Talker().handle(e, st, 'Remind captain failed');
      if (context.mounted) {
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.circleX),
          variant: .destructive,
          title: const Text('Không thể gửi nhắc nhở'),
          alignment: .bottomCenter,
        );
      }
      return;
    }
    if (context.mounted) {
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.check),
        title: const Text('Đã nhắc đội trưởng'),
        alignment: .bottomCenter,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    return Padding(
      // 4-px horizontal inset matches FTabs' internal padding so the
      // card edge lines up with the tab pill edge (the FTabs widget
      // itself is wrapped by Padding(horizontal: 14) at the page level).
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(12),
          // Solid border instead of a hand-painted dashed one — the
          // dashed painter produced visibly stepped corners at this
          // width because the dash spacing didn't divide evenly around
          // the perimeter and used butt caps on the rounded arcs.
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: _crimsonTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_today_outlined,
                size: 22,
                color: _crimson,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Chưa có buổi chơi nào',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF09090B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isLeader
                  ? 'Lên lịch buổi mới hoặc mời lobby khác thách đấu để khởi động.'
                  : 'Đội trưởng chưa lên lịch buổi nào. Bạn có thể nhắc.',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: colors.mutedForeground,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (isLeader)
              Column(
                spacing: 8,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FButton(
                      size: .sm,
                      style: FButtonStyleExtension.accentBlueStyle(
                        context.theme.buttonStyles.primary.base,
                      ),
                      onPress: () =>
                          showScheduleActivitySheet(context, lobbyId),
                      child: const _CTALabel(
                        icon: Icon(Icons.calendar_month_outlined, size: 16),
                        label: 'Lên Lịch',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: FButton(
                      size: .sm,
                      onPress: () => showInviteChallengeSheet(context, lobbyId),
                      // Match the icon used in Discover ▸ Challenger.
                      child: const _CTALabel(
                        icon: FaIcon(
                          FontAwesomeIcons.fireFlameCurved,
                          size: 16,
                        ),
                        label: 'Mời Thách Đấu',
                        iconTrailing: true,
                      ),
                    ),
                  ),
                ],
              )
            else
              GestureDetector(
                onTap: () => _remindCaptain(context, ref),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colors.secondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        FLucideIcons.bell,
                        size: 14,
                        color: colors.secondaryForeground,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Nhắc đội trưởng',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colors.secondaryForeground,
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

/// Compact icon + label used inside the empty hero's two CTA buttons.
/// Color comes from whatever the enclosing [FButton]'s style resolves to
/// (crimson primary vs. the accent-blue style), not hardcoded here.
class _CTALabel extends StatelessWidget {
  final Widget icon;
  final String label;
  final bool iconTrailing;

  const _CTALabel({
    required this.icon,
    required this.label,
    this.iconTrailing = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = Flexible(
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: iconTrailing ? [text, icon] : [icon, text],
    );
  }
}

// ─── Expanded state ────────────────────────────────────────────

class _HeroExpanded extends ConsumerWidget {
  final String lobbyId;
  final UpcomingActivity upcoming;
  final Sport? sport;
  final bool isLeader;
  final String? captainId;
  final ActivityConfirmationStatus? status;
  final bool compact;

  const _HeroExpanded({
    super.key,
    required this.lobbyId,
    required this.upcoming,
    required this.sport,
    required this.isLeader,
    required this.captainId,
    required this.status,
    required this.compact,
  });

  static const _wd = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

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

  /// Just the start hour, for the compact (overscrolled) form.
  String _startTimeLabel() {
    final start = upcoming.nextStart.toLocal();
    return '${start.hour.toString().padLeft(2, '0')}:'
        '${start.minute.toString().padLeft(2, '0')}';
  }

  String? _prepaymentLabel() {
    final amount = upcoming.prepaymentAmount;
    if (!upcoming.prepaymentRequired || amount == null) return null;
    final unit = upcoming.paymentType == 'da' ? 'Đá' : 'đ';
    return '${amount.toStringAsFixed(0)} $unit';
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
        title: const Text('Đã sao chép địa chỉ'),
        alignment: .bottomCenter,
      );
    }
  }

  void _openReschedule(BuildContext context) {
    showScheduleActivitySheet(context, lobbyId, existing: upcoming);
  }

  Future<void> _payHost(BuildContext context) async {
    final hostId = captainId;
    final amount = upcoming.prepaymentAmount;
    if (hostId == null || amount == null) return;

    await payRecipient(
      context,
      recipientUserId: hostId,
      amount: amount,
      note: 'payment.depositNote'.tr(args: [_dateLabel()]),
      emptyMessage: 'payment.hostNoPaymentInfo'.tr(),
    );
  }

  void _confirmCancel(BuildContext context, WidgetRef ref) {
    showFDialog(
      context: context,
      builder: (dialogCtx, style, animation) => FDialog(
        animation: animation,
        title: const Text('Hủy buổi chơi?'),
        body: const Text(
          'Mọi thành viên sẽ thấy buổi này bị hủy trong Hoạt động.',
        ),
        direction: Axis.horizontal,
        actions: [
          FButton(
            variant: .outline,
            onPress: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Đóng'),
          ),
          FButton(
            variant: .destructive,
            onPress: () {
              Navigator.of(dialogCtx).pop();
              _doCancel(context, ref);
            },
            child: const Text('Hủy Buổi'),
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
          title: const Text('Không thể hủy buổi chơi'),
          alignment: .bottomCenter,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;

    if (compact) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Icon(Icons.event, size: 14, color: _crimson),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${_dateLabel()} · ${_startTimeLabel()}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF09090B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _ConfirmationSummary(status: status),
            ],
          ),
        ),
      );
    }

    final activityId = _activityId;
    final prepaymentLabel = _prepaymentLabel();
    final currentUserId = ref.watch(currentUserIdProvider);
    // 'da' (đá) deposits aren't real money yet (no ledger) — only a
    // 'manual' (out-of-app) prepayment has an actual bank/wallet transfer
    // to make. Never show this to the captain paying themselves.
    final canPayHost = upcoming.prepaymentRequired &&
        upcoming.prepaymentAmount != null &&
        upcoming.paymentType != 'da' &&
        captainId != null &&
        captainId != currentUserId;

    return Padding(
      // See _HeroEmpty above — 4-px inset aligns with tab pill edges.
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
      child: Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Crimson top strip — the one "this is pinned" signal.
            Container(height: 3, color: _crimson),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label row
                  Row(
                    children: [
                      Icon(Icons.push_pin_outlined, size: 13, color: _crimson),
                      const SizedBox(width: 5),
                      Text(
                        'Buổi tiếp theo',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                    // Location — real join from the activity's
                    // location_id (schema/activity_member_visibility.sql
                    // + upcoming_controller.dart). No pitch/court-number
                    // or match-format data exists on `activity`, so
                    // unlike the old mock there's nothing else to show
                    // here beyond name + district.
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
                  if (prepaymentLabel != null) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: [
                        _Tag(
                          text: 'Đặt cọc $prepaymentLabel',
                          icon: Icons.account_balance_wallet_outlined,
                          tone: 'neutral',
                        ),
                      ],
                    ),
                  ],
                  // Hired neutrals (referee / coach) attached to this session.
                  if (upcoming.referee != null || upcoming.coach != null) ...[
                    const SizedBox(height: 10),
                    if (upcoming.referee != null)
                      _AttachedProRow(
                        label: 'Trọng tài',
                        icon: Icons.sports,
                        pro: upcoming.referee!,
                      ),
                    if (upcoming.coach != null) ...[
                      if (upcoming.referee != null) const SizedBox(height: 6),
                      _AttachedProRow(
                        label: 'HLV',
                        icon: Icons.school_outlined,
                        pro: upcoming.coach!,
                      ),
                    ],
                  ],
                  const SizedBox(height: 12),
                  // Confirmation summary — status from the
                  // ActivityConfirmationController. While loading
                  // we render the avatar strip with no count so
                  // the layout doesn't pop.
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
                  // "going" counts toward the confirmation threshold. No
                  // segment is active until the member responds.
                  _RsvpControl(
                    value: status?.myAttendance?.value ?? '',
                    onChange: (v) {
                      final next = Attendance.fromValue(v);
                      if (next == null) return;
                      if (!ensureSignedIn(context, ref)) return;
                      ref
                          .read(
                            activityConfirmationControllerProvider(
                              activityId,
                            ).notifier,
                          )
                          .setAttendance(activityId, next);
                    },
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
                              if (upcoming.locationName != null) ...[
                                _QuickAction(
                                  icon: Icons.navigation_outlined,
                                  label: 'Chỉ Đường',
                                  onTap: () => _copyAddress(context),
                                ),
                                const SizedBox(width: 6),
                              ],
                              if (isLeader) ...[
                                _QuickAction(
                                  icon: Icons.calendar_month_outlined,
                                  label: 'Đổi Giờ',
                                  onTap: () => _openReschedule(context),
                                ),
                                const SizedBox(width: 6),
                              ],
                              _QuickAction(
                                icon: Icons.person_add_alt_1_outlined,
                                label: 'Mời',
                                onTap: () =>
                                    showInviteMemberSheet(context, lobbyId),
                              ),
                              if (canPayHost) ...[
                                const SizedBox(width: 6),
                                _QuickAction(
                                  icon: Icons.qr_code_rounded,
                                  label: 'Trả Tiền',
                                  onTap: () => _payHost(context),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (isLeader) ...[
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
                ],
              ),
            ),
          ],
        ),
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
            letter: a.username.isNotEmpty ? a.username[0].toUpperCase() : '?',
            going: a.attendance == Attendance.going,
          ),
      ],
    );
  }
}

/// Single neutral background for every avatar — status reads from the
/// ring color (green = going, gray = anything else), not from a
/// per-person hash-color palette.
class _RsvpAvatar extends StatelessWidget {
  final String letter;
  final bool going;

  const _RsvpAvatar({required this.letter, required this.going});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final ringColor = going ? _green : colors.border;
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.secondary,
        border: Border.all(color: ringColor, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: colors.secondaryForeground,
        ),
      ),
    );
  }
}

// ─── Confirmation summary text ─────────────────────────────────

/// Renders the "N có mặt … X người để chính thức" copy next to the
/// avatar strip. When [status] is null (still loading) we show nothing
/// to avoid flicker; when there's no threshold we just show the count.
/// Compact "confirmed / threshold" ratio (falls back to a bare count when
/// the activity has no confirmation threshold) instead of a sentence.
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
  final ValueChanged<String> onChange;

  const _RsvpControl({required this.value, required this.onChange});

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
            label: 'Có Mặt',
            icon: Icons.check_rounded,
            active: value == 'going',
            tone: 'green',
            onTap: onChange,
          ),
          _RsvpBtn(
            id: 'maybe',
            label: 'Có Thể',
            icon: Icons.help_outline_rounded,
            active: value == 'maybe',
            tone: 'neutral',
            onTap: onChange,
          ),
          _RsvpBtn(
            id: 'out',
            label: 'Vắng',
            icon: Icons.close_rounded,
            active: value == 'out',
            tone: 'neutral',
            onTap: onChange,
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
  final ValueChanged<String> onTap;

  const _RsvpBtn({
    required this.id,
    required this.label,
    required this.icon,
    required this.active,
    required this.tone,
    required this.onTap,
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
        onTap: () => onTap(id),
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
              Icon(icon, size: 14, color: active ? fg : colors.mutedForeground),
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
        'Chờ xác nhận',
        _amber,
        _amberTint,
      ),
      ProfessionalBookingStatus.confirmed => (
        'Đã xác nhận',
        _green,
        _greenTint,
      ),
      ProfessionalBookingStatus.completed => (
        'Hoàn thành',
        _green,
        _greenTint,
      ),
      // rejected / cancelled_by_client / cancelled_by_pro
      _ => ('Đã huỷ', colors.mutedForeground, colors.secondary),
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
                    const Icon(FLucideIcons.badgeCheck, size: 13, color: pbBlue),
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
