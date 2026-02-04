import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../auth/auth_controller.dart';
import '../core/model/enum.dart';
import '../core/model/network.dart';
import '../core/model/user_details.dart';
import '../main.dart';

part 'profile_controller.freezed.dart';
part 'profile_controller.g.dart';

@freezed
abstract class ProfileState with _$ProfileState {
  const factory ProfileState({
    required String username,
    required UserDetails details,
    @Default([]) List<Network> networks,
    @Default([]) List<Industry> industries,
    XFile? pickedAvatar,
  }) = _ProfileState;

  const ProfileState._();
}

@riverpod
class NetworkController extends _$NetworkController {
  final supabase = Supabase.instance.client;

  @override
  List<Network> build() {
    final user = ref.watch(authControllerProvider).value;
    if (user == null || user.id == null) return [];

    // Fetch initial data
    _fetchNetworks(user.id!);

    return [];
  }

  Future<void> _fetchNetworks(String userId) async {
    try {
      final response = await supabase
          .from('user_network')
          .select('alumni, network(id, name, category, city)')
          .eq('user_id', userId);

      final networks = (response as List).map((data) {
        final networkData = data['network'] as Map<String, dynamic>;
        return Network(
          id: networkData['id'] as int,
          name: networkData['name'] as String,
          isAlumni: data['alumni'] as bool,
          category: NetworkCategory.fromString(networkData['category'] as String?),
          city: networkData['city'] != null
              ? City.values.firstWhere(
                  (c) => c.name.toLowerCase() == (networkData['city'] as String).toLowerCase(),
                  orElse: () => City.hanoi,
                )
              : null,
        );
      }).toList();

      state = networks;
    } catch (e, st) {
      Talker().handle(e, st, 'Error fetching user networks');
    }
  }

  void toggle(Network network) {
    final current = state.toSet();
    if (current.contains(network)) {
      current.remove(network);
    } else if (current.length < 2) {
      current.add(network);
    } else {
      current.remove(current.first);
      current.add(network);
    }
    state = current.toList();
  }

  void toggleAlumni(int networkId) {
    state = [
      for (final network in state)
        if (network.id == networkId)
          network.copyWith(isAlumni: !network.isAlumni)
        else
          network,
    ];
  }

  void updateAll(List<Network> networks) {
    state = networks;
  }

  void reset() {
    ref.invalidateSelf();
  }

  Future<void> commit() async {
    if (supabase.auth.currentUser == null) return;
    final userId = supabase.auth.currentUser!.id;

    try {
      await supabase.from('user_network').delete().eq('user_id', userId);
      if (state.isNotEmpty) {
        await supabase.from('user_network').insert(
              state
                  .map((network) => {
                        'user_id': userId,
                        'network_id': network.id,
                        'alumni': network.isAlumni,
                      })
                  .toList(),
            );
      }
    } catch (e, st) {
      Talker().handle(e, st, 'Error committing user networks');
      rethrow;
    }
  }
}

@riverpod
class IndustryController extends _$IndustryController {
  final supabase = Supabase.instance.client;

  @override
  List<Industry> build() {
    final user = ref.watch(authControllerProvider).value;
    if (user == null || user.id == null) return [];

    // Fetch initial data
    final fetch = _fetchIndustries(user.id!);
    return [];
  }



  Future<void> _fetchIndustries(String userId) async {

    try {
      final response = await supabase
          .from('user_industry')
          .select('industry_id')
          .eq('user_id', userId);

      final industries = (response as List).map((data) {
        final industryId = data['industry_id'] as int;
        return Industry.values[industryId];
      }).toList();

      state = industries;
    } catch (e, st) {
      Talker().handle(e, st, 'Error fetching user industries');
    }
  }

  void toggle(Industry industry) {
    final current = state.toSet();
    if (current.contains(industry)) {
      current.remove(industry);
    } else if (current.length < 2) {
      current.add(industry);
    } else {
      current.remove(current.first);
      current.add(industry);
    }
    state = current.toList();
  }

  void updateAll(List<Industry> industries) {
    if (industries.length > 2) return;
    state = industries;
  }

  void reset() {
    ref.invalidateSelf();
  }

  Future<void> commit() async {
    if (supabase.auth.currentUser == null) return;
    final userId = supabase.auth.currentUser!.id;

    try {
      await supabase.from('user_industry').delete().eq('user_id', userId);
      if (state.isNotEmpty) {
        await supabase.from('user_industry').insert(
              state
                  .map((industry) => {
                        'user_id': userId,
                        'industry_id': industry.index,
                      })
                  .toList(),
            );
      }
    } catch (e, st) {
      Talker().handle(e, st, 'Error committing user industries');
      rethrow;
    }
  }
}

@riverpod
class ProfileController extends _$ProfileController {
  final supabase = Supabase.instance.client;
  final talker = Talker();

  @override
  ProfileState build() {
    final user = ref.watch(authControllerProvider).value;

    final networks = ref.watch(networkControllerProvider);
    final industries = ref.watch(industryControllerProvider);

    final username = user?.username ?? 'Guest';
    final tagNumber = user?.tagNumber ?? '0000';
    var details = user?.details ?? const UserDetails();

    if (details.generatedAvatar == null) {
      final seed = username == 'Guest'
          ? '${DateTime.now().millisecondsSinceEpoch}'
          : '${username}_$tagNumber';
      details = details.copyWith(generatedAvatar: seed);
    }

    return ProfileState(
      username: username,
      details: details,
      networks: networks,
      industries: industries,
    );
  }

