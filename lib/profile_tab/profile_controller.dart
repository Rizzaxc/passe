import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
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
  }) = _ProfileState;
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
    
    return ProfileState(
      username: user?.username ?? 'Guest',
      details: user?.details ?? const UserDetails(),
      networks: networks,
      industries: industries,
    );
  }

  void updateDraft({
    String? username,
    UserDetails? details,
    List<Network>? networks,
    List<Industry>? industries,
  }) {
    state = state.copyWith(
      username: username ?? state.username,
      details: details ?? state.details,
      networks: networks ?? state.networks,
      industries: industries ?? state.industries,
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

    try {
      await Future.wait([
        // 1. Update user basic info & details json
        supabase.from('user').update({
          'username': state.username,
          'details': state.details.toJson(),
        }).eq('id', user.id!),

        // 2. Sync networks (user_network table)
        ref.read(networkControllerProvider.notifier).commit(),

        // 3. Sync industries (user_industry table)
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
