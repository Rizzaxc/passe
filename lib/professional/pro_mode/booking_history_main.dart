import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/format.dart';
import '../../core/model/enum.dart';
import '../../ui/main.dart';
import 'pro_bookings_controller.dart';

(String, Color) _statusStyle(
  BuildContext context,
  ProfessionalBookingStatus s,
) {
  final colors = context.theme.colors;
  return switch (s) {
    ProfessionalBookingStatus.completed => (
      'homeTab.professional.mode.status.completed'.tr(),
      const Color(0xFF3F7E4B),
    ),
    ProfessionalBookingStatus.rejected => (
      'homeTab.professional.mode.status.rejected'.tr(),
      colors.mutedForeground,
    ),
    ProfessionalBookingStatus.cancelledByClient => (
      'homeTab.professional.mode.status.cancelledByClient'.tr(),
      colors.mutedForeground,
    ),
    ProfessionalBookingStatus.cancelledByPro => (
      'homeTab.professional.mode.status.cancelledByPro'.tr(),
      colors.mutedForeground,
    ),
    ProfessionalBookingStatus.requested => (
      'homeTab.professional.mode.status.requested'.tr(),
      colors.mutedForeground,
    ),
    ProfessionalBookingStatus.confirmed => (
      'homeTab.professional.mode.status.confirmed'.tr(),
      colors.primary,
    ),
  };
}

/// Manage ▸ pro mode's "history" subtab — completed/rejected/cancelled
/// bookings, most recent first.
class ProBookingHistorySection extends ConsumerWidget {
  final String professionalId;

  const ProBookingHistorySection({super.key, required this.professionalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(proBookingHistoryProvider(professionalId));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(proBookingHistoryProvider(professionalId));
        await ref.read(proBookingHistoryProvider(professionalId).future);
      },
      child: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            PEmptySectionPlaceholder(
              subtitle: 'homeTab.professional.mode.history.loadFailed'.tr(),
            ),
          ],
        ),
        data: (bookings) {
          if (bookings.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
              children: [
                PEmptySectionPlaceholder(
                  title: 'homeTab.professional.mode.history.emptyTitle'.tr(),
                  subtitle: 'homeTab.professional.mode.history.emptySubtitle'
                      .tr(),
                ),
              ],
            );
          }
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            itemCount: bookings.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _HistoryRow(booking: bookings[i]),
          );
        },
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final ProBookingItem booking;

  const _HistoryRow({required this.booking});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final (label, color) = _statusStyle(context, booking.status);

    return PCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(
                  booking.clientName,
                  style: context.theme.typography.body.sm.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${booking.start.day}/${booking.start.month}/${booking.start.year}'
                  '${booking.serviceType != null ? " · ${booking.serviceType}" : ""}',
                  style: context.theme.typography.body.xs.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
                if (booking.agreedRate != null)
                  Text(
                    '${formatVnd(booking.agreedRate!)}₫',
                    style: context.theme.typography.body.xs.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: context.theme.typography.body.xs.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
