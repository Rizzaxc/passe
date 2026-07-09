import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../core/format.dart';
import '../../ui/main.dart';
import 'pro_bookings_controller.dart';

/// Manage ▸ pro mode's "schedule" subtab — the pro's own confirmed
/// sessions. A simple date-grouped list rather than the player Manage tab's
/// full timeline/card calendar (`schedule_section/main.dart`) — that widget
/// is tightly coupled to the `my_schedule_data` RPC (player's own activities
/// + bookings as a *client*), not reusable for the professional-as-recipient
/// perspective without forking its private internals.
class ProScheduleSection extends ConsumerWidget {
  final String professionalId;

  const ProScheduleSection({super.key, required this.professionalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(proUpcomingBookingsProvider(professionalId));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(proUpcomingBookingsProvider(professionalId));
        await ref.read(proUpcomingBookingsProvider(professionalId).future);
      },
      child: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            PEmptySectionPlaceholder(subtitle: 'Không tải được lịch'),
          ],
        ),
        data: (bookings) {
          if (bookings.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
              children: const [
                PEmptySectionPlaceholder(
                  title: 'Chưa có buổi nào được xác nhận',
                  subtitle: 'Các buổi đã xác nhận sẽ hiện ở đây.',
                ),
              ],
            );
          }
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            itemCount: bookings.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _BookingCard(
              professionalId: professionalId,
              booking: bookings[i],
            ),
          );
        },
      ),
    );
  }
}

class _BookingCard extends ConsumerWidget {
  final String professionalId;
  final ProBookingItem booking;

  const _BookingCard({required this.professionalId, required this.booking});

  Future<void> _markComplete(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(proBookingActionControllerProvider(professionalId).notifier)
          .markComplete(booking.id);
    } catch (e, st) {
      Talker().handle(e, st, 'Mark complete failed');
      if (context.mounted) {
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.circleX),
          variant: .destructive,
          title: const Text('Không thể đánh dấu hoàn thành'),
          alignment: .bottomCenter,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final saving = ref.watch(
      proBookingActionControllerProvider(professionalId),
    );
    final isPastDue = booking.end.isBefore(DateTime.now());

    return FCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 6,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.clientName,
                  style: context.theme.typography.body.sm.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (booking.packageId != null)
                Icon(FLucideIcons.package, size: 14, color: colors.mutedForeground),
            ],
          ),
          if (booking.serviceType != null) Text(booking.serviceType!),
          Text(
            '${booking.start.day}/${booking.start.month} · '
            '${booking.start.hour.toString().padLeft(2, '0')}:${booking.start.minute.toString().padLeft(2, '0')}'
            ' - ${booking.end.hour.toString().padLeft(2, '0')}:${booking.end.minute.toString().padLeft(2, '0')}',
            style: context.theme.typography.body.xs.copyWith(
              color: colors.mutedForeground,
            ),
          ),
          if (booking.locationName != null)
            Text(
              booking.locationName!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.theme.typography.body.xs.copyWith(
                color: colors.mutedForeground,
              ),
            ),
          if (booking.agreedRate != null)
            Text(
              '${formatVnd(booking.agreedRate!)}₫',
              style: context.theme.typography.body.sm.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.primary,
              ),
            ),
          if (isPastDue)
            FButton(
              variant: .secondary,
              onPress: saving ? null : () => _markComplete(context, ref),
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Đánh Dấu Hoàn Thành'),
            ),
        ],
      ),
    );
  }
}
