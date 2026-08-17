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
import 'write_failure_support.dart';

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
  late final _failures = WriteFailureHandler(ref);

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

  void updateAll(List<Network> networks) {
    state = networks;
  }

  /// Persists the current selection as a delete-all + reinsert-all — cheap
  /// here since this only runs once per visit to the network subroute (on
  /// pop), not per toggle.
  Future<void> flush() async {
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
    } catch (e, st) {
      _failures.handle(
        e,
        st,
        logMessage: 'Error flushing user networks',
        resync: () => ref.invalidateSelf(),
      );
    }
  }
}

@riverpod
class IndustryController extends _$IndustryController {
  final supabase = Supabase.instance.client;
  late final _failures = WriteFailureHandler(ref);

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

  /// Persists the current selection as a delete-all + reinsert-all — cheap
  /// here since this only runs once per visit to the industry subroute (on
  /// pop), not per toggle.
  Future<void> flush() async {
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
    } catch (e, st) {
      _failures.handle(
        e,
        st,
        logMessage: 'Error flushing user industries',
        resync: () => ref.invalidateSelf(),
      );
    }
  }
}

@riverpod
class ProfileController extends _$ProfileController {
  final supabase = Supabase.instance.client;
  late final _failures = WriteFailureHandler(ref);

  @override
  ProfileState build() {
    final user = ref.watch(authControllerProvider).value;

    final networks = ref.watch(networkControllerProvider);
    final industries = ref.watch(industryControllerProvider);

    final username = user?.username ?? 'Guest';
    final tagNumber = user?.tagNumber ?? '0000';
    var details = user?.details ?? const UserDetails();

    if (details.avatar == null) {
      // A fixed seed, not a timestamp, so the placeholder avatar doesn't
      // visibly change on every rebuild.
      final seed = username == 'Guest' ? 'guest' : '${username}_$tagNumber';
      details = details.copyWith(avatar: GeneratedAvatar(seed));
    }

    return ProfileState(
      username: username,
      details: details,
      networks: networks,
      industries: industries,
    );
  }

  /// Mutates the in-memory state only — used while a pushed subroute (age
  /// group / location / playtime) is open and editing `details` a field at a
  /// time. Call [flushDetails] to persist, typically from that subroute's
  /// pop handler.
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

  /// Persists the current username + details to `user`. Safe to call
  /// whether or not anything actually changed — a no-op write is harmless —
  /// which is what lets subroutes flush unconditionally on pop instead of
  /// tracking dirty state.
  Future<void> flushDetails() async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.id == null) return;

    try {
      await supabase
          .from('user')
          .update({
            'username': state.username,
            'details': state.details.toJson(),
          })
          .eq('id', user.id!)
          .timeout(const Duration(seconds: 5));
    } catch (e, st) {
      _failures.handle(
        e,
        st,
        logMessage: state.details.toString(),
        resync: () => ref.invalidate(authControllerProvider),
      );
    } finally {
      if (ref.mounted) {
        await ref.read(authControllerProvider.notifier).refresh();
      }
    }
  }

  /// Convenience for callers that always want an immediate write — no
  /// subroute buffering — e.g. onboarding's single-sheet flow, or an
  /// in-place field on the main tab like gender.
  Future<void> updateDetailsAndFlush(UserDetails details) async {
    updateDraft(details: details);
    await flushDetails();
  }

  Future<void> setGender(Gender gender) =>
      updateDetailsAndFlush(state.details.copyWith(gender: gender));

  Future<void> randomizeAvatar() async {
    final user = ref.read(authControllerProvider).value;
    final tagNumber = user?.tagNumber ?? '0000';
    final seed = '${DateTime.now().microsecondsSinceEpoch}_$tagNumber';
    await _setAvatar(GeneratedAvatar(seed));
  }

  Future<void> removeAvatar() async {
    final user = ref.read(authControllerProvider).value;
    final tagNumber = user?.tagNumber ?? '0000';
    final seed = '${DateTime.now().microsecondsSinceEpoch}_$tagNumber';
    await _setAvatar(GeneratedAvatar(seed));
  }

  Future<void> _setAvatar(UserAvatar avatar) async {
    final oldAvatar = state.details.avatar;
    updateDraft(
      details: state.details.copyWith(avatar: avatar),
      clearPickedAvatar: true,
    );

    // Swapping away from a custom photo to a generated one: clean up the
    // now-orphaned storage object.
    if (oldAvatar is PhotoAvatar && avatar is GeneratedAvatar) {
      final userId = ref.read(authControllerProvider).value?.id;
      if (userId != null) {
        try {
          await supabase.storage
              .from('user_avatar')
              .remove(['$userId.jpg'])
              .timeout(const Duration(seconds: 5));
        } catch (e, st) {
          Talker().handle(e, st, 'Failed to remove avatar from storage');
        }
      }
    }

    await flushDetails();
  }

  /// Uploads an already-picked-and-cropped avatar (picking and cropping
  /// happen in the UI layer — `profile_tab/main.dart` — since the native
  /// crop screen needs a `BuildContext` for theming) and persists
  /// `details.avatar`. On upload failure, falls back to a generated seed;
  /// the failure itself surfaces via [WriteFailureHandler].
  Future<void> pickAvatar(XFile file) async {
    updateDraft(
      details: state.details.copyWith(avatar: const PhotoAvatar()),
      pickedAvatar: file,
    );

    final user = ref.read(authControllerProvider).value;
    if (user == null || user.id == null) return;

    try {
      final bytes = await file.readAsBytes();
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
      final seed =
          'fallback_${DateTime.now().millisecondsSinceEpoch}_${user.tagNumber}';
      updateDraft(
        details: state.details.copyWith(avatar: GeneratedAvatar(seed)),
      );
      _failures.handle(
        e,
        st,
        logMessage: 'Failed to upload avatar to storage',
        resync: () => ref.invalidate(authControllerProvider),
      );
    }

    state = state.copyWith(pickedAvatar: null);
    await flushDetails();
  }

  void resetPlaytime() {
    final user = ref.read(authControllerProvider).value;
    final originalPlaytime = user?.details?.playtime;
    state = state.copyWith(
      details: state.details.copyWith(playtime: originalPlaytime),
    );
  }
}
