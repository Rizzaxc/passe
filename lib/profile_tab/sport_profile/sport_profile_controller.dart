import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../auth/auth_controller.dart';
import '../../core/model/enum.dart';
import '../../core/model/sport_profile.dart';
import '../../core/state/selected_sport_state.dart';

part 'sport_profile_controller.g.dart';

@riverpod
bool sportProfileHasUncommittedChanges(Ref ref) {
  final sport = ref.watch(selectedSportStateProvider).asData?.value;
  return switch (sport) {
    Sport.soccer =>
      ref.watch(soccerProfileControllerProvider).profile !=
          ref.read(soccerProfileControllerProvider.notifier).initialProfile,
    Sport.basketball =>
      ref.watch(basketballProfileControllerProvider).profile !=
          ref.read(basketballProfileControllerProvider.notifier).initialProfile,
    Sport.badminton =>
      ref.watch(badmintonProfileControllerProvider).profile !=
          ref.read(badmintonProfileControllerProvider.notifier).initialProfile,
    Sport.tennis =>
      ref.watch(tennisProfileControllerProvider).profile !=
          ref.read(tennisProfileControllerProvider.notifier).initialProfile,
    Sport.pickleball =>
      ref.watch(pickleballProfileControllerProvider).profile !=
          ref.read(pickleballProfileControllerProvider.notifier).initialProfile,
    _ => false,
  };
}

void discardSportProfileChanges(WidgetRef ref, Sport sport) {
  switch (sport) {
    case Sport.soccer:
      ref.read(soccerProfileControllerProvider.notifier).discardChanges();
    case Sport.basketball:
      ref.read(basketballProfileControllerProvider.notifier).discardChanges();
    case Sport.badminton:
      ref.read(badmintonProfileControllerProvider.notifier).discardChanges();
    case Sport.tennis:
      ref.read(tennisProfileControllerProvider.notifier).discardChanges();
    case Sport.pickleball:
      ref.read(pickleballProfileControllerProvider.notifier).discardChanges();
    case Sport.others:
      break;
  }
}

/// Shared dispatch used by both [SportProfileScreen] and the onboarding
/// profile step so there's one place that knows how to commit/read a sport's
/// profile instead of a private switch duplicated per call site.
Future<void> commitSportProfile(WidgetRef ref, Sport sport) => switch (sport) {
  Sport.soccer => ref.read(soccerProfileControllerProvider.notifier).commit(),
  Sport.basketball =>
    ref.read(basketballProfileControllerProvider.notifier).commit(),
  Sport.badminton =>
    ref.read(badmintonProfileControllerProvider.notifier).commit(),
  Sport.tennis => ref.read(tennisProfileControllerProvider.notifier).commit(),
  Sport.pickleball =>
    ref.read(pickleballProfileControllerProvider.notifier).commit(),
  Sport.others => Future.value(),
};

/// Current `elo_seed` value + whether it's locked (already committed) for
/// [sport]. Locking is permanent once set — see `EloSeedField`.
({EloSeed? seed, bool locked}) readSportEloSeed(WidgetRef ref, Sport sport) =>
    switch (sport) {
      Sport.soccer => (
        seed: ref.watch(soccerProfileControllerProvider).profile.eloSeed,
        locked: ref.watch(soccerProfileControllerProvider).eloSeedLocked,
      ),
      Sport.basketball => (
        seed: ref.watch(basketballProfileControllerProvider).profile.eloSeed,
        locked: ref.watch(basketballProfileControllerProvider).eloSeedLocked,
      ),
      Sport.badminton => (
        seed: ref.watch(badmintonProfileControllerProvider).profile.eloSeed,
        locked: ref.watch(badmintonProfileControllerProvider).eloSeedLocked,
      ),
      Sport.tennis => (
        seed: ref.watch(tennisProfileControllerProvider).profile.eloSeed,
        locked: ref.watch(tennisProfileControllerProvider).eloSeedLocked,
      ),
      Sport.pickleball => (
        seed: ref.watch(pickleballProfileControllerProvider).profile.eloSeed,
        locked: ref.watch(pickleballProfileControllerProvider).eloSeedLocked,
      ),
      Sport.others => (seed: null, locked: false),
    };

/// Sets only the draft `elo_seed` for [sport], leaving its other fields
/// untouched. Does not persist — call [commitSportProfile] to write it.
void setSportEloSeed(WidgetRef ref, Sport sport, EloSeed seed) {
  switch (sport) {
    case Sport.soccer:
      final notifier = ref.read(soccerProfileControllerProvider.notifier);
      notifier.updateDraft(
        ref
            .read(soccerProfileControllerProvider)
            .profile
            .copyWith(eloSeed: seed),
      );
    case Sport.basketball:
      final notifier = ref.read(basketballProfileControllerProvider.notifier);
      notifier.updateDraft(
        ref
            .read(basketballProfileControllerProvider)
            .profile
            .copyWith(eloSeed: seed),
      );
    case Sport.badminton:
      final notifier = ref.read(badmintonProfileControllerProvider.notifier);
      notifier.updateDraft(
        ref
            .read(badmintonProfileControllerProvider)
            .profile
            .copyWith(eloSeed: seed),
      );
    case Sport.tennis:
      final notifier = ref.read(tennisProfileControllerProvider.notifier);
      notifier.updateDraft(
        ref
            .read(tennisProfileControllerProvider)
            .profile
            .copyWith(eloSeed: seed),
      );
    case Sport.pickleball:
      final notifier = ref.read(pickleballProfileControllerProvider.notifier);
      notifier.updateDraft(
        ref
            .read(pickleballProfileControllerProvider)
            .profile
            .copyWith(eloSeed: seed),
      );
    case Sport.others:
      break;
  }
}

