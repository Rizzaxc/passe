import 'package:avatar_plus/avatar_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/auth_controller.dart';
import '../core/model/enum.dart';
import '../core/model/user_details.dart';
import '../core/model/user_location.dart';
import '../core/sport_selector.dart';
import '../core/state/selected_sport_state.dart';
import '../notification/notification_icon_button.dart';
import '../ui/main.dart';
import 'age_group_selection_screen.dart';
import 'guest_profile_view.dart';
import 'industry_selection_screen.dart';
import 'network_selection_screen.dart';
import 'profile_controller.dart';
import 'network_empty_placeholder.dart';
import 'industry_empty_placeholder.dart';
import 'sport_profile/badminton.dart';
import 'sport_profile/basketball.dart';
import 'sport_profile/pickleball.dart';
import 'sport_profile/soccer.dart';
import 'sport_profile/tennis.dart';

class ProfileTab extends HookConsumerWidget {
  const ProfileTab({super.key});

  static final instance = ProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authControllerProvider);
    final profileState = ref.watch(profileControllerProvider);

    return FScaffold(
      header: FHeader(
        title: Text('nav.profile'.tr()),
        suffixes: [const NotificationIconButton(), const SportSelector()],
      ),
      child: userAsync.when(
        data: (user) {
          if (user == null || user.isGuest) {
            return const GuestProfileView();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Section 1: Avatar + Account Info
                _buildAvatar(context, profileState),
                const SizedBox(height: 16),
                _buildAccountSection(context, ref, profileState, user),
                const SizedBox(height: 24),

                // Section 2: General Info
                _buildGeneralInfoSection(context, ref, profileState.details),
                const SizedBox(height: 24),

                // Section 3: Network & Industry Info
                _buildNetworkIndustrySection(context, ref, profileState),
                const SizedBox(height: 24),

                // Section 4: Sport-Specific Info
                _buildSportInfoSection(context, ref, profileState.details),
                const SizedBox(height: 24),

                // Commit Button
                FButton(
                  onPress: () async {
                    try {
                      await ref
                          .read(profileControllerProvider.notifier)
                          .commit();
                    } catch (e) {
                      if (!context.mounted) return;
                      showFToast(
                        context: context,
                        title: Text('error'.tr()),
                        description: Text('error_generic'.tr()),
                        alignment: .bottomCenter,
                      );
                    }
                  },
                  style: FButtonStyle.primary(),
                  child: Text('profile.commit'.tr()),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, ProfileState profileState) {
    return Center(
      child: CircleAvatar(
        radius: 60,
        backgroundColor: context.theme.colors.primary,
        // TODO: allow user to upload their own picture
        child: AvatarPlus(profileState.username),
      ),
    );
  }

  Widget _buildAccountSection(
    BuildContext context,
    WidgetRef ref,
    ProfileState profileState,
    user,
  ) {
    final isEditingUsername = useState(false);
    final controller = useTextEditingController(text: profileState.username);

    return FTileGroup(
      label: Text('profile.accountInfo'.tr()),
      description: Text('profile.profile_feature_explanation'.tr()),
      children: [
        if (isEditingUsername.value)
          FTile.raw(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: FTextField(
                label: Text('profile.username'.tr()),
                control: FTextFieldControl.managed(
                  controller: controller,
                  onChange: (value) {
                    ref
                        .read(profileControllerProvider.notifier)
                        .updateDraft(username: value.text);
                  },
                ),
                suffixBuilder: (context, style, states) => FButton.icon(
                  onPress: () => isEditingUsername.value = false,
                  child: const Icon(FIcons.check),
                ),
              ),
            ),
          )
        else
          FTile(
            onPress: () => isEditingUsername.value = true,
            title: Text('profile.username'.tr()),
            details: Text('${profileState.username}#${user.tagNumber}'),
          ),
        if (user.email != null)
          FTile(title: Text('profile.email'.tr()), details: Text(user.email!)),
        FTile(
          onPress: () {
            // TODO: Implement change password logic
          },
          title: Text('profile.changePassword'.tr()),
          details: const Icon(Icons.password),
        ),
        FTile(
          style: (style) => style.copyWith(
            decoration: FWidgetStateMap<BoxDecoration>({
              WidgetState.any: BoxDecoration(
                color: context.theme.colors.destructive,
              ),
            }),
          ),
          onPress: () {
            showFToast(
              context: context,
              title: Text('profile.confirmLogout'.tr()),
              duration: const Duration(milliseconds: 1500),
              alignment: .bottomCenter,
            );
          },
          onLongPress: () =>
              ref.read(authControllerProvider.notifier).signOut(),
          title: Text(
            'profile.logout'.tr(),
            style: TextStyle(color: context.theme.colors.destructiveForeground),
          ),
          details: Icon(
            FIcons.logOut,
            color: context.theme.colors.destructiveForeground,
          ),
        ),
      ],
    );
  }

  Widget _buildGeneralInfoSection(
    BuildContext context,
    WidgetRef ref,
    UserDetails details,
  ) {
    final genderSuffix = () {
      if (details.gender == null) return null;
      if (details.gender == Gender.male) return const Icon(FIcons.mars);
      return const Icon(FIcons.venus);
    }();

    return FTileGroup(
      label: Text('profile.generalInfo'.tr()),
      description: Text('profile.profile_feature_explanation'.tr()),
      children: [
        FTile(
          suffix: genderSuffix,
          title: Text('profile.gender'.tr()),
          details: Text(
            details.gender?.getLocalizedName(context) ?? 'not_set'.tr(),
          ),
          onPress: () {
            final currentGender = details.gender;
            final nextGender = currentGender == Gender.male
                ? Gender.female
                : Gender.male;
            final updatedDetails = details.copyWith(gender: nextGender);
            ref
                .read(profileControllerProvider.notifier)
                .updateDraft(details: updatedDetails);
          },
        ),
        FTile(
          title: Text('profile.ageGroup'.tr()),
          details: Text(
            details.ageGroup?.getLocalizedName(context) ?? 'not_set'.tr(),
          ),
          onPress: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AgeGroupSelectionScreen(),
            ),
          ),
        ),
        FTile(
          title: Text('profile.location'.tr()),
          details: Text(
            details.location != null
                ? _formatLocation(details.location!)
                : 'not_set'.tr(),
          ),
          onPress: () {},
        ),
        FTile(
          title: Text('profile.playtime'.tr()),
          details: Text(
            (details.playtime != null && details.playtime!.isNotEmpty)
                ? '${details.playtime!.length} timeslots'
                : 'not_set'.tr(),
          ),
          onPress: () {},
        ),
      ],
    );
  }

  Widget _buildNetworkIndustrySection(
    BuildContext context,
    WidgetRef ref,
    ProfileState profileState,
  ) {
    return Column(
      children: [
        (profileState.networks.isEmpty)
            ? NetworkEmptyPlaceholder()
            : FTileGroup(
                label: Text('profile.networkLabel'.tr()),
                description: Text('profile.network_feature_explanation'.tr()),
                children: [
                  FTile(
                    title: Text('profile.networkLabel'.tr()),
                    details: Text(
                      profileState.networks.map((e) => e.name).join(', '),
                    ),
                    onPress: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const NetworkSelectionScreen(),
                      ),
                    ),
                  ),
                ],
              ),
        const SizedBox(height: 24),
        FTileGroup(
          label: Text('profile.industryLabel'.tr()),
          description: Text('profile.industry_feature_explanation'.tr()),
          children: [
            if (profileState.industries.isEmpty)
              FTile.raw(child: IndustryEmptyPlaceholder())
            else
              FTile.raw(
                child: Text(
                  profileState.industries
                      .map((e) => e.getLocalizedName(context))
                      .join(', '),
                ),
                onPress: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const IndustrySelectionScreen(),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSportInfoSection(
    BuildContext context,
    WidgetRef ref,
    UserDetails details,
  ) {
    final selectedSportAsync = ref.watch(selectedSportStateProvider);

    return selectedSportAsync.when(
      data: (sport) {
        return switch (sport) {
          Sport.soccer => SoccerProfile(details: details),
          Sport.basketball => BasketballProfile(details: details),
          Sport.badminton => BadmintonProfile(details: details),
          Sport.tennis => TennisProfile(details: details),
          Sport.pickleball => PickleballProfile(details: details),
          Sport.others => const SizedBox.shrink(),
        };
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  String _formatLocation(UserLocation location) {
    if (location.city == null) return 'N/A';

    try {
      final city = location.city!;
      final districts = location.districts;

      if (districts.isNotEmpty) {
        return '${city.name} - ${districts.join(", ")}';
      }

      return city.name;
    } catch (e) {
      return 'N/A';
    }
  }
}
