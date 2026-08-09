import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../auth/auth_controller.dart';
import '../core/format.dart';
import '../core/model/enum.dart';
import '../core/model/location.dart';
import '../core/model/professional_feed_item.dart';
import '../router.dart';
import '../ui/main.dart';
import 'booking_location_field.dart';
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

class _Body extends ConsumerWidget {
  final ProfessionalFeedItem item;

  const _Body({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courtsAsync = ref.watch(preferredCourtsProvider(item.id));

    return _Shell(
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                    children: [
                      _ProfileHero(item: item),
                      const SizedBox(height: 18),
                      _CredentialBoard(item: item),
                      const SizedBox(height: 18),
                      _ProfileSection(
                        icon: FLucideIcons.mapPinned,
                        title: 'homeTab.professional.coverage'.tr(),
                        accent: pbMint,
                        child: _LocationContent(
                          item: item,
                          courtsAsync: courtsAsync,
                        ),
                      ),
                      if (item.sports.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _ProfileSection(
                          icon: FLucideIcons.trophy,
                          title: 'homeTab.professional.sports'.tr(),
                          accent: item.role == ProfessionalRole.coach
                              ? pbAmber
                              : pbCoral,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final idx in item.sports)
                                _SportChip(
                                  sport: idx >= 0 && idx < Sport.values.length
                                      ? Sport.values[idx]
                                      : Sport.others,
                                ),
                            ],
                          ),
                        ),
                      ],
                      if (item.bio?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 14),
                        _ProfileSection(
                          icon: FLucideIcons.messageSquareQuote,
                          title: 'homeTab.professional.about'.tr(),
                          accent: pbBlue,
                          child: Text(
                            item.bio!,
                            style: context.theme.typography.body.sm.copyWith(
                              color: pbInk.withValues(alpha: 0.82),
                              height: 1.6,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          _ProfileActions(item: item),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final ProfessionalFeedItem item;

  const _ProfileHero({required this.item});

  @override
  Widget build(BuildContext context) {
    final roleColor = item.role == ProfessionalRole.coach ? pbAmber : pbCoral;
    final radius = BorderRadius.circular(18);
    final location = _coverageLabel(context, item);

    return POffsetFrame(
      offsetColor: roleColor,
      borderRadius: radius,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.theme.colors.card,
          border: Border.all(color: pbInk.withValues(alpha: 0.16)),
          borderRadius: radius,
          boxShadow: context.theme.style.shadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _ProfileAvatar(item: item, color: roleColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 7,
                children: [
                  _RolePill(item: item, color: roleColor),
                  Text(
                    item.displayName,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: context.theme.typography.body.xl2.copyWith(
                      color: pbInk,
                      fontWeight: FontWeight.w900,
                      height: 1.04,
                    ),
                  ),
                  if (location != null)
                    Row(
                      children: [
                        const Icon(
                          FLucideIcons.mapPin,
                          size: 13,
                          color: pbBlueDeep,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.theme.typography.body.xs.copyWith(
                              color: pbBlueDeep,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
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

class _ProfileAvatar extends StatelessWidget {
  final ProfessionalFeedItem item;
  final Color color;

  const _ProfileAvatar({required this.item, required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            _initials(item.displayName),
            style: context.theme.typography.body.xl3.copyWith(
              color: pbInk,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
        if (item.isVerified)
          Positioned(
            right: -3,
            bottom: -3,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                FLucideIcons.badgeCheck,
                size: 21,
                color: pbBlueDeep,
              ),
            ),
          ),
      ],
    );
  }
}

class _RolePill extends StatelessWidget {
  final ProfessionalFeedItem item;
  final Color color;

  const _RolePill({required this.item, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.23),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 5,
      children: [
        Icon(
          item.role == ProfessionalRole.coach
              ? FLucideIcons.graduationCap
              : FLucideIcons.flag,
          size: 11,
          color: pbInk,
        ),
        Flexible(
          child: Text(
            item.role.getLocalizedName(context).toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.theme.typography.body.xs.copyWith(
              color: pbInk,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.65,
            ),
          ),
        ),
      ],
    ),
  );
}

class _CredentialBoard extends StatelessWidget {
  final ProfessionalFeedItem item;

  const _CredentialBoard({required this.item});

  @override
  Widget build(BuildContext context) {
    final metrics = <Widget>[
      _CredentialMetric(
        icon: FLucideIcons.star,
        value: item.averageRating.toStringAsFixed(1),
        label: 'homeTab.professional.reviews'.tr(
          namedArgs: {'count': '${item.reviewCount}'},
        ),
      ),
      if (item.experienceYears != null)
        _CredentialMetric(
          icon: FLucideIcons.briefcaseBusiness,
          value: '${item.experienceYears}',
          label: 'homeTab.professional.experience'.tr(
            namedArgs: {'years': '${item.experienceYears}'},
          ),
        ),
      if (item.priceFrom != null)
        _CredentialMetric(
          icon: FLucideIcons.wallet,
          value: formatVnd(item.priceFrom!),
          label:
              '${'homeTab.professional.startingFrom'.tr()} · đ/${item.priceFromKind == ProfessionalPricingKind.perSession ? 'buổi' : 'giờ'}',
        ),
    ];

    return PMatchBoard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < metrics.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: Colors.white.withValues(alpha: 0.18),
              ),
            Expanded(child: metrics[i]),
          ],
        ],
      ),
    );
  }
}

class _CredentialMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _CredentialMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    spacing: 5,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: pbAmber),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.theme.typography.body.lg.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
        ],
      ),
      Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: context.theme.typography.body.xs.copyWith(
          color: Colors.white.withValues(alpha: 0.58),
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.45,
        ),
      ),
    ],
  );
}

