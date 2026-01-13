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
class ProfileController extends _$ProfileController {
  final supabase = Supabase.instance.client;
  final talker = Talker();

  @override
  ProfileState build() {
    final user = ref.watch(authControllerProvider).value;
    // Note: in a real app, networks and industries would be fetched from /profile
    // For now, initializing with empty lists if not available in user object
    // Assuming User model might have been updated too, but issue says fetched separately.
    return ProfileState(
      username: user?.username ?? 'Guest',
      details: user?.details ?? const UserDetails(),
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
    final user = ref.read(authControllerProvider).value;
    state = ProfileState(
      username: user?.username ?? 'Guest',
      details: user?.details ?? const UserDetails(),
    );
  }

  Future<void> commit() async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.id == null) return;

    try {
      await supabase.from('user').update({
        'username': state.username,
        'details': state.details.toJson(),
      }).eq('id', user.id!);

      await ref.read(authControllerProvider.notifier).refresh();
    } on PostgrestException catch (e, st) {
      talker.handle(e, st, state.details.toString());
      rethrow;
    } catch (e, st) {
      talker.handle(e, st);
      rethrow;
    }
  }

  void updateSportProfile(String sportId, SportProfile sportProfile) {
    final updatedSports = Map<String, SportProfile>.from(state.details.sport!);
    updatedSports[sportId] = sportProfile;

    state = state.copyWith(
      details: state.details.copyWith(sport: updatedSports),
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
