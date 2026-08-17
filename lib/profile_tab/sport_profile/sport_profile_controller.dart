import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../auth/auth_controller.dart';
import '../../core/model/enum.dart';
import '../../core/model/sport_profile.dart';
import '../write_failure_support.dart';

part 'sport_profile_controller.g.dart';

/// Shared dispatch used by both [SportProfileScreen] and the onboarding
/// profile step so there's one place that knows how to flush/read a sport's
/// profile instead of a private switch duplicated per call site. Called from
/// a `PFlushOnPop` handler (or onboarding's sheet-close), not a button press.
Future<void> flushSportProfile(WidgetRef ref, Sport sport) => switch (sport) {
  Sport.soccer => ref.read(soccerProfileControllerProvider.notifier).flush(),
  Sport.basketball =>
    ref.read(basketballProfileControllerProvider.notifier).flush(),
  Sport.badminton =>
    ref.read(badmintonProfileControllerProvider.notifier).flush(),
  Sport.tennis => ref.read(tennisProfileControllerProvider.notifier).flush(),
  Sport.pickleball =>
    ref.read(pickleballProfileControllerProvider.notifier).flush(),
  Sport.others => Future.value(),
};

/// Current `elo_seed` value for [sport]. Self-declared and freely editable —
/// the DB only ever uses the *first* value it sees to seed `user_rating`
/// (`fn_seed_initial_elo`), it never blocks a later change.
EloSeed? readSportEloSeed(WidgetRef ref, Sport sport) => switch (sport) {
  Sport.soccer => ref.watch(soccerProfileControllerProvider).eloSeed,
  Sport.basketball => ref.watch(basketballProfileControllerProvider).eloSeed,
  Sport.badminton => ref.watch(badmintonProfileControllerProvider).eloSeed,
  Sport.tennis => ref.watch(tennisProfileControllerProvider).eloSeed,
  Sport.pickleball => ref.watch(pickleballProfileControllerProvider).eloSeed,
  Sport.others => null,
};

/// Sets only the draft `elo_seed` for [sport], leaving its other fields
/// untouched. Does not persist — call [flushSportProfile] to write it.
void setSportEloSeed(WidgetRef ref, Sport sport, EloSeed seed) {
  switch (sport) {
    case Sport.soccer:
      final notifier = ref.read(soccerProfileControllerProvider.notifier);
      notifier.updateDraft(
        ref.read(soccerProfileControllerProvider).copyWith(eloSeed: seed),
      );
    case Sport.basketball:
      final notifier = ref.read(basketballProfileControllerProvider.notifier);
      notifier.updateDraft(
        ref.read(basketballProfileControllerProvider).copyWith(eloSeed: seed),
      );
    case Sport.badminton:
      final notifier = ref.read(badmintonProfileControllerProvider.notifier);
      notifier.updateDraft(
        ref.read(badmintonProfileControllerProvider).copyWith(eloSeed: seed),
      );
    case Sport.tennis:
      final notifier = ref.read(tennisProfileControllerProvider.notifier);
      notifier.updateDraft(
        ref.read(tennisProfileControllerProvider).copyWith(eloSeed: seed),
      );
    case Sport.pickleball:
      final notifier = ref.read(pickleballProfileControllerProvider.notifier);
      notifier.updateDraft(
        ref.read(pickleballProfileControllerProvider).copyWith(eloSeed: seed),
      );
    case Sport.others:
      break;
  }
}

// ─── Soccer ───────────────────────────────────────────────────────────────────

@riverpod
class SoccerProfileController extends _$SoccerProfileController {
  final _supabase = Supabase.instance.client;
  final _talker = Talker();
  late final _failures = WriteFailureHandler(ref);

  @override
  SoccerProfile build() {
    final user = ref.watch(authControllerProvider).value;
    if (user?.id != null) _fetch(user!.id!);
    return const SoccerProfile();
  }

  Future<void> _fetch(String userId) async {
    try {
      final response = await _supabase
          .from('soccer_profile')
          .select()
          .eq('user_id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));
      if (response != null && ref.mounted) {
        state = SoccerProfile.fromJson(response);
      }
    } catch (e, st) {
      _talker.handle(e, st, 'Error fetching soccer profile');
    }
  }

  void updateDraft(SoccerProfile profile) => state = profile;

  Future<void> flush() async {
    final user = ref.read(authControllerProvider).value;
    if (user?.id == null) return;
    try {
      await _supabase
          .from('soccer_profile')
          .upsert({'user_id': user!.id!, ...state.toJson()})
          .timeout(const Duration(seconds: 5));
    } catch (e, st) {
      _failures.handle(
        e,
        st,
        logMessage: 'Error flushing soccer profile',
        resync: () => ref.invalidateSelf(),
      );
    }
  }
}

// ─── Basketball ───────────────────────────────────────────────────────────────

@riverpod
class BasketballProfileController extends _$BasketballProfileController {
  final _supabase = Supabase.instance.client;
  final _talker = Talker();
  late final _failures = WriteFailureHandler(ref);

