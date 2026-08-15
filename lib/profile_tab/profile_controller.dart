import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../auth/auth_controller.dart';
import '../core/model/enum.dart';
import '../core/model/network.dart';
import '../core/model/user_avatar.dart';
import '../core/model/user_details.dart';
import 'user_contact_controller.dart';

part 'profile_controller.freezed.dart';
part 'profile_controller.g.dart';

@riverpod
bool profileHasUncommittedChanges(Ref ref) {
  ref.watch(profileControllerProvider);
  ref.watch(networkControllerProvider);
  ref.watch(industryControllerProvider);
  ref.watch(userContactControllerProvider);
  return ref.read(profileControllerProvider.notifier).hasUncommittedChanges ||
      ref.read(networkControllerProvider.notifier).hasUncommittedChanges ||
      ref.read(industryControllerProvider.notifier).hasUncommittedChanges ||
      ref.read(userContactControllerProvider.notifier).hasUncommittedChanges;
}

class AvatarUploadFailedException implements Exception {
  const AvatarUploadFailedException();

  @override
  String toString() =>
      'AvatarUploadFailedException: failed to upload avatar to storage';
}

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

@freezed
abstract class NetworkSearchState with _$NetworkSearchState {
  const factory NetworkSearchState({
    @Default([]) List<Network> results,
    @Default(false) bool isLoading,
    @Default({}) Set<City> cityFilters,
    @Default({}) Set<NetworkCategory> categoryFilters,
  }) = _NetworkSearchState;
}

@riverpod
class NetworkSearchController extends _$NetworkSearchController {
  @override
  NetworkSearchState build() => const NetworkSearchState();

  void toggleCity(City city) {
    final updated = {...state.cityFilters};
    if (!updated.remove(city)) updated.add(city);
    state = state.copyWith(cityFilters: updated);
    _reSearch();
  }

  void toggleCategory(NetworkCategory category) {
    final updated = {...state.categoryFilters};
    if (!updated.remove(category)) updated.add(category);
    state = state.copyWith(categoryFilters: updated);
    _reSearch();
  }

  String _lastQuery = '';

  Future<void> search(String query) async {
    _lastQuery = query;
    await _executeSearch(query);
  }

  Future<void> _reSearch() async {
    if (_lastQuery.isEmpty) return;
    await _executeSearch(_lastQuery);
  }

  Future<void> _executeSearch(String query) async {
    if (query.length < 3) {
      state = state.copyWith(results: [], isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true);
    try {
      final supabase = Supabase.instance.client;
      final params = <String, dynamic>{
        'search_term': query,
        'result_limit': 10,
        'filter_cities': state.cityFilters.map((c) => c.dbIndex).toList(),
        'filter_categories': state.categoryFilters
            .map((c) => c.jsonValue)
            .toList(),
      };

      final response = await supabase
          .rpc('search_networks_unaccent', params: params)
          .timeout(const Duration(seconds: 5));

      state = state.copyWith(
        isLoading: false,
        results: (response as List).map((data) {
          return Network(
            id: data['id'] as int,
            name: data['name'] as String,
            isAlumni: false,
            category: NetworkCategory.fromString(data['category'] as String?),
            city: data['city'] != null
                ? City.values[data['city'] as int]
                : null,
          );
        }).toList(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }
}

@riverpod
class NetworkController extends _$NetworkController {
  final supabase = Supabase.instance.client;
  List<Network>? _initialNetworks;

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
          .eq('user_id', userId)
          .timeout(const Duration(seconds: 5));

      final networks = (response as List).map((data) {
        final networkData = data['network'] as Map<String, dynamic>;
        return Network(
          id: networkData['id'] as int,
          name: networkData['name'] as String,
          isAlumni: data['alumni'] as bool,
          category: NetworkCategory.fromString(
            networkData['category'] as String?,
          ),
          city: networkData['city'] != null
              ? City.values[networkData['city'] as int]
              : null,
        );
      }).toList();

      state = networks;
      _initialNetworks ??= List.unmodifiable(networks);
    } catch (e, st) {
      Talker().handle(e, st, 'Error fetching user networks');
    }
  }

  /// Returns false if at max capacity and trying to add.
  bool toggle(Network network) {
    final current = [...state];
    final index = current.indexWhere((selected) => selected.id == network.id);
    if (index != -1) {
      current.removeAt(index);
    } else if (current.length < 5) {
      current.add(network);
    } else {
      return false;
    }
    state = current;
    return true;
  }

  void setAlumni(int networkId, bool isAlumni) {
    state = [
      for (final network in state)
        if (network.id == networkId)
          network.copyWith(isAlumni: isAlumni)
        else
          network,
    ];
  }

  void remove(int networkId) {
    state = state.where((network) => network.id != networkId).toList();
  }

  bool get hasUncommittedChanges {
    final initial = _initialNetworks;
    if (initial == null || initial.length != state.length) {
      return initial != null;
    }
    return state.any((network) => !initial.contains(network));
  }

  void discardChanges() {
    final initial = _initialNetworks;
    if (initial != null) state = [...initial];
  }

  void updateAll(List<Network> networks) {
    state = networks;
  }

  void reset() {
    ref.invalidateSelf();
  }

  Future<void> commit() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      await supabase
          .from('user_network')
          .delete()
          .eq('user_id', userId)
          .timeout(const Duration(seconds: 5));
      if (state.isNotEmpty) {
        await supabase
            .from('user_network')
            .insert(
              state
                  .map(
                    (network) => {
                      'user_id': userId,
                      'network_id': network.id,
                      'alumni': network.isAlumni,
                    },
                  )
                  .toList(),
            )
            .timeout(const Duration(seconds: 5));
      }
      _initialNetworks = List.unmodifiable(state);
    } catch (e, st) {
      Talker().handle(e, st, 'Error committing user networks');
      rethrow;
    }
  }
}

