import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../core/format.dart';
import '../../core/model/enum.dart';
import '../../professional/next_session_sheet.dart';
import '../../professional/professional_booking.dart';
import '../../router.dart';
import '../../ui/main.dart';
import 'coaching_controller.dart';
import 'review_sheet.dart';

/// Manage ▸ Coaching: the signed-in user's coach bookings
/// (`professional_booking` rows where the professional's role is coach).
///
/// This replaced a fully-mocked course/session/drill-block prototype — that
/// data model (structured curricula, per-session blocks) has no backing
/// tables, so the *data* here is honest: everything below is a real
/// `professional_booking` row. The *visual language* — the crimson hero, the
/// colour-coded journey ribbon per coach, tap-a-cell-for-detail — is kept
/// close to the original mock on purpose (bookings grouped by professional
/// stand in for "courses"; ribbon cell colour reflects real status/review
/// state instead of fake paid/done flags).
class CoachingSection extends ConsumerWidget {
  const CoachingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(coachingBookingsProvider, (_, next) {
      if (next is AsyncError && context.mounted) {
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.circleX),
          variant: .destructive,
          title: const Text('Không tải được lịch huấn luyện'),
          alignment: .bottomCenter,
        );
      }
    });

    final bookingsAsync = ref.watch(coachingBookingsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(coachingBookingsProvider);
        await ref.read(coachingBookingsProvider.future);
      },
      child: bookingsAsync.when(
        loading: () => const _LoadingSkeleton(),
        error: (_, _) => const _Content(bookings: []),
        data: (bookings) => _Content(bookings: bookings),
      ),
    );
  }
}

// ─── Grouping: bookings by coach, one "journey" per coach ──────────────────

class _CoachJourney {
  final String professionalId;
  final String professionalName;
  final bool verified;
  final double rating;
  final int reviewCount;
  final List<ProfessionalBookingItem> sessions; // ascending by start

  const _CoachJourney({
    required this.professionalId,
    required this.professionalName,
    required this.verified,
    required this.rating,
    required this.reviewCount,
    required this.sessions,
  });

  DateTime? get nextUpcomingStart =>
      sessions.where((s) => s.isUpcoming).firstOrNull?.start;
}

List<_CoachJourney> _groupByCoach(List<ProfessionalBookingItem> bookings) {
  final byPro = <String, List<ProfessionalBookingItem>>{};
  for (final b in bookings) {
    byPro.putIfAbsent(b.professionalId, () => []).add(b);
  }

  final journeys = byPro.entries.map((entry) {
    final sessions = entry.value..sort((a, b) => a.start.compareTo(b.start));
    final first = sessions.first;
    return _CoachJourney(
      professionalId: entry.key,
      professionalName: first.professionalName,
      verified: first.professionalVerified,
      rating: first.professionalRating,
      reviewCount: first.professionalReviewCount,
      sessions: sessions,
    );
  }).toList();

  journeys.sort((a, b) {
    final an = a.nextUpcomingStart;
    final bn = b.nextUpcomingStart;
    if (an != null && bn != null) return an.compareTo(bn);
    if (an != null) return -1;
    if (bn != null) return 1;
    return b.sessions.last.start.compareTo(a.sessions.last.start);
  });

  return journeys;
}

// ─── Content ────────────────────────────────────────────────────────────────

class _Content extends StatelessWidget {
  final List<ProfessionalBookingItem> bookings;

  const _Content({required this.bookings});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 24, 0, 40),
        children: [
          PEmptySectionPlaceholder(
            title: 'Chưa có buổi tập nào',
            subtitle:
                'Đặt lịch với một huấn luyện viên ở Trang chủ để bắt đầu.',
          ),
          const SizedBox(height: 12),
          const _BrowseMoreCta(),
        ],
      );
    }

    final journeys = _groupByCoach(bookings);
    final upcoming = bookings.where((b) => b.isUpcoming).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    final hero = upcoming.firstOrNull;
    var heroIndex = 0;
    if (hero != null) {
      final heroJourney = journeys.firstWhere(
        (j) => j.professionalId == hero.professionalId,
      );
      heroIndex = heroJourney.sessions.indexOf(hero) + 1;
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 40),
      children: [
        if (hero != null) ...[
          _Hero(booking: hero, sessionIndex: heroIndex),
          const SizedBox(height: 20),
        ],
        for (final journey in journeys) ...[
          _CoachJourneyCard(journey: journey),
          const SizedBox(height: 16),
        ],
        const SizedBox(height: 4),
        const _BrowseMoreCta(),
      ],
    );
  }
}