class _ProfileSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color accent;
  final Widget child;

  const _ProfileSection({
    required this.icon,
    required this.title,
    required this.accent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.theme.colors.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: pbInk.withValues(alpha: 0.12)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 13,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.32),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 15, color: pbInk),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                title.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.theme.typography.body.xs.copyWith(
                  color: pbInk,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
        child,
      ],
    ),
  );
}

class _LocationContent extends StatelessWidget {
  final ProfessionalFeedItem item;
  final AsyncValue<List<Location>> courtsAsync;

  const _LocationContent({required this.item, required this.courtsAsync});

  @override
  Widget build(BuildContext context) => courtsAsync.when(
    loading: () => const LinearProgressIndicator(minHeight: 2),
    error: (_, _) => _AreaFallback(item: item),
    data: (courts) {
      if (courts.isEmpty) return _AreaFallback(item: item);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 9,
        children: [
          Text(
            'homeTab.professional.preferredCourts'.tr().toUpperCase(),
            style: context.theme.typography.body.xs.copyWith(
              color: context.theme.colors.mutedForeground,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          for (final court in courts) _CourtRow(court: court),
        ],
      );
    },
  );
}

class _AreaFallback extends StatelessWidget {
  final ProfessionalFeedItem item;

  const _AreaFallback({required this.item});

  @override
  Widget build(BuildContext context) {
    final districts = item.preferredDistricts
        .map(VietnamLocationData.instance.findDistrictById)
        .whereType<District>()
        .toList();
    final city = City.values.where(
      (city) => city.dbIndex == item.preferredCityCluster,
    );

    if (districts.isEmpty && city.isEmpty) {
      return Text(
        'Địa điểm linh hoạt, xác nhận khi đặt lịch',
        style: context.theme.typography.body.sm.copyWith(
          color: context.theme.colors.mutedForeground,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        if (districts.isNotEmpty)
          for (final district in districts)
            _AreaChip(label: district.getLocalizedFullName(context))
        else
          _AreaChip(label: city.first.getLocalizedName(context)),
      ],
    );
  }
}

class _AreaChip extends StatelessWidget {
  final String label;

  const _AreaChip({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: pbMint.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 5,
      children: [
        const Icon(FLucideIcons.mapPin, size: 12, color: pbBlueDeep),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.theme.typography.body.xs.copyWith(
              color: pbInk,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _CourtRow extends StatelessWidget {
  final Location court;

  const _CourtRow({required this.court});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
    decoration: BoxDecoration(
      color: pbBlueDeep.withValues(alpha: 0.055),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Row(
      children: [
        const Icon(FLucideIcons.mapPinned, size: 17, color: pbBlueDeep),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Text(
                court.hasName ? court.name : 'Địa điểm',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.theme.typography.body.sm.copyWith(
                  color: pbInk,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (court.displayAddress.isNotEmpty)
                Text(
                  court.displayAddress,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.theme.typography.body.xs.copyWith(
                    color: context.theme.colors.mutedForeground,
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ProfileActions extends ConsumerWidget {
  final ProfessionalFeedItem item;

  const _ProfileActions({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
    decoration: BoxDecoration(
      color: context.theme.colors.background,
      border: Border(
        top: BorderSide(color: pbInk.withValues(alpha: 0.1)),
      ),
    ),
    padding: EdgeInsets.fromLTRB(
      18,
      12,
      18,
      MediaQuery.paddingOf(context).bottom + 12,
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Row(
          spacing: 9,
          children: [
            Expanded(
              child: FButton(
                variant: .outline,
                onPress: () => _showComingSoon(
                  context,
                  'homeTab.professional.message'.tr(),
                ),
                child: Text('homeTab.professional.message'.tr()),
              ),
            ),
            Expanded(
              flex: 2,
              child: FButton(
                style: FButtonStyleExtension.accentBlueStyle(
                  context.theme.buttonStyles.primary.base,
                ),
                onPress: () {
                  if (ref.read(currentUserIdProvider) == null) {
                    const ProfileRoute().go(context);
                    return;
                  }
                  showProfessionalBookingSheet(context, item);
                },
                child: Text('homeTab.professional.book'.tr()),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SportChip extends StatelessWidget {
  final Sport sport;

  const _SportChip({required this.sport});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: pbBlueDeep.withValues(alpha: 0.07),
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
              color: pbInk,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

String _initials(String displayName) {
  final cleaned = displayName
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

String? _coverageLabel(BuildContext context, ProfessionalFeedItem item) {
  if (item.preferredLocationNames.isNotEmpty) {
    final extra = item.preferredLocationNames.length - 1;
    return extra > 0
        ? '${item.preferredLocationNames.first} +$extra'
        : item.preferredLocationNames.first;
  }
  final districts = item.preferredDistricts
      .map(VietnamLocationData.instance.findDistrictById)
      .whereType<District>()
      .toList();
  if (districts.isNotEmpty) {
    final extra = districts.length - 1;
    return extra > 0
        ? '${districts.first.getLocalizedFullName(context)} +$extra'
        : districts.first.getLocalizedFullName(context);
  }
  final city = City.values.where(
    (city) => city.dbIndex == item.preferredCityCluster,
  );
  return city.isEmpty ? null : city.first.getLocalizedName(context);
}
