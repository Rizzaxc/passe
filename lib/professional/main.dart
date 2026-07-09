import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../core/format.dart';
import '../core/model/enum.dart';
import '../core/model/professional_feed_item.dart';
import '../ui/theme.dart';
import 'booking_sheet.dart';
import 'controller.dart';

/// Messaging has no backing flow at all (no message/conversation table in
/// the schema), so the CTA honestly says so instead of silently no-op'ing.
void _showComingSoon(BuildContext context, String feature) {
  showFToast(
    context: context,
    icon: const Icon(FLucideIcons.hammer),
    title: Text('$feature sẽ sớm có mặt'),
    alignment: .bottomCenter,
  );
}

/// Full-page profile view for a coach / referee.
///
/// This route is not part of the main tab navigation — it's only
/// reachable as a destination from discovery flows (home professional
/// subtab cards, manage tab coaching links, search, push notifs, etc.).
/// When the caller already has the [ProfessionalFeedItem] in hand, it
/// can pass it as `$extra` to skip the fetch round-trip.
class ProfessionalDetailPage extends ConsumerWidget {
  final String id;
  final ProfessionalFeedItem? initialItem;

  const ProfessionalDetailPage({super.key, required this.id, this.initialItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (initialItem != null) return _Body(item: initialItem!);

    final async = ref.watch(professionalByIdProvider(id));
    return async.when(
      data: (item) => _Body(item: item),
      loading: () =>
          const _Shell(child: Center(child: CircularProgressIndicator())),
      error: (_, _) => _Shell(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Không tải được hồ sơ',
              style: context.theme.typography.body.sm.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Header + scaffolding shared by every state (loading, error, data).
class _Shell extends StatelessWidget {
  final Widget child;

  const _Shell({required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeaderBar(onBack: () => context.pop()),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  final VoidCallback onBack;

  const _HeaderBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Container(
      color: colors.background,
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: colors.secondaryForeground,
            ),
            padding: const EdgeInsets.all(6),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final ProfessionalFeedItem item;

  const _Body({required this.item});

  String get _initials {
    final cleaned = item.displayName
        .replaceAll(
          RegExp(r'^(hlv|coach|trọng tài)\s+', caseSensitive: false),
          '',
        )
        .trim();
    final parts = cleaned.split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final isCoach = item.role == ProfessionalRole.coach;
    // Single accent across the screen; role is conveyed by the label below,
    // not by switching colours.
    final accent = colors.primary;

    return _Shell(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                // ── Hero ──────────────────────────────────────────
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent,
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.28),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _initials,
                          style: TextStyle(
                            fontFamily:
                                context.theme.typography.body.xl3.fontFamily,
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: colors.primaryForeground,
                            height: 1,
                          ),
                        ),
                      ),
                      if (item.isVerified)
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: colors.card,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              FLucideIcons.badgeCheck,
                              size: 24,
                              color: pbBlue,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Name
                Center(
                  child: Text(
                    item.displayName,
                    style: context.theme.typography.body.xl2.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 4),

                // Role
                Center(
                  child: Text(
                    isCoach ? 'Huấn luyện viên' : 'Trọng tài',
                    style: context.theme.typography.body.sm.copyWith(
                      color: colors.mutedForeground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Stats row
                IntrinsicHeight(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: _StatTile(
                          icon: FLucideIcons.star,
                          iconColor: pbStar,
                          label: item.averageRating.toStringAsFixed(1),
                          sub: '${item.reviewCount} đánh giá',
                        ),
                      ),
                      if (item.experienceYears != null) ...[
                        Container(
                          width: 1,
                          color: colors.border,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        Flexible(
                          child: _StatTile(
                            icon: FLucideIcons.briefcaseBusiness,
                            iconColor: colors.mutedForeground,
                            label: '${item.experienceYears}',
                            sub: 'năm kinh nghiệm',
                          ),
                        ),
                      ],
                      // Price is the one fact this page was missing — it's
                      // shown on the discovery card but dropped once you
                      // reach the full profile, which is exactly where a
                      // booking decision gets made.
                      if (item.priceFrom != null) ...[
                        Container(
                          width: 1,
                          color: colors.border,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        Flexible(
                          child: _StatTile(
                            icon: FLucideIcons.wallet,
                            iconColor: colors.primary,
                            label: formatVnd(item.priceFrom!),
                            sub: 'đ/giờ',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                if (item.sports.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _SectionLabel('Môn'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final idx in item.sports)
                        _SportChip(
                          sport: idx >= 0 && idx < Sport.values.length
                              ? Sport.values[idx]
                              : Sport.others,
                        ),
                    ],
                  ),
                ],

                if (item.bio != null && item.bio!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _SectionLabel('Giới thiệu'),
                  const SizedBox(height: 6),
                  Text(
                    item.bio!,
                    style: context.theme.typography.body.sm.copyWith(
                      color: colors.foreground,
                      height: 1.55,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Sticky CTA ──────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.of(context).padding.bottom + 12,
            ),
            child: Row(
              spacing: 8,
              children: [
                Expanded(
                  child: FButton(
                    variant: .outline,
                    onPress: () => _showComingSoon(context, 'Nhắn tin'),
                    child: const Text('Nhắn tin'),
                  ),
                ),
                Expanded(
                  child: FButton(
                    onPress: () => showProfessionalBookingSheet(context, item),
                    child: const Text('Đặt lịch'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.theme.typography.body.xs.copyWith(
        color: context.theme.colors.mutedForeground,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String sub;

  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 4),
            // Flexible + ellipsis: this tile sits inside an outer Flexible
            // in the stats row (up to 3 tiles side by side), so a long
            // price/label on a narrow phone must truncate, not overflow.
            Flexible(
              child: Text(
                label,
                style: context.theme.typography.body.lg.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          sub,
          style: context.theme.typography.body.xs.copyWith(
            color: colors.mutedForeground,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _SportChip extends StatelessWidget {
  final Sport sport;

  const _SportChip({required this.sport});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 5,
        children: [
          sport.getIcon(size: 12),
          Text(
            sport.getLocalizedName(context),
            style: context.theme.typography.body.xs.copyWith(
              color: colors.secondaryForeground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