  void updateDraft({
    String? username,
    UserDetails? details,
    List<Network>? networks,
    List<Industry>? industries,
    XFile? pickedAvatar,
    bool clearPickedAvatar = false,
  }) {
    state = state.copyWith(
      username: username ?? state.username,
      details: details ?? state.details,
      networks: networks ?? state.networks,
      industries: industries ?? state.industries,
      pickedAvatar: clearPickedAvatar ? null : (pickedAvatar ?? state.pickedAvatar),
    );
  }

  void randomizeAvatar() {
    final user = ref.read(authControllerProvider).value;
    final tagNumber = user?.tagNumber ?? '0000';
    final seed = '${DateTime.now().microsecondsSinceEpoch}_$tagNumber';
    updateDraft(
      details: state.details.copyWith(generatedAvatar: seed),
      clearPickedAvatar: true,
    );
  }

  void removeAvatar() {
    final user = ref.read(authControllerProvider).value;
    final tagNumber = user?.tagNumber ?? '0000';
    final seed = '${DateTime.now().microsecondsSinceEpoch}_$tagNumber';
    updateDraft(
      details: state.details.copyWith(generatedAvatar: seed),
      clearPickedAvatar: true,
    );
  }

  void uploadAvatar() async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.id == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked == null) return;

    updateDraft(
      details: state.details.copyWith(generatedAvatar: ''),
      pickedAvatar: picked,
    );
  }

  void resetDraft() {
    ref.read(networkControllerProvider.notifier).reset();
    ref.read(industryControllerProvider.notifier).reset();

    final user = ref.read(authControllerProvider).value;
    state = ProfileState(
      username: user?.username ?? 'Guest',
      details: user?.details ?? const UserDetails(),
      networks: ref.read(networkControllerProvider),
      industries: ref.read(industryControllerProvider),
    );
  }

  Future<void> commit() async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.id == null) return;

    var updatedDetails = state.details;

    try {
      // 1. Handle Avatar storage operations
      final oldGeneratedAvatar = user.details?.generatedAvatar;
      final newGeneratedAvatar = state.details.generatedAvatar;

      // If we previously had a custom photo (generatedAvatar was '')
      // and now we have a generated one (not ''), remove the custom photo from bucket
      if (oldGeneratedAvatar == '' && newGeneratedAvatar != '' && newGeneratedAvatar != null) {
        try {
          final path = '${user.id}.jpg';
          await supabase.storage.from('user_avatar').remove([path]);
        } catch (e, st) {
          talker.handle(e, st, 'Failed to remove avatar from storage');
        }
      }

      // If there's a picked avatar, upload it
      if (state.pickedAvatar != null) {
        try {
          final bytes = await state.pickedAvatar!.readAsBytes();
          final path = '${user.id}.jpg';

          await supabase.storage.from('user_avatar').uploadBinary(
                path,
                bytes,
                fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
              );
        } catch (e, st) {
          talker.handle(e, st, 'Failed to upload avatar to storage');
          // If upload fails, we might want to revert to a generated avatar
          // but for now let's just log it. The user will see a broken image or old one.
          // To be safe, if it fails and we intended it to be custom, maybe we should
          // set generatedAvatar back to something.
          // But according to instructions: "nullify the url if that previous step fails"
          // Since we don't have avatarUrl anymore, if upload fails, we should probably
          // set a generatedAvatar so it's not "null" (which means custom).
          final tagNumber = user.tagNumber;
          final seed = 'fallback_${DateTime.now().millisecondsSinceEpoch}_$tagNumber';
          updatedDetails = updatedDetails.copyWith(generatedAvatar: seed);
        }
      }

      await Future.wait([
        // 2. Update user basic info & details json
        supabase.from('user').update({
          'username': state.username,
          'details': updatedDetails.toJson(),
        }).eq('id', user.id!),

        // 3. Sync networks (user_network table)
        ref.read(networkControllerProvider.notifier).commit(),

        // 4. Sync industries (user_industry table)
        ref.read(industryControllerProvider.notifier).commit(),
      ]);
    } on PostgrestException catch (e, st) {
      talker.handle(e, st, state.details.toString());
      rethrow;
    } catch (e, st) {
      talker.handle(e, st);
      rethrow;
    } finally {
      if (ref.mounted) {
        await ref.read(authControllerProvider.notifier).refresh();
      }
    }
  }

  void updateSportProfile(String sportId, SportProfile sportProfile) {
    final updatedSports = Map<String, SportProfile>.from(state.details.sport!);
    updatedSports[sportId] = sportProfile;

    state = state.copyWith(
      details: state.details.copyWith(sport: updatedSports),
    );
  }

  void resetPlaytime() {
    final user = ref.read(authControllerProvider).value;
    final originalPlaytime = user?.details?.playtime;
    state = state.copyWith(
      details: state.details.copyWith(playtime: originalPlaytime),
    );
  }

  Future<void> changePassword(String newPassword) async {
    try {
      await supabase.auth.updateUser(
        UserAttributes(
          password: newPassword,
        ),
      );
    } on AuthException catch (e, st) {
      talker.handle(e, st);
      rethrow;
    } catch (e, st) {
      talker.handle(e, st);
      rethrow;
    }
  }
}
