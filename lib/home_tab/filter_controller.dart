import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../auth/auth_controller.dart';
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
    this.visibleRoles = const {
      ProfessionalRole.coach,
      ProfessionalRole.referee,
    },
  });

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

    return FilterData(
      city: city,
      districts: districts,
      schedule: List.of(playtime),
    );
  }

  void setFilter(String value) {
    state = state.copyWith(search: value);
  }

  void setCity(City city) {
    if (state.city != city) {
      state = state.copyWith(city: city, districts: {});
    }
  }

  void setDistricts(Set<District> districts) {
    while (districts.length > 6) {
      districts.remove(districts.first);
    }
    state = state.copyWith(districts: districts);
  }

  void setSchedule(List<Timeslot> schedule) {
    while (schedule.length > 3) {
      schedule.removeAt(0);
    }
    state = state.copyWith(schedule: schedule);
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
