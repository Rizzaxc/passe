import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../auth/auth_controller.dart';
import '../../core/model/sport_profile.dart';

part 'sport_profile_controller.g.dart';

// ─── Soccer ───────────────────────────────────────────────────────────────────

typedef SoccerProfileState = ({SoccerProfile profile, bool eloSeedLocked});

@riverpod
class SoccerProfileController extends _$SoccerProfileController {
  final _supabase = Supabase.instance.client;
  final _talker = Talker();

  @override
  SoccerProfileState build() {
    final user = ref.watch(authControllerProvider).value;
    if (user?.id != null) _fetch(user!.id!);
    return (profile: const SoccerProfile(), eloSeedLocked: false);
  }

  Future<void> _fetch(String userId) async {
    try {
      final response = await _supabase
          .from('soccer_profile')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (response != null) {
        final profile = SoccerProfile.fromJson(response);
        state = (profile: profile, eloSeedLocked: profile.eloSeed != null);
      }
    } catch (e, st) {
      _talker.handle(e, st, 'Error fetching soccer profile');
    }
  }

  void updateDraft(SoccerProfile profile) =>
      state = (profile: profile, eloSeedLocked: state.eloSeedLocked);

  void reset() => ref.invalidateSelf();

  Future<void> commit() async {
    final user = ref.read(authControllerProvider).value;
    if (user?.id == null) return;
    try {
      await _supabase.from('soccer_profile').upsert({
        'user_id': user!.id!,
        ...state.profile.toJson(),
      });
      if (state.profile.eloSeed != null) {
        state = (profile: state.profile, eloSeedLocked: true);
      }
    } catch (e, st) {
      _talker.handle(e, st, 'Error committing soccer profile');
      rethrow;
    }
  }
}

// ─── Basketball ───────────────────────────────────────────────────────────────

typedef BasketballProfileState = ({
  BasketballProfile profile,
  bool eloSeedLocked
});

@riverpod
class BasketballProfileController extends _$BasketballProfileController {
  final _supabase = Supabase.instance.client;
  final _talker = Talker();

  @override
  BasketballProfileState build() {
    final user = ref.watch(authControllerProvider).value;
    if (user?.id != null) _fetch(user!.id!);
    return (profile: const BasketballProfile(), eloSeedLocked: false);
  }

  Future<void> _fetch(String userId) async {
    try {
      final response = await _supabase
          .from('basketball_profile')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (response != null) {
        final profile = BasketballProfile.fromJson(response);
        state = (profile: profile, eloSeedLocked: profile.eloSeed != null);
      }
    } catch (e, st) {
      _talker.handle(e, st, 'Error fetching basketball profile');
    }
  }

  void updateDraft(BasketballProfile profile) =>
      state = (profile: profile, eloSeedLocked: state.eloSeedLocked);

  void reset() => ref.invalidateSelf();

  Future<void> commit() async {
    final user = ref.read(authControllerProvider).value;
    if (user?.id == null) return;
    try {
      await _supabase.from('basketball_profile').upsert({
        'user_id': user!.id!,
        ...state.profile.toJson(),
      });
      if (state.profile.eloSeed != null) {
        state = (profile: state.profile, eloSeedLocked: true);
      }
    } catch (e, st) {
      _talker.handle(e, st, 'Error committing basketball profile');
      rethrow;
    }
  }
}

// ─── Badminton ────────────────────────────────────────────────────────────────

typedef BadmintonProfileState = ({
  BadmintonProfile profile,
  bool eloSeedLocked
});

@riverpod
class BadmintonProfileController extends _$BadmintonProfileController {
  final _supabase = Supabase.instance.client;
  final _talker = Talker();

  @override
  BadmintonProfileState build() {
    final user = ref.watch(authControllerProvider).value;
    if (user?.id != null) _fetch(user!.id!);
    return (profile: const BadmintonProfile(), eloSeedLocked: false);
  }