// ─── Soccer ───────────────────────────────────────────────────────────────────

typedef SoccerProfileState = ({SoccerProfile profile, bool eloSeedLocked});

@riverpod
class SoccerProfileController extends _$SoccerProfileController {
  final _supabase = Supabase.instance.client;
  final _talker = Talker();
  SoccerProfile initialProfile = const SoccerProfile();

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
          .maybeSingle()
          .timeout(const Duration(seconds: 5));
      if (response != null) {
        final profile = SoccerProfile.fromJson(response);
        if (ref.mounted) {
          initialProfile = profile;
          state = (profile: profile, eloSeedLocked: profile.eloSeed != null);
        }
      }
    } catch (e, st) {
      _talker.handle(e, st, 'Error fetching soccer profile');
    }
  }

  void updateDraft(SoccerProfile profile) =>
      state = (profile: profile, eloSeedLocked: state.eloSeedLocked);

  void reset() => ref.invalidateSelf();
  void discardChanges() =>
      state = (profile: initialProfile, eloSeedLocked: state.eloSeedLocked);

  Future<void> commit() async {
    final user = ref.read(authControllerProvider).value;
    if (user?.id == null) return;
    final draft = state.profile;
    try {
      await _supabase
          .from('soccer_profile')
          .upsert({'user_id': user!.id!, ...draft.toJson()})
          .timeout(const Duration(seconds: 5));
      // `commit()` runs alongside `ProfileController.commit()` via
      // `Future.wait` on the profile screen's commit button, whose `finally`
      // refreshes `authControllerProvider` — which this controller watches.
      // That refresh can dispose/rebuild this controller before this upsert's
      // await returns, so the state write below must be `ref.mounted`-gated
      // (matching `_fetch`'s existing guard) or it throws "Cannot use Ref
      // after disposed" on the stale instance.
      if (!ref.mounted) return;
      initialProfile = draft;
      if (draft.eloSeed != null) {
        state = (profile: draft, eloSeedLocked: true);
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
  bool eloSeedLocked,
});

@riverpod
class BasketballProfileController extends _$BasketballProfileController {
  final _supabase = Supabase.instance.client;
  final _talker = Talker();
  BasketballProfile initialProfile = const BasketballProfile();

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
          .maybeSingle()
          .timeout(const Duration(seconds: 5));
      if (response != null) {
        final profile = BasketballProfile.fromJson(response);
        if (ref.mounted) {
          initialProfile = profile;
          state = (profile: profile, eloSeedLocked: profile.eloSeed != null);
        }
      }
    } catch (e, st) {
      _talker.handle(e, st, 'Error fetching basketball profile');
    }
  }

  void updateDraft(BasketballProfile profile) =>
      state = (profile: profile, eloSeedLocked: state.eloSeedLocked);

  void reset() => ref.invalidateSelf();
  void discardChanges() =>
      state = (profile: initialProfile, eloSeedLocked: state.eloSeedLocked);

  Future<void> commit() async {
    final user = ref.read(authControllerProvider).value;
    if (user?.id == null) return;
    final draft = state.profile;
    try {
      await _supabase
          .from('basketball_profile')
          .upsert({'user_id': user!.id!, ...draft.toJson()})
          .timeout(const Duration(seconds: 5));
      // `commit()` runs alongside `ProfileController.commit()` via
      // `Future.wait` on the profile screen's commit button, whose `finally`
      // refreshes `authControllerProvider` — which this controller watches.
      // That refresh can dispose/rebuild this controller before this upsert's
      // await returns, so the state write below must be `ref.mounted`-gated
      // (matching `_fetch`'s existing guard) or it throws "Cannot use Ref
      // after disposed" on the stale instance.
      if (!ref.mounted) return;
      initialProfile = draft;
      if (draft.eloSeed != null) {
        state = (profile: draft, eloSeedLocked: true);
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
  bool eloSeedLocked,
});

@riverpod
class BadmintonProfileController extends _$BadmintonProfileController {
  final _supabase = Supabase.instance.client;
  final _talker = Talker();
  BadmintonProfile initialProfile = const BadmintonProfile();

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
          .maybeSingle()
          .timeout(const Duration(seconds: 5));
      if (response != null) {
        final profile = BadmintonProfile.fromJson(response);
        if (ref.mounted) {
          initialProfile = profile;
          state = (profile: profile, eloSeedLocked: profile.eloSeed != null);
        }
      }
    } catch (e, st) {
      _talker.handle(e, st, 'Error fetching badminton profile');
    }
  }

  void updateDraft(BadmintonProfile profile) =>
      state = (profile: profile, eloSeedLocked: state.eloSeedLocked);

  void reset() => ref.invalidateSelf();
  void discardChanges() =>
      state = (profile: initialProfile, eloSeedLocked: state.eloSeedLocked);

  Future<void> commit() async {
    final user = ref.read(authControllerProvider).value;
    if (user?.id == null) return;
    final draft = state.profile;
    try {
      await _supabase
          .from('badminton_profile')
          .upsert({'user_id': user!.id!, ...draft.toJson()})
          .timeout(const Duration(seconds: 5));
      // `commit()` runs alongside `ProfileController.commit()` via
      // `Future.wait` on the profile screen's commit button, whose `finally`
      // refreshes `authControllerProvider` — which this controller watches.
      // That refresh can dispose/rebuild this controller before this upsert's
      // await returns, so the state write below must be `ref.mounted`-gated
      // (matching `_fetch`'s existing guard) or it throws "Cannot use Ref
      // after disposed" on the stale instance.
      if (!ref.mounted) return;
      initialProfile = draft;
      if (draft.eloSeed != null) {
        state = (profile: draft, eloSeedLocked: true);
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
  TennisProfile initialProfile = const TennisProfile();

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
          .maybeSingle()
          .timeout(const Duration(seconds: 5));
      if (response != null) {
        final profile = TennisProfile.fromJson(response);
        if (ref.mounted) {
          initialProfile = profile;
          state = (profile: profile, eloSeedLocked: profile.eloSeed != null);
        }
      }
    } catch (e, st) {
      _talker.handle(e, st, 'Error fetching tennis profile');
    }
  }

  void updateDraft(TennisProfile profile) =>
      state = (profile: profile, eloSeedLocked: state.eloSeedLocked);

  void reset() => ref.invalidateSelf();
  void discardChanges() =>
      state = (profile: initialProfile, eloSeedLocked: state.eloSeedLocked);

  Future<void> commit() async {
    final user = ref.read(authControllerProvider).value;
    if (user?.id == null) return;
    final draft = state.profile;
    try {
      await _supabase
          .from('tennis_profile')
          .upsert({'user_id': user!.id!, ...draft.toJson()})
          .timeout(const Duration(seconds: 5));
      // `commit()` runs alongside `ProfileController.commit()` via
      // `Future.wait` on the profile screen's commit button, whose `finally`
      // refreshes `authControllerProvider` — which this controller watches.
      // That refresh can dispose/rebuild this controller before this upsert's
      // await returns, so the state write below must be `ref.mounted`-gated
      // (matching `_fetch`'s existing guard) or it throws "Cannot use Ref
      // after disposed" on the stale instance.
      if (!ref.mounted) return;
      initialProfile = draft;
      if (draft.eloSeed != null) {
        state = (profile: draft, eloSeedLocked: true);
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
  bool eloSeedLocked,
});

@riverpod
class PickleballProfileController extends _$PickleballProfileController {
  final _supabase = Supabase.instance.client;
  final _talker = Talker();
  PickleballProfile initialProfile = const PickleballProfile();

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
          .maybeSingle()
          .timeout(const Duration(seconds: 5));
      if (response != null) {
        final profile = PickleballProfile.fromJson(response);
        if (ref.mounted) {
          initialProfile = profile;
          state = (profile: profile, eloSeedLocked: profile.eloSeed != null);
        }
      }
    } catch (e, st) {
      _talker.handle(e, st, 'Error fetching pickleball profile');
    }
  }

  void updateDraft(PickleballProfile profile) =>
      state = (profile: profile, eloSeedLocked: state.eloSeedLocked);

  void reset() => ref.invalidateSelf();
  void discardChanges() =>
      state = (profile: initialProfile, eloSeedLocked: state.eloSeedLocked);

  Future<void> commit() async {
    final user = ref.read(authControllerProvider).value;
    if (user?.id == null) return;
    final draft = state.profile;
    try {
      await _supabase
          .from('pickleball_profile')
          .upsert({'user_id': user!.id!, ...draft.toJson()})
          .timeout(const Duration(seconds: 5));
      // `commit()` runs alongside `ProfileController.commit()` via
      // `Future.wait` on the profile screen's commit button, whose `finally`
      // refreshes `authControllerProvider` — which this controller watches.
      // That refresh can dispose/rebuild this controller before this upsert's
      // await returns, so the state write below must be `ref.mounted`-gated
      // (matching `_fetch`'s existing guard) or it throws "Cannot use Ref
      // after disposed" on the stale instance.
      if (!ref.mounted) return;
      initialProfile = draft;
      if (draft.eloSeed != null) {
        state = (profile: draft, eloSeedLocked: true);
      }
    } catch (e, st) {
      _talker.handle(e, st, 'Error committing pickleball profile');
      rethrow;
    }
  }
}
