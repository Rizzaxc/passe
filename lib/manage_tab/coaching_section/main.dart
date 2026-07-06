import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../core/format.dart';
import '../../core/model/enum.dart';
import '../../professional/professional_booking.dart';
import '../../router.dart';
import '../../ui/main.dart';
import 'coaching_controller.dart';
import 'review_sheet.dart';

/// Manage ▸ Coaching: the signed-in user's coach bookings
/// (`professional_booking` rows where the professional's role is coach).
///
/// This replaced a fully-mocked course/session/drill-block prototype — that
/// data model (structured curricula, per-session blocks, journeys) has no
/// backing tables, so this view is intentionally simpler: a hero for the
/// next upcoming session, then flat "sắp tới" / "đã qua" lists driven by
/// real bookings.
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

class _Content extends StatelessWidget {
  final List<ProfessionalBookingItem> bookings;

  const _Content({required this.bookings});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
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

    final upcoming = bookings.where((b) => b.isUpcoming).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    final past = bookings.where((b) => !b.isUpcoming).toList();
    final hero = upcoming.isEmpty ? null : upcoming.first;
    final restUpcoming = upcoming.length > 1
        ? upcoming.sublist(1)
        : const <ProfessionalBookingItem>[];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        if (hero != null) ...[_Hero(booking: hero), const SizedBox(height: 20)],
        if (restUpcoming.isNotEmpty) ...[
          _SectionHeader(
            title: 'Sắp tới',
            subtitle: '${restUpcoming.length} buổi',
          ),
          const SizedBox(height: 8),
          for (final b in restUpcoming) ...[
            _SessionCard(booking: b),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 12),
        ],
        if (past.isNotEmpty) ...[
          _SectionHeader(title: 'Đã qua', subtitle: '${past.length} buổi'),
          const SizedBox(height: 8),
          for (final b in past) ...[
            _SessionCard(booking: b),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
        ],
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

// ─── Cancel confirmation (shared by hero + session card) ───────────────────

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
          child: const Text('Huỷ Lịch'),
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

// ─── Hero (nearest upcoming session) ───────────────────────────────────────

class _Hero extends ConsumerWidget {
  final ProfessionalBookingItem booking;

  const _Hero({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const crimson = Color(0xFFDC143C);
    final isToday = _isToday(booking.start);
    final (label, _, _) = _statusStyle(context, booking.status);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: crimson,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
              fontSize: 22,
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
              Text(
                '${isToday ? "Hôm nay" : _relDay(booking.start)} · ${_fmtTime(booking.start)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
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
          Container(height: 1, color: Colors.white.withValues(alpha: 0.15)),
          Row(
            children: [
              if (booking.agreedRate != null)
                Text(
                  '${formatVnd(booking.agreedRate!)}₫',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              const Spacer(),
              FTappable(
                onPress: () => _confirmCancelBooking(context, ref, booking),
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
                    'Huỷ',
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
    );
  }
}

// ─── Session card (upcoming-beyond-hero + past) ────────────────────────────

class _SessionCard extends ConsumerWidget {
  final ProfessionalBookingItem booking;

  const _SessionCard({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final (label, fg, bg) = _statusStyle(context, booking.status);

    return FCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Row(
            spacing: 10,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Row(
                      spacing: 6,
                      children: [
                        Flexible(
                          child: Text(
                            booking.professionalName,
                            style: context.theme.typography.body.sm.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (booking.professionalVerified)
                          Icon(
                            FLucideIcons.badgeCheck,
                            size: 14,
                            color: pbBlue,
                          ),
                      ],
                    ),
                    if (booking.serviceType != null)
                      Text(
                        booking.serviceType!,
                        style: context.theme.typography.body.xs.copyWith(
                          color: colors.mutedForeground,
                        ),
                      ),
                  ],
                ),
              ),
              _StatusChip(label: label, color: fg, bg: bg),
            ],
          ),
          Row(
            spacing: 6,
            children: [
              Icon(
                FLucideIcons.calendar,
                size: 13,
                color: colors.mutedForeground,
              ),
              Text(
                '${_relDay(booking.start)} · ${_fmtTime(booking.start)}',
                style: context.theme.typography.body.sm.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (booking.agreedRate != null) ...[
                Text('·', style: TextStyle(color: colors.mutedForeground)),
                Text(
                  '${formatVnd(booking.agreedRate!)}₫',
                  style: context.theme.typography.body.sm.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.primary,
                  ),
                ),
              ],
            ],
          ),
          if (booking.locationName != null)
            Row(
              spacing: 6,
              children: [
                Icon(
                  FLucideIcons.mapPin,
                  size: 13,
                  color: colors.mutedForeground,
                ),
                Expanded(
                  child: Text(
                    booking.locationName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.theme.typography.body.xs.copyWith(
                      color: colors.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
          if (booking.isUpcoming || booking.reviewEligible || booking.reviewed)
            Row(
              children: [
                const Spacer(),
                if (booking.isUpcoming)
                  FButton(
                    variant: .outline,
                    onPress: () => _confirmCancelBooking(context, ref, booking),
                    child: const Text('Huỷ'),
                  )
                else if (booking.reviewEligible)
                  FButton(
                    onPress: () => showCoachingReviewSheet(
                      context,
                      bookingId: booking.id,
                      professionalId: booking.professionalId,
                      professionalName: booking.professionalName,
                    ),
                    child: const Text('Đánh giá'),
                  )
                else if (booking.reviewed)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 4,
                    children: [
                      Icon(FLucideIcons.star, size: 13, color: pbStar),
                      Text(
                        'Đã đánh giá',
                        style: context.theme.typography.body.xs.copyWith(
                          color: colors.mutedForeground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
        ],
      ),
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          title,
          style: context.theme.typography.body.lg.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            height: 1,
          ),
        ),
        Text(
          subtitle,
          style: context.theme.typography.body.xs.copyWith(
            color: colors.mutedForeground,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        Container(
          height: 170,
          decoration: BoxDecoration(
            color: colors.muted,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: 20),
        bar(120, 20),
        const SizedBox(height: 10),
        for (var i = 0; i < 2; i++) ...[
          FCard(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  bar(160, 16),
                  const SizedBox(height: 8),
                  bar(double.infinity, 14),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
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