  Future<void> _fetch(String userId) async {
    try {
      final response = await _supabase
          .from('badminton_profile')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (response != null) {
        final profile = BadmintonProfile.fromJson(response);
        state = (profile: profile, eloSeedLocked: profile.eloSeed != null);
      }
    } catch (e, st) {
      _talker.handle(e, st, 'Error fetching badminton profile');
    }
  }

  void updateDraft(BadmintonProfile profile) =>
      state = (profile: profile, eloSeedLocked: state.eloSeedLocked);

  void reset() => ref.invalidateSelf();

  Future<void> commit() async {
    final user = ref.read(authControllerProvider).value;
    if (user?.id == null) return;
    try {
      await _supabase.from('badminton_profile').upsert({
        'user_id': user!.id!,
        ...state.profile.toJson(),
      });
      if (state.profile.eloSeed != null) {
        state = (profile: state.profile, eloSeedLocked: true);
      }
    } catch (e, st) {
      _talker.handle(e, st, 'Error committing badminton profile');
      rethrow;
    }
  }
}

// ─── Tennis ───────────────────────────────────────────────────────────────────

typedef TennisProfileState = ({TennisProfile profile, bool eloSeedLocked});

@riverpod
class TennisProfileController extends _$TennisProfileController {
  final _supabase = Supabase.instance.client;
  final _talker = Talker();

  @override
  TennisProfileState build() {
    final user = ref.watch(authControllerProvider).value;
    if (user?.id != null) _fetch(user!.id!);
    return (profile: const TennisProfile(), eloSeedLocked: false);
  }

  Future<void> _fetch(String userId) async {
    try {
      final response = await _supabase
          .from('tennis_profile')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (response != null) {
        final profile = TennisProfile.fromJson(response);
        state = (profile: profile, eloSeedLocked: profile.eloSeed != null);
      }
    } catch (e, st) {
      _talker.handle(e, st, 'Error fetching tennis profile');
    }
  }

  void updateDraft(TennisProfile profile) =>
      state = (profile: profile, eloSeedLocked: state.eloSeedLocked);

  void reset() => ref.invalidateSelf();

  Future<void> commit() async {
    final user = ref.read(authControllerProvider).value;
    if (user?.id == null) return;
    try {
      await _supabase.from('tennis_profile').upsert({
        'user_id': user!.id!,
        ...state.profile.toJson(),
      });
      if (state.profile.eloSeed != null) {
        state = (profile: state.profile, eloSeedLocked: true);
      }
    } catch (e, st) {
      _talker.handle(e, st, 'Error committing tennis profile');
      rethrow;
    }
  }
}

// ─── Pickleball ───────────────────────────────────────────────────────────────

typedef PickleballProfileState = ({
  PickleballProfile profile,
  bool eloSeedLocked
});

@riverpod
class PickleballProfileController extends _$PickleballProfileController {
  final _supabase = Supabase.instance.client;
  final _talker = Talker();

  @override
  PickleballProfileState build() {
    final user = ref.watch(authControllerProvider).value;
    if (user?.id != null) _fetch(user!.id!);
    return (profile: const PickleballProfile(), eloSeedLocked: false);
  }

  Future<void> _fetch(String userId) async {
    try {
      final response = await _supabase
          .from('pickleball_profile')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (response != null) {
        final profile = PickleballProfile.fromJson(response);
        state = (profile: profile, eloSeedLocked: profile.eloSeed != null);
      }
    } catch (e, st) {
      _talker.handle(e, st, 'Error fetching pickleball profile');
    }
  }

  void updateDraft(PickleballProfile profile) =>
      state = (profile: profile, eloSeedLocked: state.eloSeedLocked);

  void reset() => ref.invalidateSelf();

  Future<void> commit() async {
    final user = ref.read(authControllerProvider).value;
    if (user?.id == null) return;
    try {
      await _supabase.from('pickleball_profile').upsert({
        'user_id': user!.id!,
        ...state.profile.toJson(),
      });
      if (state.profile.eloSeed != null) {
        state = (profile: state.profile, eloSeedLocked: true);
      }
    } catch (e, st) {
      _talker.handle(e, st, 'Error committing pickleball profile');
      rethrow;
    }
  }
}
