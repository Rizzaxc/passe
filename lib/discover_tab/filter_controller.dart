import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../auth/auth_controller.dart';
import '../core/feature_flags.dart';
import '../core/model/enum.dart';
import '../core/model/timeslot.dart';

part 'filter_controller.g.dart';

class FilterData {
  final String search;
  final City city;
  final Set<District> districts;
  final List<Timeslot> schedule;

  /// Professional-subtab only: which roles to show, each independently
  /// checked. Both checked by default. `setRoleVisible` refuses to empty
  /// this set — "show neither" isn't a real filter state.
  final Set<ProfessionalRole> visibleRoles;

  FilterData({
    this.search = '',
    this.city = City.hochiminh,
    this.districts = const {},
    this.schedule = const [],
    this.visibleRoles = ClientFeatureFlags.refereeFlow
        ? const {ProfessionalRole.coach, ProfessionalRole.referee}
        : const {ProfessionalRole.coach},
  });

  /// Equality over the fields that change what a feed returns —
  /// `visibleRoles` is a client-side view toggle, not a criterion.
  bool sameCriteriaAs(FilterData other) =>
      search == other.search &&
      city == other.city &&
      setEquals(districts, other.districts) &&
      listEquals(schedule, other.schedule);

  FilterData copyWith({
    String? search,
    City? city,
    Set<District>? districts,
    List<Timeslot>? schedule,
    Set<ProfessionalRole>? visibleRoles,
  }) {
    return FilterData(
      search: search ?? this.search,
      city: city ?? this.city,
      districts: districts ?? this.districts,
      schedule: schedule ?? this.schedule,
      visibleRoles: visibleRoles ?? this.visibleRoles,
    );
  }
}

@riverpod
class FilterState extends _$FilterState {
  @override
  FilterData build() {
    final user = ref.read(authControllerProvider).value;
    final playtime = user?.details?.playtime ?? [];
    final location = user?.details?.location;

    final city = (location?.city != null && location!.city != City.none)
        ? location.city!
        : City.hochiminh;

    final districts =
        location?.districts
            .map((id) => VietnamLocationData.instance.findDistrictById(id))
            .whereType<District>()
            .toSet() ??
        {};

    final seed = FilterData(
      city: city,
      districts: districts,
      schedule: List.of(playtime),
    );
    _seed = seed;
    return seed;
  }

  /// The profile-seeded starting point — what [reset] returns to and what
  /// [isActive] compares against.
  late FilterData _seed;

  /// Back to the profile seed, keeping the professional role toggle (that
  /// one is a view preference, not a search criterion).
  void reset() {
    state = _seed.copyWith(visibleRoles: state.visibleRoles);
  }

  void setFilter(String value) {
    state = state.copyWith(search: value);
  }

  void setCity(City city) {
    if (state.city != city) {
      state = state.copyWith(city: city, districts: {});
    }
  }

  static const maxDistricts = 6;
  static const maxTimeslots = 3;

  /// Returns true when the cap forced the oldest pick out, so the caller can
  /// say so instead of the selection silently changing under the user.
  bool setDistricts(Set<District> districts) {
    var dropped = false;
    while (districts.length > maxDistricts) {
      districts.remove(districts.first);
      dropped = true;
    }
    state = state.copyWith(districts: districts);
    return dropped;
  }

  /// See [setDistricts] for the return value.
  bool setSchedule(List<Timeslot> schedule) {
    var dropped = false;
    while (schedule.length > maxTimeslots) {
      schedule.removeAt(0);
      dropped = true;
    }
    state = state.copyWith(schedule: schedule);
    return dropped;
  }

  /// Checks/unchecks one role's checkbox. Only the professional subtab
  /// reads this field. Refuses to uncheck the last remaining role — at
  /// least one must stay visible.
  void setRoleVisible(ProfessionalRole role, bool visible) {
    final updated = Set<ProfessionalRole>.of(state.visibleRoles);
    if (visible) {
      updated.add(role);
    } else if (updated.length > 1) {
      updated.remove(role);
    }
    state = state.copyWith(visibleRoles: updated);
  }

  /// TODO: Send filter settings to server
  Future<void> onCommit() async {}
}

/// True when the user has narrowed the filter away from their profile seed.
/// Drives the dot on Discover's filter summary chip and the reset action.
@riverpod
bool filterIsActive(Ref ref) {
  final state = ref.watch(filterStateProvider);
  return !state.sameCriteriaAs(ref.read(filterStateProvider.notifier)._seed);
}
