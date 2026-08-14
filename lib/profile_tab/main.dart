import 'dart:io';

import 'package:avatar_plus/avatar_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../auth/auth_controller.dart';
import '../core/icon/main.dart';
import '../core/model/enum.dart';
import '../core/model/user_avatar.dart';
import '../core/model/user_contact.dart';
import '../core/model/user_details.dart';
import '../core/sport_selector.dart';
import '../core/state/host_mode_state.dart';
import '../core/state/pro_mode_state.dart';
import '../core/state/selected_sport_state.dart';
import '../freeplay/host_profile_controller.dart';
import '../freeplay/model.dart';
import '../freeplay/repository.dart';
import '../professional/controller.dart';
import '../professional/pro_mode/service_editor_main.dart';
import '../social/friends_screen.dart';
import '../social/friendship_controller.dart';
import '../ui/main.dart';
import 'age_group_selection_screen.dart';
import 'change_password_screen.dart';
import 'change_username_screen.dart';
import 'edit_zalo_sheet.dart';
import 'guest_profile_view.dart';
import 'industry_selection_screen.dart';
import 'location_selection_screen.dart';
import 'network_selection_screen.dart';
import 'payment_info_controller.dart';
import 'payment_info_selection_screen.dart';
import 'playtime_selection_screen.dart';
import 'profile_controller.dart';
import 'sport_profile/sport_profile_controller.dart';
import 'sport_profile/sport_profile_screen.dart';
import 'user_contact_controller.dart';

class _HostProfileView extends ConsumerStatefulWidget {
  final FreeplayHost host;
  const _HostProfileView({required this.host});

  @override
  ConsumerState<_HostProfileView> createState() => _HostProfileViewState();
}