// ─── Status → (label, fg, bg) ──────────────────────────────────────────────

(String, Color, Color) _statusStyle(
  BuildContext context,
  ProfessionalBookingStatus status,
) {
  final colors = context.theme.colors;
  return switch (status) {
    ProfessionalBookingStatus.requested => (
      'Chờ xác nhận',
      const Color(0xFF8E5D1F),
      const Color(0xFFFBE7D3),
    ),
    ProfessionalBookingStatus.confirmed => (
      'Đã xác nhận',
      pbBlue,
      pbBlue.withValues(alpha: 0.12),
    ),
    ProfessionalBookingStatus.completed => (
      'Hoàn thành',
      const Color(0xFF3F7E4B),
      const Color(0xFFDDF0E2),
    ),
    ProfessionalBookingStatus.rejected => (
      'Bị từ chối',
      colors.mutedForeground,
      colors.muted,
    ),
    ProfessionalBookingStatus.cancelledByClient => (
      'Đã huỷ',
      colors.mutedForeground,
      colors.muted,
    ),
    ProfessionalBookingStatus.cancelledByPro => (
      'HLV đã huỷ',
      colors.mutedForeground,
      colors.muted,
    ),
  };
}

/// Ribbon-cell palette. Built on top of [_statusStyle] rather than a second
/// parallel switch, so a "confirmed" cell in the ribbon and the "Đã xác
/// nhận" chip in the session-preview sheet always agree on what confirmed
/// looks like — only "today" (crimson) and reviewed/needs-review (green /
/// orange, which aren't `ProfessionalBookingStatus` values) are overrides.
(Color bg, Color fg, Color border) _cellStyle(
  BuildContext context,
  ProfessionalBookingItem s,
  bool highlightToday,
) {
  final colors = context.theme.colors;
  if (highlightToday) {
    return (colors.primary, colors.primaryForeground, colors.primary);
  }
  if (s.reviewEligible) {
    return (
      const Color(0xFFFBE7D3),
      const Color(0xFF8E5D1F),
      Colors.transparent,
    );
  }
  if (s.reviewed) {
    return (
      const Color(0xFFDDF0E2),
      const Color(0xFF3F7E4B),
      Colors.transparent,
    );
  }
  final (_, fg, bg) = _statusStyle(context, s.status);
  return (bg, fg, Colors.transparent);
}

// ─── Cancel confirmation (shared by hero + preview sheet) ──────────────────

void _confirmCancelBooking(
  BuildContext context,
  WidgetRef ref,
  ProfessionalBookingItem booking,
) {
  showFDialog(
    context: context,
    builder: (dialogCtx, style, animation) => FDialog(
      animation: animation,
      title: const Text('Huỷ lịch hẹn?'),
      body: Text('Yêu cầu đặt lịch với ${booking.professionalName} sẽ bị huỷ.'),
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
            _doCancelBooking(context, ref, booking.id);
          },
          child: const Text('Huỷ Lịch Hẹn'),
        ),
      ],
    ),
  );
}

Future<void> _doCancelBooking(
  BuildContext context,
  WidgetRef ref,
  String bookingId,
) async {
  try {
    await ref
        .read(coachingBookingActionControllerProvider.notifier)
        .cancel(bookingId);
  } catch (e, st) {
    Talker().handle(e, st, 'Cancel coaching booking failed');
    if (context.mounted) {
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleX),
        variant: .destructive,
        title: const Text('Không thể huỷ lịch hẹn'),
        alignment: .bottomCenter,
      );
    }
  }
}

class _MarkCompleteButton extends ConsumerWidget {
  final ProfessionalBookingItem session;