@riverpod
class IndustryController extends _$IndustryController {
  final supabase = Supabase.instance.client;
  List<Industry>? _initialIndustries;

  @override
  List<Industry> build() {
    final user = ref.watch(authControllerProvider).value;
    if (user == null || user.id == null) return [];

    // Fetch initial data
    _fetchIndustries(user.id!);
    return [];
  }

  Future<void> _fetchIndustries(String userId) async {
    try {
      final response = await supabase
          .from('user_industry')
          .select('industry_id')
          .eq('user_id', userId)
          .timeout(const Duration(seconds: 5));

      final industries = (response as List).map((data) {
        final industryId = data['industry_id'] as int;
        return Industry.values[industryId];
      }).toList();

      state = industries;
      _initialIndustries ??= List.unmodifiable(industries);
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

  bool get hasUncommittedChanges {
    final initial = _initialIndustries;
    if (initial == null || initial.length != state.length) {
      return initial != null;
    }
    return state.any((industry) => !initial.contains(industry));
  }

  void discardChanges() {
    final initial = _initialIndustries;
    if (initial != null) state = [...initial];
  }

  void reset() {
    ref.invalidateSelf();
  }

  Future<void> commit() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      await supabase
          .from('user_industry')
          .delete()
          .eq('user_id', userId)
          .timeout(const Duration(seconds: 5));
      if (state.isNotEmpty) {
        await supabase
            .from('user_industry')
            .insert(
              state
                  .map(
                    (industry) => {
                      'user_id': userId,
                      'industry_id': industry.index,
                    },
                  )
                  .toList(),
            )
            .timeout(const Duration(seconds: 5));
      }
      _initialIndustries = List.unmodifiable(state);
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
  ProfileState? _initialState;
  String? _initialUserId;
  bool _hasInitialUser = false;

  @override
  ProfileState build() {
    final user = ref.watch(authControllerProvider).value;

    final networks = ref.watch(networkControllerProvider);
    final industries = ref.watch(industryControllerProvider);

    final username = user?.username ?? 'Guest';
    final tagNumber = user?.tagNumber ?? '0000';
    var details = user?.details ?? const UserDetails();

    if (details.avatar == null) {
      // A fixed seed, not a timestamp: this branch also fires transiently
      // while `authControllerProvider` is between AsyncLoading and AsyncData
      // (every sign-in briefly passes through this), and `ProfileTab` shows
      // a spinner rather than this controller's state during that gap, so a
      // stable placeholder here is never actually seen by a real guest — it
      // only needs to stay *identical* across repeated rebuilds. A
      // per-rebuild-unique seed made `hasUncommittedChanges` (below) read
      // true for a user who never touched anything: the `_initialUserId`
      // guard only re-baselines `_initialState` when `user?.id` *changes*,
      // so two consecutive null-user rebuilds (both `id == null`) each got a
      // fresh random seed while only the first one was captured as the
      // baseline.
      final seed = username == 'Guest' ? 'guest' : '${username}_$tagNumber';
      details = details.copyWith(avatar: GeneratedAvatar(seed));
    }

    final initial = ProfileState(
      username: username,
      details: details,
      networks: networks,
      industries: industries,
    );
    // This controller can first build while auth is loading, which produces a
    // temporary Guest draft. Replace that baseline when the resolved identity
    // changes; otherwise merely landing on Profile immediately after login is
    // incorrectly treated as an edit to the Guest draft.
    if (!_hasInitialUser || _initialUserId != user?.id) {
      _initialState = initial;
      _initialUserId = user?.id;
      _hasInitialUser = true;
    }
    return initial;
  }

  bool get hasUncommittedChanges {
    final initial = _initialState;
    if (initial == null) return false;
    return state.username != initial.username ||
        state.details != initial.details ||
        state.pickedAvatar != initial.pickedAvatar;
  }

  void discardChanges() {
    final initial = _initialState;
    if (initial != null) state = initial;
    ref.read(networkControllerProvider.notifier).discardChanges();
    ref.read(industryControllerProvider.notifier).discardChanges();
    ref.read(userContactControllerProvider.notifier).discardChanges();
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
      pickedAvatar: clearPickedAvatar
          ? null
          : (pickedAvatar ?? state.pickedAvatar),
    );
  }

  void randomizeAvatar() {
    final user = ref.read(authControllerProvider).value;
    final tagNumber = user?.tagNumber ?? '0000';
    final seed = '${DateTime.now().microsecondsSinceEpoch}_$tagNumber';
    updateDraft(
      details: state.details.copyWith(avatar: GeneratedAvatar(seed)),
      clearPickedAvatar: true,
    );
  }

  void removeAvatar() {
    final user = ref.read(authControllerProvider).value;
    final tagNumber = user?.tagNumber ?? '0000';
    final seed = '${DateTime.now().microsecondsSinceEpoch}_$tagNumber';
    updateDraft(
      details: state.details.copyWith(avatar: GeneratedAvatar(seed)),
      clearPickedAvatar: true,
    );
  }

  /// Stores an already-picked-and-cropped avatar as the draft pick. Picking
  /// and cropping happen in the UI layer (`profile_tab/main.dart`) since the
  /// native crop screen needs a `BuildContext` for theming.
  void setPickedAvatar(XFile file) {
    updateDraft(
      details: state.details.copyWith(avatar: const PhotoAvatar()),
      pickedAvatar: file,
    );
  }

  void resetDraft() {
    ref.read(networkControllerProvider.notifier).reset();
    ref.read(industryControllerProvider.notifier).reset();
    ref.read(userContactControllerProvider.notifier).reset();

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
    var avatarUploadFailed = false;

    try {
      // 1. Handle Avatar storage operations
      final oldAvatar = user.details?.avatar;
      final newAvatar = state.details.avatar;

      // If we previously had a custom photo and now we have a generated
      // one, remove the custom photo from the bucket.
      if (oldAvatar is PhotoAvatar && newAvatar is GeneratedAvatar) {
        try {
          final path = '${user.id}.jpg';
          await supabase.storage
              .from('user_avatar')
              .remove([path])
              .timeout(const Duration(seconds: 5));
        } catch (e, st) {
          talker.handle(e, st, 'Failed to remove avatar from storage');
        }
      }

      // If there's a picked avatar, upload it
      if (state.pickedAvatar != null) {
        try {
          final bytes = await state.pickedAvatar!.readAsBytes();
          final path = '${user.id}.jpg';

          await supabase.storage
              .from('user_avatar')
              .uploadBinary(
                path,
                bytes,
                fileOptions: const FileOptions(
                  upsert: true,
                  contentType: 'image/jpeg',
                ),
              )
              .timeout(const Duration(seconds: 5));
        } catch (e, st) {
          talker.handle(e, st, 'Failed to upload avatar to storage');
          // Fall back to a generated avatar so `avatar` isn't left as
          // `PhotoAvatar` with nothing actually uploaded, then surface the
          // failure to the user via AvatarUploadFailedException once the
          // rest of the commit succeeds below.
          avatarUploadFailed = true;
          final tagNumber = user.tagNumber;
          final seed =
              'fallback_${DateTime.now().millisecondsSinceEpoch}_$tagNumber';
          updatedDetails = updatedDetails.copyWith(
            avatar: GeneratedAvatar(seed),
          );
        }
      }

      await Future.wait([
        // 2. Update user basic info & details json
        supabase
            .from('user')
            .update({
              'username': state.username,
              'details': updatedDetails.toJson(),
            })
            .eq('id', user.id!)
            .timeout(const Duration(seconds: 5)),

        // 3. Sync networks (user_network table)
        ref.read(networkControllerProvider.notifier).commit(),

        // 4. Sync industries (user_industry table)
        ref.read(industryControllerProvider.notifier).commit(),

        // 5. Sync contact info (user_contact table)
        ref.read(userContactControllerProvider.notifier).commit(),
      ]);

      // Clear the picked file from the live draft too, not just the
      // baseline — otherwise `state.pickedAvatar` (still the XFile) never
      // again equals `_initialState.pickedAvatar` (null), so
      // `hasUncommittedChanges` reports true forever after the first avatar
      // change+commit, prompting "discard changes?" on every later
      // navigation away from Profile even with nothing actually pending.
      state = state.copyWith(pickedAvatar: null);
      _initialState = state;

      if (avatarUploadFailed) {
        throw const AvatarUploadFailedException();
      }
    } on PostgrestException catch (e, st) {
      talker.handle(e, st, state.details.toString());
      rethrow;
    } on AvatarUploadFailedException {
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

  void resetPlaytime() {
    final user = ref.read(authControllerProvider).value;
    final originalPlaytime = user?.details?.playtime;
    state = state.copyWith(
      details: state.details.copyWith(playtime: originalPlaytime),
    );
  }
}