class _HostProfileViewState extends ConsumerState<_HostProfileView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _displayNameController;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(
      text: widget.host.displayName,
    );
  }

  @override
  void didUpdateWidget(covariant _HostProfileView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.host.displayName != widget.host.displayName &&
        _displayNameController.text == oldWidget.host.displayName) {
      _displayNameController.text = widget.host.displayName;
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      await ref
          .read(hostProfileEditControllerProvider(widget.host.id).notifier)
          .commit(displayName: _displayNameController.text.trim());
    } catch (e, st) {
      Talker().handle(e, st, 'Host profile save failed');
      if (mounted) {
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.circleX),
          variant: .destructive,
          title: Text('freeplay.hostMode.saveFailed'.tr()),
          alignment: .bottomCenter,
        );
      }
      return;
    }

    if (!mounted) return;
    showFToast(
      context: context,
      icon: const Icon(FLucideIcons.check),
      title: Text('freeplay.hostMode.saved'.tr()),
      alignment: .bottomCenter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(hostProfileEditControllerProvider(widget.host.id));
    final displayNameAsync = ref.watch(
      myHostDisplayNameProvider(widget.host.id),
    );
    // Same `user_contact` row user mode edits — host mode fully replaces the
    // player profile screen, so without this the Zalo tile is unreachable
    // while host mode is on, even though the freeplay chat sheet already
    // reads this exact field for players contacting the host.
    final myContact =
        ref.watch(userContactControllerProvider).value ?? const UserContact();
    ref.listen(myHostDisplayNameProvider(widget.host.id), (previous, next) {
      final latestName = next.value;
      final previousName = previous?.value ?? widget.host.displayName;
      if (latestName != null && _displayNameController.text == previousName) {
        _displayNameController.text = latestName;
      }
    });
    final displayName = displayNameAsync.value ?? widget.host.displayName;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FButton(
            variant: .outline,
            onPress: () => ref.read(hostModeStateProvider.notifier).set(false),
            child: Text('freeplay.hostMode.backToPlayer'.tr()),
          ),
        ),
        const SizedBox(height: 24),
        CircleAvatar(
          radius: 58,
          backgroundImage: widget.host.avatarUrl == null
              ? null
              : NetworkImage(widget.host.avatarUrl!),
          child: widget.host.avatarUrl == null
              ? const Icon(FLucideIcons.ticket, size: 42)
              : null,
        ),
        const SizedBox(height: 16),
        Text(
          displayName,
          textAlign: TextAlign.center,
          style: context.theme.typography.body.xl2.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text('freeplay.verifiedHost'.tr(), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        if (widget.host.bio.isNotEmpty)
          Text(widget.host.bio, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              FTextFormField(
                label: Text('freeplay.hostMode.displayName'.tr()),
                hint: 'freeplay.hostMode.displayNameHint'.tr(),
                description: Text(
                  'freeplay.hostMode.displayNameDescription'.tr(),
                ),
                maxLength: 80,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                control: FTextFieldControl.managed(
                  controller: _displayNameController,
                ),
                validator: (value) {
                  final name = value?.trim() ?? '';
                  if (name.isEmpty) {
                    return 'freeplay.hostMode.displayNameRequired'.tr();
                  }
                  if (name.length > 80) {
                    return 'freeplay.hostMode.displayNameTooLong'.tr();
                  }
                  return null;
                },
              ),
              FButton(
                onPress: saving ? null : _save,
                child: Text(
                  saving
                      ? 'freeplay.hostMode.saving'.tr()
                      : 'freeplay.hostMode.save'.tr(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FTileGroup(
          children: [
            FTile(
              suffix: myContact.zaloPublic
                  ? Icon(FLucideIcons.globe, color: context.theme.colors.primary)
                  : null,
              title: const SizedBox(
                width: 32,
                height: 32,
                child: PasseIcons.zaloLogo,
              ),
              details: Text(
                myContact.zalo ?? 'notSet'.tr(),
                style: TextStyle(
                  color: myContact.zalo != null
                      ? context.theme.colors.primary
                      : context.theme.colors.mutedForeground,
                ),
              ),
              onPress: () => showEditZaloSheet(context, myContact),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'freeplay.hostMode.manageHint'.tr(),
          textAlign: TextAlign.center,
          style: context.theme.typography.body.sm.copyWith(
            color: context.theme.colors.mutedForeground,
          ),
        ),
      ],
    );
  }
}

class ProfileTab extends ConsumerWidget {
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

          final linkedProfessionalId = ref
              .watch(linkedProfessionalIdProvider)
              .asData
              ?.value;
          final proModeActive =
              ref.watch(proModeStateProvider).asData?.value ?? false;
          final linkedHost = ref
              .watch(linkedFreeplayHostProvider)
              .asData
              ?.value;
          final hostModeActive =
              ref.watch(hostModeStateProvider).asData?.value ?? false;

          if (linkedProfessionalId != null && proModeActive) {
            return ProProfileView(professionalId: linkedProfessionalId);
          }

          if (linkedHost != null && hostModeActive) {
            return _HostProfileView(host: linkedHost);
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(authControllerProvider);
              await ref.read(authControllerProvider.future);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              // padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (linkedProfessionalId != null || linkedHost != null) ...[
                    FTileGroup(
                      children: [
                        if (linkedHost != null)
                          FTile(
                            prefix: const Icon(FLucideIcons.ticket),
                            title: Text('freeplay.hostMode.title'.tr()),
                            details: FSwitch(
                              value: hostModeActive,
                              onChange: (v) {
                                ref.read(hostModeStateProvider.notifier).set(v);
                                if (v) {
                                  ref
                                      .read(proModeStateProvider.notifier)
                                      .set(false);
                                }
                              },
                            ),
                          ),
                        if (linkedProfessionalId != null)
                          FTile(
                            prefix: const Icon(FLucideIcons.briefcaseBusiness),
                            title: Text('homeTab.professional.mode.title'.tr()),
                            details: FSwitch(
                              value: proModeActive,
                              onChange: (v) {
                                ref.read(proModeStateProvider.notifier).set(v);
                                if (v) {
                                  ref
                                      .read(hostModeStateProvider.notifier)
                                      .set(false);
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Section 1: Avatar + Account Info
                  _buildAvatar(context, ref, profileState),
                  const SizedBox(height: 16),
                  _buildAccountSection(context, ref, profileState, user),
                  const SizedBox(height: 24),

                  // Section 2: General Info
                  _buildGeneralInfoSection(context, ref, profileState.details),
                  const SizedBox(height: 24),

                  // Section 2b: Payment Info
                  _buildPaymentInfoSection(context, ref),
                  const SizedBox(height: 24),

                  // Section 3: Network & Industry Info
                  _buildNetworkIndustrySection(context, ref, profileState),
                  const SizedBox(height: 24),

                  // Section 3b: Friends
                  _buildSocialSection(context, ref),
                  const SizedBox(height: 24),

                  // Section 4: Sport-Specific Info
                  _buildSportInfoSection(context, ref),
                  const SizedBox(height: 24),

                  // Commit Button
                  FButton(
                    onPress: () async {
                      try {
                        final sport = ref
                            .read(selectedSportStateProvider)
                            .asData
                            ?.value;
                        await Future.wait([
                          ref.read(profileControllerProvider.notifier).commit(),
                          if (sport != null && sport != Sport.others)
                            commitSportProfile(ref, sport),
                        ]);
                      } on AvatarUploadFailedException {
                        if (!context.mounted) return;
                        showFToast(
                          context: context,
                          icon: const Icon(FLucideIcons.circleX),
                          variant: .destructive,
                          title: Text('profile.uploadFailed'.tr()),
                          alignment: .bottomCenter,
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        showFToast(
                          context: context,
                          icon: const Icon(FLucideIcons.circleX),
                          variant: .destructive,
                          title: Text('error'.tr()),
                          description: Text('errorGeneric'.tr()),
                          alignment: .bottomCenter,
                        );
                      }
                    },
                    child: Text('profile.commit'.tr()),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  /// Picks a gallery photo, then hands it to the native circular crop/pan
  /// screen (uCrop on Android, TOCropViewController on iOS) before storing
  /// it as the draft pick. Cropping needs a `BuildContext` for toolbar
  /// theming, so it lives here rather than in `ProfileController`.
  Future<void> _pickAndCropAvatar(BuildContext context, WidgetRef ref) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (picked == null) return;

      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        maxWidth: 512,
        maxHeight: 512,
        compressQuality: 85,
        compressFormat: ImageCompressFormat.jpg,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'profile.cropAvatar'.tr(),
            toolbarColor: pbBlue,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: pbBlue,
            cropStyle: CropStyle.circle,
            lockAspectRatio: true,
            hideBottomControls: true,
          ),
          IOSUiSettings(
            title: 'profile.cropAvatar'.tr(),
            cropStyle: CropStyle.circle,
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
          ),
        ],
      );
      if (cropped == null) return;

      ref
          .read(profileControllerProvider.notifier)
          .setPickedAvatar(XFile(cropped.path));
    } catch (e) {
      if (!context.mounted) return;
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleX),
        variant: .destructive,
        title: Text('profile.uploadFailed'.tr()),
        alignment: .bottomCenter,
      );
    }
  }

  Widget _buildAvatar(
    BuildContext context,
    WidgetRef ref,
    ProfileState profileState,
  ) {
    final avatar = profileState.details.avatar;
    final pickedAvatar = profileState.pickedAvatar;

    ImageProvider? imageProvider;
    if (pickedAvatar != null) {
      imageProvider = FileImage(File(pickedAvatar.path));
    } else if (avatar is PhotoAvatar) {
      final userId = ref.read(authControllerProvider).value?.id;
      if (userId != null) {
        final avatarUrl = Supabase.instance.client.storage
            .from('user_avatar')
            .getPublicUrl('$userId.jpg');
        // Add cache busting
        final cacheBusted =
            '$avatarUrl?t=${DateTime.now().millisecondsSinceEpoch}';
        imageProvider = NetworkImage(cacheBusted);
      }
    }

    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: context.theme.colors.primary,
            backgroundImage: imageProvider,
            child: imageProvider != null
                ? null
                : AvatarPlus(
                    avatar is GeneratedAvatar
                        ? avatar.seed
                        : profileState.username,
                  ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (imageProvider != null)
                FButton.icon(
                  onPress: () => ref
                      .read(profileControllerProvider.notifier)
                      .removeAvatar(),
                  variant: .ghost,
                  child: const Icon(FLucideIcons.trash),
                )
              else
                FButton.icon(
                  onPress: () => ref
                      .read(profileControllerProvider.notifier)
                      .randomizeAvatar(),
                  variant: .ghost,
                  child: const Icon(FLucideIcons.shuffle),
                ),
              const SizedBox(width: 12),
              FButton.icon(
                onPress: () => _pickAndCropAvatar(context, ref),
                variant: .ghost,
                child: const Icon(FLucideIcons.camera),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(
    BuildContext context,
    WidgetRef ref,
    ProfileState profileState,
    user,
  ) {
    return FTileGroup(
      label: Text('profile.accountInfo'.tr()),
      children: [
        FTile(
          onPress: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ChangeUsernameScreen(),
            ),
          ),
          title: Text('profile.username'.tr()),
          details: Text('${profileState.username}#${user.tagNumber}'),
        ),
        if (user.email != null)
          FTile(title: Text('profile.email'.tr()), details: Text(user.email!)),
        FTile(
          onPress: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ChangePasswordScreen(),
            ),
          ),
          title: Text('profile.changePassword'.tr()),
          details: Icon(Icons.password, color: context.theme.colors.primary),
        ),
        FTile(
          style: .delta(
            backgroundColor: .delta([.all(context.theme.colors.destructive)]),
          ),
          onPress: () {
            showFToast(
              context: context,
              icon: const Icon(FLucideIcons.logOut),
              title: Text('profile.confirmLogout'.tr()),
              duration: const Duration(milliseconds: 1500),
              alignment: .bottomCenter,
            );
          },
          onLongPress: () =>
              ref.read(authControllerProvider.notifier).signOut(),
          title: Text(
            'profile.logout'.tr(),
            style: TextStyle(color: context.theme.colors.destructive),
          ),
          details: Icon(
            FLucideIcons.logOut,
            color: context.theme.colors.destructive,
          ),
        ),
      ],
    );
  }

  /// Friends hub entry. The badge counts requests waiting on the user — the
  /// only place in the app that lets you *act* on them (accept/decline). The
  /// notification centre (`/notifications`) also lists `friend_request`
  /// events as passive history, but doesn't replace this actionable queue.
  Widget _buildSocialSection(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(incomingFriendRequestsProvider).length;

    return FTileGroup(
      children: [
        FTile(
          prefix: const Icon(FLucideIcons.users),
          title: Text('social.friends'.tr()),
          details: pending > 0
              ? FBadge(child: Text('$pending'))
              : Text(
                  '${ref.watch(friendsProvider).length}',
                  style: TextStyle(color: context.theme.colors.primary),
                ),
          suffix: const Icon(FLucideIcons.chevronRight),
          onPress: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const FriendsScreen()),
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
      if (details.gender == Gender.male) return FLucideIcons.mars;
      return FLucideIcons.venus;
    }();
    final myContact =
        ref.watch(userContactControllerProvider).value ?? const UserContact();

    return FTileGroup(
      label: Text('profile.generalInfo'.tr()),
      description: Text('profile.profileFeatureExplanation'.tr()),
      children: [
        FTile(
          suffix: details.gender != null
              ? Icon(genderSuffix, color: context.theme.colors.primary)
              : null,

          title: Text('profile.gender'.tr()),
          details: Text(
            details.gender?.getLocalizedName(context) ?? 'notSet'.tr(),
            style: TextStyle(
              color: (details.gender != null)
                  ? context.theme.colors.primary
                  : context.theme.colors.mutedForeground,
            ),
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
            details.ageGroup?.getLocalizedName(context) ?? 'notSet'.tr(),
            style: TextStyle(
              color: (details.ageGroup != null)
                  ? context.theme.colors.primary
                  : context.theme.colors.mutedForeground,
            ),
          ),
          onPress: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AgeGroupSelectionScreen(),
            ),
          ),
        ),
        FTile(
          title: Text('profile.location'.tr()),
          details: _isLocationSet(details)
              ? const Icon(FLucideIcons.chevronRight)
              : Text(
                  'notSet'.tr(),
                  style: TextStyle(color: context.theme.colors.mutedForeground),
                ),
          onPress: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const LocationSelectionScreen(),
            ),
          ),
        ),
        FTile(
          title: Text('profile.playtime'.tr()),
          details: (details.playtime != null && details.playtime!.isNotEmpty)
              ? const Icon(FLucideIcons.chevronRight)
              : Text(
                  'notSet'.tr(),
                  style: TextStyle(color: context.theme.colors.mutedForeground),
                ),
          onPress: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const PlaytimeSelectionScreen(),
            ),
          ),
        ),
        FTile(
          suffix: myContact.zaloPublic
              ? Icon(FLucideIcons.globe, color: context.theme.colors.primary)
              : null,
          title: const SizedBox(
            width: 32,
            height: 32,
            child: PasseIcons.zaloLogo,
          ),
          details: Text(
            myContact.zalo ?? 'notSet'.tr(),
            style: TextStyle(
              color: myContact.zalo != null
                  ? context.theme.colors.primary
                  : context.theme.colors.mutedForeground,
            ),
          ),
          onPress: () => showEditZaloSheet(context, myContact),
        ),
      ],
    );
  }

  Widget _buildPaymentInfoSection(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(paymentInfoControllerProvider);
    final count = entriesAsync.asData?.value.length ?? 0;

    return FTileGroup(
      children: [
        FTile(
          prefix: const Icon(FLucideIcons.landmark),
          title: Text('profile.paymentInfo'.tr()),
          details: count > 0
              ? Text(
                  '$count',
                  style: TextStyle(color: context.theme.colors.primary),
                )
              : Text(
                  'notSet'.tr(),
                  style: TextStyle(color: context.theme.colors.mutedForeground),
                ),
          suffix: const Icon(FLucideIcons.chevronRight),
          onPress: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const PaymentInfoSelectionScreen(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkIndustrySection(
    BuildContext context,
    WidgetRef ref,
    ProfileState profileState,
  ) {
    final industryRowTitle = profileState.industries.isEmpty
        ? Text('profile.industryLabel'.tr())
        : Text(
            profileState.industries
                .map((e) => e.getLocalizedName(context))
                .join(', '),
            maxLines: 2,
          );

    final networkRowTitle = profileState.networks.isEmpty
        ? Text('profile.networkLabel'.tr())
        : Text(
            profileState.networks
                .map((e) => e.getLocalizedName(context))
                .join(', '),
            maxLines: 2,
          );
    return Column(
      children: [
        FTileGroup(
          label: Text('profile.industryAndNetworkLabel'.tr()),
          children: [
            FTile(
              prefix: Icon(FLucideIcons.briefcaseBusiness),
              title: industryRowTitle,
              suffix: profileState.industries.isEmpty
                  ? Text(
                      'notSet'.tr(),
                      style: TextStyle(
                        color: context.theme.colors.mutedForeground,
                      ),
                    )
                  : null,
              onPress: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const IndustrySelectionScreen(),
                ),
              ),
            ),
            FTile(
              prefix: Icon(FLucideIcons.network),
              title: networkRowTitle,
              suffix: profileState.networks.isEmpty
                  ? Text(
                      'notSet'.tr(),
                      style: TextStyle(
                        color: context.theme.colors.mutedForeground,
                      ),
                    )
                  : null,
              onPress: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NetworkSelectionScreen(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSportInfoSection(BuildContext context, WidgetRef ref) {
    final sportAsync = ref.watch(selectedSportStateProvider);
    final sport = sportAsync.maybeWhen(
      data: (s) => s,
      orElse: () => Sport.others,
    );
    final sportName = sport.getLocalizedName(context);

    return FTileGroup(
      children: [
        FTile(
          prefix: sport.getIcon(size: 8),
          title: Text('profile.sportProfile'.tr(args: [sportName])),
          suffix: const Icon(FLucideIcons.chevronRight),
          onPress: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const SportProfileScreen()),
          ),
        ),
      ],
    );
  }

  bool _isLocationSet(UserDetails details) {
    final city = details.location?.city;
    return city != null && city != City.none;
  }
}
