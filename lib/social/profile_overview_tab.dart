import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../core/icon/main.dart';
import '../core/model/enum.dart';
import '../core/model/network.dart';
import '../core/model/sport_profile.dart';
import '../core/model/timeslot.dart';
import '../core/model/user_details.dart';
import '../core/state/selected_sport_state.dart';
import '../core/zalo_link.dart';
import '../ui/main.dart';
import 'user_profile_detail_controller.dart';

/// Read-only counterpart to the Profile tab's own sections
/// (`lib/profile_tab/main.dart`) — general info, network/industry, and the
/// current context sport's profile, for whoever `/user/:id` is showing.
/// Nothing here is tappable: this is someone else's data, not a draft to edit.
class ProfileOverviewTab extends ConsumerWidget {
  final String userId;
  final UserDetails details;

  const ProfileOverviewTab({
    super.key,
    required this.userId,
    required this.details,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sportAsync = ref.watch(selectedSportStateProvider);
    final sport = sportAsync.maybeWhen(data: (s) => s, orElse: () => Sport.others);
    final detailAsync = ref.watch(userProfileDetailProvider(userId, sport));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(userProfileDetailProvider(userId, sport));
        await ref.read(userProfileDetailProvider(userId, sport).future);
      },
      child: ListView(
        // Extra bottom padding — this page has no bottom nav bar to absorb
        // the home-indicator safe area, so the last section clips without it.
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
        children: [
          // Rendered off the synchronously-available `details` right away, not
          // gated on `detailAsync` — `zalo` (async, RLS-gated) just merges in
          // as its own row once/if it resolves, same widget either way.
          _GeneralInfoSection(
            details: details,
            zalo: detailAsync.value?.contact.zalo,
          ),
          const SizedBox(height: 20),
          detailAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, st) =>
                PEmptySectionPlaceholder(subtitle: 'social.profileError'.tr()),
            data: (detail) => Column(
              children: [
                _NetworkIndustrySection(
                  networks: detail.networks,
                  industries: detail.industries,
                ),
                const SizedBox(height: 20),
                _SportProfileSection(sport: sport, profile: detail.sportProfile),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GeneralInfoSection extends StatelessWidget {
  final UserDetails details;
  final String? zalo;
  const _GeneralInfoSection({required this.details, this.zalo});

  bool get _isEmpty =>
      details.gender == null &&
      details.ageGroup == null &&
      !_isLocationSet(details) &&
      (details.playtime == null || details.playtime!.isEmpty) &&
      zalo == null;

  static bool _isLocationSet(UserDetails details) {
    final city = details.location?.city;
    return city != null && city != City.none;
  }

  /// Condensed "T2 Tối, T4 Sáng" style summary — short day + short chunk per
  /// slot, matching the shorthand `playtime_selection_screen.dart` itself
  /// uses for each row, joined instead of listed since this is one summary
  /// line rather than an editable list.
  static String? _playtimeSummary(BuildContext context, List<Timeslot>? playtime) {
    if (playtime == null || playtime.isEmpty) return null;
    return playtime
        .map((t) =>
            '${t.dayOfWeek.getShortName(context)} ${t.dayChunk.getShortName(context)}')
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    if (_isEmpty) {
      return FTileGroup(
        label: Text('profile.generalInfo'.tr()),
        children: [
          FTile(
            title: Text(
              'profile.noGeneralInfo'.tr(),
              style: TextStyle(color: context.theme.colors.mutedForeground),
            ),
          ),
        ],
      );
    }

    final genderIcon = switch (details.gender) {
      Gender.male => FLucideIcons.mars,
      Gender.female => FLucideIcons.venus,
      null => null,
    };

    return FTileGroup(
      label: Text('profile.generalInfo'.tr()),
      children: [
        FTile(
          suffix: genderIcon != null
              ? Icon(genderIcon, color: context.theme.colors.primary)
              : null,
          title: Text('profile.gender'.tr()),
          details: Text(
            details.gender?.getLocalizedName(context) ?? 'notSet'.tr(),
            style: TextStyle(
              color: details.gender != null
                  ? context.theme.colors.primary
                  : context.theme.colors.mutedForeground,
            ),
          ),
        ),
        FTile(
          title: Text('profile.ageGroup'.tr()),
          details: Text(
            details.ageGroup?.getLocalizedName(context) ?? 'notSet'.tr(),
            style: TextStyle(
              color: details.ageGroup != null
                  ? context.theme.colors.primary
                  : context.theme.colors.mutedForeground,
            ),
          ),
        ),
        FTile(
          title: Text('profile.location'.tr()),
          details: Text(
            _isLocationSet(details)
                ? details.location!.city!.getLocalizedName(context)
                : 'notSet'.tr(),
            style: TextStyle(
              color: _isLocationSet(details)
                  ? context.theme.colors.primary
                  : context.theme.colors.mutedForeground,
            ),
          ),
        ),
        FTile(
          title: Text('profile.playtime'.tr()),
          details: Text(
            _playtimeSummary(context, details.playtime) ?? 'notSet'.tr(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _playtimeSummary(context, details.playtime) != null
                  ? context.theme.colors.primary
                  : context.theme.colors.mutedForeground,
            ),
          ),
        ),
        // Only rendered once `user_contact`'s own RLS lets the viewer see this
        // contact — friends, anyone if the owner made it public, or a
        // freeplay host (see `schema/user_contact.sql` /
        // `schema/user_contact_zalo_public.sql`). Absent zalo isn't shown as
        // "not set" like the fields above — silence here just means "not
        // visible to me", not "unset".
        if (zalo != null)
          FTile(
            suffix: Icon(
              FLucideIcons.externalLink,
              color: context.theme.colors.primary,
            ),
            title: const SizedBox(
              width: 32,
              height: 32,
              child: PasseIcons.zaloLogo,
            ),
            details: Text(
              zalo!,
              style: TextStyle(color: context.theme.colors.primary),
            ),
            onPress: () => openZaloChat(context, zalo!),
          ),
      ],
    );
  }
}

class _NetworkIndustrySection extends StatelessWidget {
  final List<Network> networks;
  final List<Industry> industries;

  const _NetworkIndustrySection({
    required this.networks,
    required this.industries,
  });

  @override
  Widget build(BuildContext context) {
    if (networks.isEmpty && industries.isEmpty) return const SizedBox.shrink();

    final industryTitle = industries.isEmpty
        ? Text(
            'notSet'.tr(),
            style: TextStyle(color: context.theme.colors.mutedForeground),
          )
        : Text(
            industries.map((e) => e.getLocalizedName(context)).join(', '),
            maxLines: 2,
          );

    final networkTitle = networks.isEmpty
        ? Text(
            'notSet'.tr(),
            style: TextStyle(color: context.theme.colors.mutedForeground),
          )
        : Text(
            networks.map((e) => e.getLocalizedName(context)).join(', '),
            maxLines: 2,
          );

    return FTileGroup(
      label: Text('profile.industryAndNetworkLabel'.tr()),
      children: [
        FTile(
          prefix: const Icon(FLucideIcons.briefcaseBusiness),
          title: Text('profile.industryLabel'.tr()),
          details: industryTitle,
        ),
        FTile(
          prefix: const Icon(FLucideIcons.network),
          title: Text('profile.networkLabel'.tr()),
          details: networkTitle,
        ),
      ],
    );
  }
}

class _SportProfileSection extends StatelessWidget {
  final Sport sport;
  final Object? profile;

  const _SportProfileSection({required this.sport, required this.profile});

  @override
  Widget build(BuildContext context) {
    if (sport == Sport.others) return const SizedBox.shrink();

    final rows = _rows(context);
    if (rows.isEmpty) {
      return FTileGroup(
        label: Text('profile.sportProfile'.tr(args: [sport.getLocalizedName(context)])),
        children: [
          FTile(
            title: Text(
              'profile.noSportProfile'.tr(),
              style: TextStyle(color: context.theme.colors.mutedForeground),
            ),
          ),
        ],
      );
    }

    return FTileGroup(
      label: Text('profile.sportProfile'.tr(args: [sport.getLocalizedName(context)])),
      children: rows,
    );
  }

  List<FTile> _rows(BuildContext context) {
    final p = profile;
    if (p == null) return [];

    return switch (sport) {
      Sport.soccer => _ballSportRows(
          context,
          position: (p as SoccerProfile)
              .position
              ?.map((e) => e.getLocalizedName(context))
              .toList(),
          pitch: p.pitch?.map((e) => e.getLocalizedName(context)).toList(),
          eloSeed: p.eloSeed,
        ),
      Sport.basketball => _ballSportRows(
          context,
          position: (p as BasketballProfile)
              .position
              ?.map((e) => e.getLocalizedName(context))
              .toList(),
          pitch: p.pitch?.map((e) => e.getLocalizedName(context)).toList(),
          eloSeed: p.eloSeed,
        ),
      Sport.badminton => _racketSportRows(
          context,
          dominantHand: (p as BadmintonProfile).dominantHand,
          discipline: p.discipline?.map((e) => e.getLocalizedName(context)).toList(),
          eloSeed: p.eloSeed,
        ),
      Sport.tennis => _racketSportRows(
          context,
          dominantHand: (p as TennisProfile).dominantHand,
          discipline: p.discipline?.map((e) => e.getLocalizedName(context)).toList(),
          eloSeed: p.eloSeed,
        ),
      Sport.pickleball => _racketSportRows(
          context,
          dominantHand: (p as PickleballProfile).dominantHand,
          discipline: p.discipline?.map((e) => e.getLocalizedName(context)).toList(),
          eloSeed: p.eloSeed,
        ),
      Sport.others => [],
    };
  }

  List<FTile> _ballSportRows(
    BuildContext context, {
    required List<String>? position,
    required List<String>? pitch,
    required EloSeed? eloSeed,
  }) {
    final rows = <FTile>[];
    if (position != null && position.isNotEmpty) {
      rows.add(FTile(
        title: Text('soccer.position.label'.tr()),
        details: Text(position.join(', ')),
      ));
    }
    if (pitch != null && pitch.isNotEmpty) {
      rows.add(FTile(
        title: Text('soccer.pitch.label'.tr()),
        details: Text(pitch.join(', ')),
      ));
    }
    if (eloSeed != null) {
      rows.add(FTile(
        prefix: const Icon(FLucideIcons.lock),
        title: Text('eloSeed.label'.tr()),
        details: Text(eloSeed.getLocalizedName(context)),
      ));
    }
    return rows;
  }

  List<FTile> _racketSportRows(
    BuildContext context, {
    required DominantHand? dominantHand,
    required List<String>? discipline,
    required EloSeed? eloSeed,
  }) {
    final rows = <FTile>[];
    if (dominantHand != null) {
      rows.add(FTile(
        title: Text('racketSport.dominantHand.label'.tr()),
        details: Text(dominantHand.getLocalizedName(context)),
      ));
    }
    if (discipline != null && discipline.isNotEmpty) {
      rows.add(FTile(
        title: Text('racketSport.discipline.label'.tr()),
        details: Text(discipline.join(', ')),
      ));
    }
    if (eloSeed != null) {
      rows.add(FTile(
        prefix: const Icon(FLucideIcons.lock),
        title: Text('eloSeed.label'.tr()),
        details: Text(eloSeed.getLocalizedName(context)),
      ));
    }
    return rows;
  }
}
