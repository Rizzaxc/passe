import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_controller.dart';
import '../core/model/user_details.dart';

part 'profile_controller.g.dart';

@riverpod
class ProfileController extends _$ProfileController {
  final supabase = Supabase.instance.client;

  @override
  UserDetails build() {
    final user = ref.watch(authControllerProvider).value;
    return user?.details ?? const UserDetails();
  }

  void updateDraft(UserDetails details) {
    state = details;
  }

  void resetDraft() {
    final user = ref.read(authControllerProvider).value;
    state = user?.details ?? const UserDetails();
  }

  Future<void> updateUsername(String username) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.id == null) return;

    try {
      await supabase
          .from('user')
          .update({'username': username})
          .eq('id', user.id!);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateDetails(UserDetails details) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.id == null) return;

    try {
      await supabase
          .from('user')
          .update({'details': details.toJson()})
          .eq('id', user.id!);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> commit() async {
    await updateDetails(state);
  }

  Future<void> updateSportProfile(String sportId, SportProfile sportProfile) async {
    final updatedSports = Map<String, SportProfile>.from(state.sport);
    updatedSports[sportId] = sportProfile;

    state = state.copyWith(sport: updatedSports);
    await commit();
  }

  Future<void> changePassword(String newPassword) async {
    try {
      await supabase.auth.updateUser(
        UserAttributes(
          password: newPassword,
        ),
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      rethrow;
    }
  }
}
