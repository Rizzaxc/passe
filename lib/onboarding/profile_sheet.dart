import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../core/model/enum.dart';
import '../core/model/user_details.dart';
import '../core/state/selected_sport_state.dart';
import '../core/timeslot_picker.dart';
import '../profile_tab/profile_controller.dart';
import '../profile_tab/sport_profile/elo_seed_field.dart';
import '../profile_tab/sport_profile/sport_profile_controller.dart';
import '../ui/dual_button.dart';
import '../ui/sheet.dart';
import 'onboarding_controller.dart';

/// Shows the condensed profile step as a sheet over the real shell.
/// Signed-in only — guests can't persist profile edits (`GuestProfileView`
/// is read-only elsewhere in the app too) and there's little for them to do
/// with a non-interactive preview, so `follow_up.dart` never calls this for
/// a guest session; `profileDone` simply stays unset for guests and the
/// real, editable sheet shows once they actually sign up.
Future<void> showProfileSheet(BuildContext context, WidgetRef ref) async {
  await showPSheet(context: context, builder: (_) => const ProfileStep());
  if (!context.mounted) return;
  await ref.read(onboardingStateProvider.notifier).completeProfile();
}

/// Condensed, skippable profile fields — just the highest-signal
/// matchmaking inputs (gender, age group, playtime, sport skill), reusing
/// [ProfileController] and the sport-specific controllers rather than a
/// full wizard through every profile field.
class ProfileStep extends ConsumerWidget {
  const ProfileStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final profileState = ref.watch(profileControllerProvider);
    final details = profileState.details;
    final sport =
        ref.watch(selectedSportStateProvider).asData?.value ?? Sport.others;
    final eloSeed = sport == Sport.others
        ? (seed: null, locked: false)
        : readSportEloSeed(ref, sport);

    final genderIcon = details.gender == null
        ? null
        : (details.gender == Gender.male ? FLucideIcons.mars : FLucideIcons.venus);

    Future<void> save() async {
      try {
        await Future.wait([
          ref.read(profileControllerProvider.notifier).commit(),
          // Only write the sport profile if the user actually chose a skill
          // level — elo_seed locks permanently once committed, so an empty
          // pick should never trip that lock.
          if (eloSeed.seed != null && sport != Sport.others)
            commitSportProfile(ref, sport),
        ]);
      } catch (e) {
        if (context.mounted) {
          showFToast(
            context: context,
            icon: const Icon(FLucideIcons.circleX),
            variant: .destructive,
            title: Text('onboarding.profile.saveError'.tr()),
            alignment: .bottomCenter,
          );
        }
      }
      // A failed write must never trap someone on this sheet.
      if (context.mounted) Navigator.of(context).pop();
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PSheetTitle(label: 'onboarding.profile.title'.tr()),
          const SizedBox(height: 4),
          Text(
            'onboarding.profile.body'.tr(),
            style: context.theme.typography.body.sm
                .copyWith(color: colors.mutedForeground),
          ),
          const SizedBox(height: 20),
          FTileGroup(
            children: [
              FTile(
                suffix: genderIcon != null
                    ? Icon(genderIcon, color: colors.primary)
                    : null,
                title: Text('onboarding.profile.gender'.tr()),
                details: Text(
                  details.gender?.getLocalizedName(context) ?? 'notSet'.tr(),
                  style: TextStyle(
                    color: details.gender != null
                        ? colors.primary
                        : colors.mutedForeground,
                  ),
                ),
                onPress: () {
                  final next =
                      details.gender == Gender.male ? Gender.female : Gender.male;
                  ref
                      .read(profileControllerProvider.notifier)
                      .updateDraft(details: details.copyWith(gender: next));
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          FSelectTileGroup<AgeGroup>(
            label: Text('onboarding.profile.ageGroup'.tr()),
            control: FMultiValueControl.managedRadio(
              initial: details.ageGroup,
              onChange: (selected) => ref
                  .read(profileControllerProvider.notifier)
                  .updateDraft(
                    details: details.copyWith(ageGroup: selected.firstOrNull),
                  ),
            ),
            children: <FSelectTile<AgeGroup>>[
              FSelectTile.suffix(
                prefix: const FaIcon(FontAwesomeIcons.graduationCap),
                title: Text(AgeGroup.student.getLocalizedName(context)),
                value: AgeGroup.student,
              ),
              FSelectTile.suffix(
                prefix: const FaIcon(FontAwesomeIcons.briefcase),
                title: Text(AgeGroup.mature.getLocalizedName(context)),
                value: AgeGroup.mature,
              ),
              FSelectTile.suffix(
                prefix: const FaIcon(FontAwesomeIcons.wineGlass),
                title: Text(AgeGroup.middleAge.getLocalizedName(context)),
                value: AgeGroup.middleAge,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _PlaytimeField(details: details),
          if (sport != Sport.others) ...[
            const SizedBox(height: 12),
            EloSeedField(
              value: eloSeed.seed,
              locked: eloSeed.locked,
              onChanged: (seed) {
                if (seed != null) setSportEloSeed(ref, sport, seed);
              },
            ),
            const SizedBox(height: 6),
            Text(
              'onboarding.profile.skillLockWarning'.tr(),
              style: context.theme.typography.body.sm
                  .copyWith(color: colors.mutedForeground),
            ),
          ],
          const SizedBox(height: 24),
          PDualButton(
            firstVariant: .outline,
            onFirstPressed: () => Navigator.of(context).pop(),
            onSecondPressed: save,
            firstChild: Text('onboarding.skip'.tr()),
            secondChild: Text('onboarding.profile.save'.tr()),
          ),
        ],
      ),
    );
  }
}

class _PlaytimeField extends ConsumerWidget {
  final UserDetails details;

  const _PlaytimeField({required this.details});

  static const _maxSlots = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeslots = details.playtime ?? [];

    return FTileGroup(
      label: Text('onboarding.profile.playtime'.tr()),
      children: [
        for (final timeslot in timeslots)
          FTile(
            title: Text(
              '${timeslot.dayChunk.getShortName(context)} ${timeslot.dayOfWeek.getFullName(context)}',
            ),
            suffix: FButton.icon(
              variant: .ghost,
              onPress: () {
                final updated = [...timeslots]..remove(timeslot);
                ref
                    .read(profileControllerProvider.notifier)
                    .updateDraft(details: details.copyWith(playtime: updated));
              },
              child: Icon(
                FLucideIcons.trash,
                color: context.theme.colors.destructive,
              ),
            ),
          ),
        if (timeslots.length < _maxSlots)
          FTile(
            prefix: const Icon(FLucideIcons.plus),
            title: Text('onboarding.profile.addPlaytime'.tr()),
            onPress: () async {
              final timeslot = await showTimeslotPicker(context: context);
              if (timeslot != null && !timeslots.contains(timeslot)) {
                final updated = [...timeslots, timeslot];
                ref
                    .read(profileControllerProvider.notifier)
                    .updateDraft(details: details.copyWith(playtime: updated));
              }
            },
          ),
      ],
    );
  }
}
