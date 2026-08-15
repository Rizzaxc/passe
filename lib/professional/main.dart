import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../auth/auth_controller.dart';
import '../core/feature_flags.dart';
import '../core/format.dart';
import '../core/icon/main.dart';
import '../core/model/enum.dart';
import '../core/model/location.dart';
import '../core/model/professional_feed_item.dart';
import '../core/state/selected_sport_state.dart';
import '../core/zalo_link.dart';
import '../course/course_controller.dart';
import '../course/message_coach_sheet.dart';
import '../router.dart';
import '../ui/main.dart';
import 'booking_controller.dart';
import 'booking_location_field.dart';
import 'booking_sheet.dart';
import 'controller.dart';

/// Still used for **referees**: they have no course flow, and there's no
/// direct-message surface for them yet. Coaches now go through
/// [_messageCoach] instead — messaging a coach opens their course thread.
/// A referee who's set up their Zalo (`professionalZalo` in controller.dart,
/// `user_contact` table) surfaces it as a deep-link button next to this one
/// (`_ProfileActions`) in the meantime — see
/// `schema/user_contact_professional_visibility.sql`.
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
    final servicesAsync = ref.watch(professionalServicesProvider(item.id));

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
                      const SizedBox(height: 14),
                      _ProfileSection(
                        icon: FLucideIcons.listChecks,
                        title: 'homeTab.professional.services'.tr(),
                        accent: item.role == ProfessionalRole.coach
                            ? pbAmber
                            : pbCoral,
                        child: _ServicesContent(servicesAsync: servicesAsync),
                      ),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            FLucideIcons.mapPin,
                            size: 13,
                            color: pbBlueDeep,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            location,
                            softWrap: true,
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
    final linkedUserId = item.linkedUserId;
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
          // Same resolver as every other user-facing avatar (`PUserAvatar`);
          // initials-on-color only when this pro has no linked `user`.
          child: linkedUserId == null
              ? Text(
                  _initials(item.displayName),
                  style: context.theme.typography.body.xl3.copyWith(
                    color: pbInk,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                )
              : PUserAvatar(
                  userId: linkedUserId,
                  username: item.displayName,
                  generatedAvatar: item.generatedAvatar,
                  radius: 41,
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

class _ServicesContent extends StatelessWidget {
  final AsyncValue<List<ProfessionalServiceOption>> servicesAsync;

  const _ServicesContent({required this.servicesAsync});

  @override
  Widget build(BuildContext context) => servicesAsync.when(
    loading: () => const LinearProgressIndicator(minHeight: 2),
    error: (_, _) => Text(
      'homeTab.professional.servicesLoadFailed'.tr(),
      style: context.theme.typography.body.sm.copyWith(
        color: context.theme.colors.mutedForeground,
      ),
    ),
    data: (services) {
      if (services.isEmpty) {
        return Text(
          'homeTab.professional.noServices'.tr(),
          style: context.theme.typography.body.sm.copyWith(
            color: context.theme.colors.mutedForeground,
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          for (final service in services) _PublicServiceCard(service: service),
        ],
      );
    },
  );
}

class _PublicServiceCard extends StatelessWidget {
  final ProfessionalServiceOption service;

  const _PublicServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    final sport = service.sportId >= 0 && service.sportId < Sport.values.length
        ? Sport.values[service.sportId]
        : Sport.others;
    final price = service.priceAmount;
    final priceLabel = price == null
        ? null
        : (service.pricingKind == ProfessionalPricingKind.hourly
                  ? 'homeTab.professional.pricePerHour'
                  : 'homeTab.professional.pricePerSession')
              .tr(namedArgs: {'price': formatVnd(price)});

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: pbBlueDeep.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: pbInk.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  service.serviceType,
                  style: context.theme.typography.body.sm.copyWith(
                    color: pbInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (priceLabel != null) ...[
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    priceLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: context.theme.typography.body.sm.copyWith(
                      color: pbBlueDeep,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (service.description?.trim().isNotEmpty == true)
            Text(
              service.description!.trim(),
              style: context.theme.typography.body.xs.copyWith(
                color: context.theme.colors.mutedForeground,
                height: 1.45,
              ),
            ),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _ServiceDetailChip(
                icon: FLucideIcons.trophy,
                label: sport.getLocalizedName(context),
              ),
              if (service.minDurationMinutes != null)
                _ServiceDetailChip(
                  icon: FLucideIcons.clock,
                  label: 'homeTab.professional.minimumDuration'.tr(
                    namedArgs: {'minutes': '${service.minDurationMinutes}'},
                  ),
                ),
              if (service.sessionCount > 1)
                _ServiceDetailChip(
                  icon: FLucideIcons.layers,
                  label: 'homeTab.professional.sessionCount'.tr(
                    namedArgs: {'count': '${service.sessionCount}'},
                  ),
                ),
              if (service.maxParticipants != null &&
                  service.maxParticipants! > 1)
                _ServiceDetailChip(
                  icon: FLucideIcons.users,
                  label: 'homeTab.professional.maxParticipants'.tr(
                    namedArgs: {'count': '${service.maxParticipants}'},
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ServiceDetailChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ServiceDetailChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: context.theme.colors.card,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: pbInk.withValues(alpha: 0.09)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 5,
      children: [
        Icon(icon, size: 11, color: pbBlueDeep),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.theme.typography.body.xs.copyWith(
              color: pbInk,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
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
            softWrap: true,
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
                softWrap: true,
                style: context.theme.typography.body.sm.copyWith(
                  color: pbInk,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (court.displayAddress.isNotEmpty)
                Text(
                  court.displayAddress,
                  softWrap: true,
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

/// Opens the course thread with this coach for the context sport if one
/// already exists, otherwise opens the ephemeral first-message sheet.
///
/// Nothing is created server-side by tapping "Nhắn tin" alone — a course only
/// comes into existence once a real first message is sent
/// (`message_coach_sheet.dart`). A bare inquiry-with-no-message used to be
/// created eagerly here, which left the coach a course-list entry with no
/// message, no sender, and no notification the moment a student opened the
/// thread and backed out without typing anything.
///
/// A coach's sport list can be wider than the sport the user is browsing in;
/// the context sport is what scopes the course, matching every other feed on
/// this screen. Guests get the standard sign-in prompt instead.
Future<void> _messageCoach(
  BuildContext context,
  WidgetRef ref,
  ProfessionalFeedItem item,
) async {
  if (ref.read(currentUserIdProvider) == null) {
    const ProfileRoute().go(context);
    return;
  }

  // A course is bound to one sport for its whole life, so there's nothing
  // sensible to create without one. Say so rather than letting the tap do
  // nothing — the sport selector is right there in the appbar.
  final sport = ref.read(selectedSportStateProvider).value;
  if (sport == null || sport == Sport.others) {
    showFToast(
      context: context,
      icon: const Icon(FLucideIcons.circleAlert),
      title: Text('course.pickSportFirst'.tr()),
      alignment: .bottomCenter,
    );
    return;
  }

  try {
    final existingCourseId = await ref.read(
      courseWithCoachProvider(item.id, sport.index).future,
    );
    if (!context.mounted) return;

    if (existingCourseId != null) {
      // go(), not push(): this profile page is a root-level screen, and
      // CourseDetailRoute is nested under the Manage tab's shell branch.
      // Pushing a nested-shell path onto a root screen collides with the
      // shell's own preserved branch state — go_router throws a duplicate-
      // GlobalKey assertion the moment the SAME course is opened a second
      // time. go() replaces the stack instead of appending to it, so it
      // can't collide. Same fix as notification/main.dart's tap handler,
      // which hit this exact pattern first.
      CourseDetailRoute(id: existingCourseId).go(context);
      return;
    }

    await showMessageCoachSheet(
      context,
      professionalId: item.id,
      sportId: sport.index,
      coachName: item.displayName,
    );
  } catch (e, st) {
    Talker().handle(e, st, 'Message coach failed');
    if (context.mounted) {
      showFToast(
        context: context,
        variant: .destructive,
        title: Text('course.actionFailed'.tr()),
      );
    }
  }
}

class _ProfileActions extends ConsumerWidget {
  final ProfessionalFeedItem item;

  const _ProfileActions({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The feed already excludes a coach/referee's own listing
    // (home_professional_data_exclude_self.sql), but this page is also
    // reachable by id directly (deep link, notification, a stale $extra) —
    // message_coach() itself rejects self-messaging server-side, but the
    // button shouldn't be there to tap in the first place.
    final isOwnListing =
        ref.watch(linkedProfessionalIdProvider).value == item.id;
    final zalo = isOwnListing
        ? null
        : ref.watch(professionalZaloProvider(item.id)).value;

    return Container(
      decoration: BoxDecoration(
        color: context.theme.colors.background,
        border: Border(top: BorderSide(color: pbInk.withValues(alpha: 0.1))),
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
          child: isOwnListing
              ? Text(
                  'homeTab.professional.ownListing'.tr(),
                  textAlign: TextAlign.center,
                  style: context.theme.typography.body.sm.copyWith(
                    color: context.theme.colors.mutedForeground,
                  ),
                )
              : Row(
                  spacing: 9,
                  children: [
                    // A coach's only CTA is "message" — that's the entry point into
                    // the whole course flow: the first message creates the course (in
                    // `inquiring` state) and the coach turns it into an enrollment
                    // from their side. The RPC is idempotent, so tapping again reopens
                    // the same thread rather than starting a second one.
                    //
                    // A referee still gets the booking CTA, gated with the challenger
                    // flow it exists to serve. There is deliberately no disabled
                    // "book" button on a coach: coaching is not a booking any more,
                    // so offering one greyed-out would just be a lie about what's
                    // coming.
                    if (item.role == ProfessionalRole.coach)
                      Expanded(
                        child: FButton(
                          style: FButtonStyleExtension.accentBlueStyle(
                            context.theme.buttonStyles.primary.base,
                          ),
                          onPress: () => _messageCoach(context, ref, item),
                          child: Text('homeTab.professional.message'.tr()),
                        ),
                      )
                    else
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
                    if (zalo != null)
                      FButton.icon(
                        variant: .outline,
                        onPress: () => openZaloChat(context, zalo),
                        child: const SizedBox(
                          width: 24,
                          height: 24,
                          child: PasseIcons.zaloLogo,
                        ),
                      ),
                    if (item.role == ProfessionalRole.referee &&
                        ClientFeatureFlags.refereeFlow)
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
    return item.preferredLocationNames.join(' • ');
  }
  final districts = item.preferredDistricts
      .map(VietnamLocationData.instance.findDistrictById)
      .whereType<District>()
      .toList();
  if (districts.isNotEmpty) {
    return districts
        .map((district) => district.getLocalizedFullName(context))
        .join(' • ');
  }
  final city = City.values.where(
    (city) => city.dbIndex == item.preferredCityCluster,
  );
  return city.isEmpty ? null : city.first.getLocalizedName(context);
}
