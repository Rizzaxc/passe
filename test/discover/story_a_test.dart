import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:passe/core/model/enum.dart';
import 'package:passe/core/model/mmr_tier.dart';
import 'package:passe/core/model/timeslot.dart';
import 'package:passe/discover_tab/filter.dart';
import 'package:passe/router.dart';

void main() {
  group('MmrTier.fromMmr', () {
    test('bands sit halfway between the elo seeds', () {
      expect(MmrTier.fromMmr(700), MmrTier.newcomer);
      expect(MmrTier.fromMmr(799), MmrTier.newcomer);
      expect(MmrTier.fromMmr(800), MmrTier.weak);
      expect(MmrTier.fromMmr(1100), MmrTier.average);
      expect(MmrTier.fromMmr(1399), MmrTier.good);
      expect(MmrTier.fromMmr(1500), MmrTier.strong);
      expect(MmrTier.strong.level, 5);
    });
  });

  group('FilterData', () {
    final slot = Timeslot(DayOfWeek.tuesday, DayChunk.night);

    test('sameCriteriaAs ignores the role view toggle', () {
      final a = FilterData(schedule: [slot]);
      final b = FilterData(schedule: [slot], visibleRoles: const {});
      expect(a.sameCriteriaAs(b), isTrue);
      expect(a.sameCriteriaAs(a.copyWith(search: 'x')), isFalse);
    });
  });

  group('resolveLandingLocation', () {
    const teammates = '/discover/teammate';
    test('guests and lobby-less players land on Teammates', () {
      expect(
        resolveLandingLocation(
          isGuest: true,
          hasLobby: const AsyncLoading(),
          feedUnread: const AsyncLoading(),
        ),
        startsWith(teammates),
      );
      expect(
        resolveLandingLocation(
          isGuest: false,
          hasLobby: const AsyncData(false),
          feedUnread: const AsyncData(true),
        ),
        startsWith(teammates),
      );
    });

    test('members keep the Feed/Manage behaviour; errors fail to Manage', () {
      expect(
        resolveLandingLocation(
          isGuest: false,
          hasLobby: const AsyncData(true),
          feedUnread: const AsyncData(false),
        ),
        const ManageRoute().location,
      );
      expect(
        resolveLandingLocation(
          isGuest: false,
          hasLobby: AsyncError('x', StackTrace.empty),
          feedUnread: const AsyncData(true),
        ),
        const FeedRoute().location,
      );
      expect(
        resolveLandingLocation(
          isGuest: false,
          hasLobby: const AsyncLoading(),
          feedUnread: const AsyncData(true),
        ),
        const SplashRoute().location,
      );
    });
  });
}