  const _MarkCompleteButton({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saving = ref.watch(coachingBookingActionControllerProvider);

    return FButton(
      onPress: saving
          ? null
          : () async {
              try {
                await ref
                    .read(coachingBookingActionControllerProvider.notifier)
                    .markComplete(session.id);
              } catch (e, st) {
                Talker().handle(e, st, 'Mark coaching booking complete failed');
                if (context.mounted) {
                  showFToast(
                    context: context,
                    icon: const Icon(FLucideIcons.circleX),
                    variant: .destructive,
                    title: const Text('Không thể đánh dấu hoàn thành'),
                    alignment: .bottomCenter,
                  );
                }
                return;
              }
              if (context.mounted) Navigator.of(context).pop();
            },
      child: saving
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text('Đánh Dấu Hoàn Thành'),
    );
  }
}

// ─── Hero (nearest upcoming session, across all coaches) ───────────────────

class _Hero extends ConsumerWidget {
  final ProfessionalBookingItem booking;
  final int sessionIndex;

  const _Hero({required this.booking, required this.sessionIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final isToday = _isToday(booking.start);
    final (label, _, _) = _statusStyle(context, booking.status);

    return Material(
      color: colors.primary,
      // 14px matches forui's FCard radius (its `lg` token) — every other
      // card-shaped surface in this screen is an FCard, so the hero locks
      // to the same corner scale instead of an arbitrary one.
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(18),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Decorative numeral, matching the old mock's per-session watermark.
            if (sessionIndex > 0)
              Positioned(
                right: -16,
                top: -28,
                child: Text(
                  '$sessionIndex',
                  style: TextStyle(
                    fontFamily: context.theme.typography.body.xl8.fontFamily,
                    fontSize: 140,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.1),
                    height: 1,
                  ),
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
              children: [
                Row(
                  children: [
                    Text(
                      'BUỔI TỚI',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  booking.professionalName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                    letterSpacing: -0.4,
                    height: 1.1,
                  ),
                ),
                if (booking.serviceType != null)
                  Text(
                    booking.serviceType!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                const SizedBox(height: 2),
                Row(
                  spacing: 8,
                  children: [
                    Icon(
                      FLucideIcons.calendar,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    Flexible(
                      child: Text(
                        '${isToday ? "Hôm nay" : _relDay(booking.start)} · ${_fmtTime(booking.start)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (booking.locationName != null)
                  Row(
                    spacing: 8,
                    children: [
                      Icon(
                        FLucideIcons.mapPin,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      Expanded(
                        child: Text(
                          booking.locationName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                Row(
                  children: [
                    if (booking.agreedRate != null)
                      Flexible(
                        child: Text(
                          '${formatVnd(booking.agreedRate!)}₫',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    const Spacer(),
                    FTappable(
                      onPress: () =>
                          _confirmCancelBooking(context, ref, booking),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Huỷ Lịch Hẹn',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Coach journey card: strip + ribbon ────────────────────────────────────

class _CoachJourneyCard extends StatelessWidget {
  final _CoachJourney journey;

  const _CoachJourneyCard({required this.journey});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final needsReview = journey.sessions.where((s) => s.reviewEligible).length;

    return FCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Row(
            spacing: 12,
            children: [
              _Avatar(name: journey.professionalName, size: 44),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 3,
                  children: [
                    Row(
                      spacing: 6,
                      children: [
                        Flexible(
                          child: Text(
                            journey.professionalName,
                            style: context.theme.typography.body.sm.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (journey.verified)
                          Icon(
                            FLucideIcons.badgeCheck,
                            size: 14,
                            color: pbBlue,
                          ),
                      ],
                    ),
                    Text(
                      '${journey.sessions.length} buổi',
                      style: context.theme.typography.body.xs.copyWith(
                        color: colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              _RatingBadge(
                rating: journey.rating,
                reviewCount: journey.reviewCount,
              ),
            ],
          ),
          _JourneyRibbon(sessions: journey.sessions),
          Row(
            children: [
              Icon(FLucideIcons.info, size: 11, color: colors.mutedForeground),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Chạm vào buổi để xem chi tiết',
                  style: context.theme.typography.body.xs.copyWith(
                    color: colors.mutedForeground,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (needsReview > 0) ...[
                const SizedBox(width: 8),
                _ReviewNudge(journey: journey, count: needsReview),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Tappable nudge for a coach's pending reviews — was a passive caption;
/// promoted to an actual affordance since "leave a review" is a real
/// business goal, not just a status readout. Opens the review sheet
/// straight for the oldest eligible session in this journey.
class _ReviewNudge extends StatelessWidget {
  final _CoachJourney journey;
  final int count;

  const _ReviewNudge({required this.journey, required this.count});

  @override
  Widget build(BuildContext context) {
    final target = journey.sessions.firstWhere((s) => s.reviewEligible);
    return FTappable(
      onPress: () => showCoachingReviewSheet(
        context,
        bookingId: target.id,
        professionalId: target.professionalId,
        professionalName: target.professionalName,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFBE7D3),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            const Icon(FLucideIcons.star, size: 11, color: Color(0xFF8E5D1F)),
            Text(
              '$count chờ đánh giá',
              style: context.theme.typography.body.xs.copyWith(
                color: const Color(0xFF8E5D1F),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JourneyRibbon extends StatelessWidget {
  final List<ProfessionalBookingItem> sessions;

  const _JourneyRibbon({required this.sessions});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: sessions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 4),
        itemBuilder: (context, i) {
          final s = sessions[i];
          final highlightToday = _isToday(s.start) && s.isUpcoming;
          final (bg, fg, border) = _cellStyle(context, s, highlightToday);

          return FTappable(
            onPress: () => showCoachingSessionSheet(context, session: s),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 36,
              height: 38,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: border),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontFamily: context.theme.typography.body.xs.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: fg,
                      height: 1,
                    ),
                  ),
                  if (highlightToday) ...[
                    const SizedBox(height: 2),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.theme.colors.primaryForeground,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Session preview sheet (tapping a ribbon cell) ─────────────────────────

/// Uses [showPSheet] (project-standard chrome) rather than a hand-rolled
/// `showFSheet` + `Container`, per the root CLAUDE.md rule that all sheets
/// go through the `PSheet` wrapper.
void showCoachingSessionSheet(
  BuildContext context, {
  required ProfessionalBookingItem session,
}) {
  showPSheet(
    context: context,
    builder: (_) => _SessionPreviewSheet(session: session),
  );
}

class _SessionPreviewSheet extends ConsumerWidget {
  final ProfessionalBookingItem session;

  const _SessionPreviewSheet({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final (label, fg, bg) = _statusStyle(context, session.status);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        Row(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Text(
                    session.professionalName,
                    style: context.theme.typography.body.lg.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (session.serviceType != null)
                    Text(
                      session.serviceType!,
                      style: context.theme.typography.body.sm.copyWith(
                        color: colors.mutedForeground,
                      ),
                    ),
                ],
              ),
            ),
            _StatusChip(label: label, color: fg, bg: bg),
          ],
        ),
        FCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: [
              _InfoRow(
                icon: FLucideIcons.calendar,
                label:
                    '${_relDay(session.start)}, ${_fmtTime(session.start)} - ${_fmtTime(session.end)}',
              ),
              if (session.locationName != null)
                _InfoRow(
                  icon: FLucideIcons.mapPin,
                  label: session.locationName!,
                ),
              if (session.agreedRate != null)
                _InfoRow(
                  icon: FLucideIcons.wallet,
                  label: '${formatVnd(session.agreedRate!)}₫',
                ),
            ],
          ),
        ),
        if (session.clientNotes != null && session.clientNotes!.isNotEmpty)
          _NoteBlock(label: 'GHI CHÚ CỦA BẠN', text: session.clientNotes!),
        if (session.professionalNotes != null &&
            session.professionalNotes!.isNotEmpty)
          _NoteBlock(label: 'GHI CHÚ TỪ HLV', text: session.professionalNotes!),
        if (session.isUpcoming)
          FButton(
            variant: .destructive,
            onPress: () {
              Navigator.of(context).pop();
              _confirmCancelBooking(context, ref, session);
            },
            child: const Text('Huỷ Lịch Hẹn'),
          )
        else if (session.completionEligible)
          _MarkCompleteButton(session: session)
        else if (session.needsNextPackageSession)
          FButton(
            onPress: () {
              Navigator.of(context).pop();
              showNextPackageSessionSheet(context, booking: session);
            },
            child: Text(
              'Đặt Buổi ${(session.packageSessionsUsed ?? 0) + 1}/${session.packageSessionsTotal}',
            ),
          )
        else if (session.reviewEligible)
          FButton(
            onPress: () {
              Navigator.of(context).pop();
              showCoachingReviewSheet(
                context,
                bookingId: session.id,
                professionalId: session.professionalId,
                professionalName: session.professionalName,
              );
            },
            child: const Text('Đánh Giá Buổi Này'),
          )
        else if (session.reviewed)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 4,
            children: [
              Icon(FLucideIcons.star, size: 14, color: pbStar),
              Text(
                'Bạn đã đánh giá buổi này',
                style: context.theme.typography.body.sm.copyWith(
                  color: colors.mutedForeground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        FButton(
          variant: .secondary,
          onPress: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Row(
      spacing: 8,
      children: [
        Icon(icon, size: 15, color: colors.secondaryForeground),
        Expanded(
          child: Text(
            label,
            style: context.theme.typography.body.sm.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _NoteBlock extends StatelessWidget {
  final String label;
  final String text;

  const _NoteBlock({required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8F0),
        border: Border.all(color: const Color(0xFFE8E1CB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Text(
            label,
            style: context.theme.typography.body.xs.copyWith(
              color: const Color(0xFF8E7B3F),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.7,
            ),
          ),
          Container(
            padding: const EdgeInsets.only(left: 10),
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: Color(0xFFC9B87C), width: 2),
              ),
            ),
            child: Text(
              '"$text"',
              style: context.theme.typography.body.sm.copyWith(
                color: colors.foreground,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared small widgets ───────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;
  final double size;

  const _Avatar({required this.name, required this.size});

  String get _initials {
    final cleaned = name
        .replaceAll(
          RegExp(r'^(hlv|coach|trọng tài)\s+', caseSensitive: false),
          '',
        )
        .trim();
    final parts = cleaned.split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          fontFamily: context.theme.typography.body.xs.fontFamily,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
          color: colors.primaryForeground,
          height: 1,
        ),
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final double rating;
  final int reviewCount;

  const _RatingBadge({required this.rating, required this.reviewCount});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: 2,
      children: [
        Row(
          spacing: 3,
          children: [
            Icon(FLucideIcons.star, size: 14, color: pbStar),
            Text(
              rating.toStringAsFixed(1),
              style: context.theme.typography.body.sm.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        Text(
          '($reviewCount)',
          style: context.theme.typography.body.xs.copyWith(
            color: context.theme.colors.mutedForeground,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;

  const _StatusChip({
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: context.theme.typography.body.xs.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BrowseMoreCta extends StatelessWidget {
  const _BrowseMoreCta();

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return FTappable(
      onPress: () => const HomeProfessionalRoute().go(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          spacing: 12,
          children: [
            Icon(FLucideIcons.search, size: 16, color: colors.mutedForeground),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    'Tìm huấn luyện viên',
                    style: context.theme.typography.body.sm.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Duyệt danh sách HLV theo môn ở Trang chủ.',
                    style: context.theme.typography.body.xs.copyWith(
                      color: colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
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

// ─── Loading skeleton ───────────────────────────────────────────────────────

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: BorderRadius.circular(6),
      ),
    );

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 40),
      children: [
        Container(
          height: 190,
          decoration: BoxDecoration(
            color: colors.muted,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < 2; i++) ...[
          FCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                Row(
                  spacing: 12,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colors.muted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(child: bar(120, 16)),
                  ],
                ),
                bar(double.infinity, 38),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

// ─── Formatting helpers ─────────────────────────────────────────────────────

bool _isToday(DateTime d) {
  final now = DateTime.now();
  return d.year == now.year && d.month == now.month && d.day == now.day;
}

String _fmtTime(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}h${d.minute.toString().padLeft(2, '0')}';

String _relDay(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(d.year, d.month, d.day);
  final diff = target.difference(today).inDays;

  if (diff == 0) return 'Hôm nay';
  if (diff == 1) return 'Ngày mai';
  if (diff == -1) return 'Hôm qua';
  if (diff.abs() < 7) {
    const names = [
      'CN',
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
    ];
    return names[d.weekday % 7];
  }
  return '${d.day}/${d.month}';
}