  @override
  BasketballProfile build() {
    final user = ref.watch(authControllerProvider).value;
    if (user?.id != null) _fetch(user!.id!);
    return const BasketballProfile();
  }

  Future<void> _fetch(String userId) async {
    try {
      final response = await _supabase
          .from('basketball_profile')
          .select()
          .eq('user_id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));
      if (response != null && ref.mounted) {
        state = BasketballProfile.fromJson(response);
      }
    } catch (e, st) {
      _talker.handle(e, st, 'Error fetching basketball profile');
    }
  }

  void updateDraft(BasketballProfile profile) => state = profile;

  Future<void> flush() async {
    final user = ref.read(authControllerProvider).value;
    if (user?.id == null) return;
    try {
      await _supabase
          .from('basketball_profile')
          .upsert({'user_id': user!.id!, ...state.toJson()})
          .timeout(const Duration(seconds: 5));
    } catch (e, st) {
      _failures.handle(
        e,
        st,
        logMessage: 'Error flushing basketball profile',
        resync: () => ref.invalidateSelf(),
      );
    }
  }
}

// ─── Badminton ────────────────────────────────────────────────────────────────

@riverpod
class BadmintonProfileController extends _$BadmintonProfileController {
  final _supabase = Supabase.instance.client;
  final _talker = Talker();
  late final _failures = WriteFailureHandler(ref);

  @override
  BadmintonProfile build() {
    final user = ref.watch(authControllerProvider).value;
    if (user?.id != null) _fetch(user!.id!);
    return const BadmintonProfile();
  }

  Future<void> _fetch(String userId) async {
    try {
      final response = await _supabase
          .from('badminton_profile')
          .select()
          .eq('user_id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));
      if (response != null && ref.mounted) {
        state = BadmintonProfile.fromJson(response);
      }
    } catch (e, st) {
      _talker.handle(e, st, 'Error fetching badminton profile');
    }
  }

  void updateDraft(BadmintonProfile profile) => state = profile;

  Future<void> flush() async {
    final user = ref.read(authControllerProvider).value;
    if (user?.id == null) return;
    try {
      await _supabase
          .from('badminton_profile')
          .upsert({'user_id': user!.id!, ...state.toJson()})
          .timeout(const Duration(seconds: 5));
    } catch (e, st) {
      _failures.handle(
        e,
        st,
        logMessage: 'Error flushing badminton profile',
        resync: () => ref.invalidateSelf(),
      );
    }
  }
}

// ─── Tennis ───────────────────────────────────────────────────────────────────

@riverpod
class TennisProfileController extends _$TennisProfileController {
  final _supabase = Supabase.instance.client;
  final _talker = Talker();
  late final _failures = WriteFailureHandler(ref);

  @override
  TennisProfile build() {
    final user = ref.watch(authControllerProvider).value;
    if (user?.id != null) _fetch(user!.id!);
    return const TennisProfile();
  }

  Future<void> _fetch(String userId) async {
    try {
      final response = await _supabase
          .from('tennis_profile')
          .select()
          .eq('user_id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));
      if (response != null && ref.mounted) {
        state = TennisProfile.fromJson(response);
      }
    } catch (e, st) {
      _talker.handle(e, st, 'Error fetching tennis profile');
    }
  }

  void updateDraft(TennisProfile profile) => state = profile;

  Future<void> flush() async {
    final user = ref.read(authControllerProvider).value;
    if (user?.id == null) return;
    try {
      await _supabase
          .from('tennis_profile')
          .upsert({'user_id': user!.id!, ...state.toJson()})
          .timeout(const Duration(seconds: 5));
    } catch (e, st) {
      _failures.handle(
        e,
        st,
        logMessage: 'Error flushing tennis profile',
        resync: () => ref.invalidateSelf(),
      );
    }
  }
}

// ─── Pickleball ───────────────────────────────────────────────────────────────

@riverpod
class PickleballProfileController extends _$PickleballProfileController {
  final _supabase = Supabase.instance.client;
  final _talker = Talker();
  late final _failures = WriteFailureHandler(ref);

  @override
  PickleballProfile build() {
    final user = ref.watch(authControllerProvider).value;
    if (user?.id != null) _fetch(user!.id!);
    return const PickleballProfile();
  }

  Future<void> _fetch(String userId) async {
    try {
      final response = await _supabase
          .from('pickleball_profile')
          .select()
          .eq('user_id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));
      if (response != null && ref.mounted) {
        state = PickleballProfile.fromJson(response);
      }
    } catch (e, st) {
      _talker.handle(e, st, 'Error fetching pickleball profile');
    }
  }

  void updateDraft(PickleballProfile profile) => state = profile;

  Future<void> flush() async {
    final user = ref.read(authControllerProvider).value;
    if (user?.id == null) return;
    try {
      await _supabase
          .from('pickleball_profile')
          .upsert({'user_id': user!.id!, ...state.toJson()})
          .timeout(const Duration(seconds: 5));
    } catch (e, st) {
      _failures.handle(
        e,
        st,
        logMessage: 'Error flushing pickleball profile',
        resync: () => ref.invalidateSelf(),
      );
    }
  }
}
