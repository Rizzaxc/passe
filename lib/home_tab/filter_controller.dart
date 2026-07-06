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

  /// Professional-subtab only: narrow the discovery feed to a single role.
  /// `null` = show both coaches and referees (the default).
  final ProfessionalRole? role;

  FilterData({
    this.search = '',
    this.city = City.hochiminh,
    this.districts = const {},
    this.schedule = const [],
    this.role,
  });

  FilterData copyWith({
    String? search,
    City? city,
    Set<District>? districts,
    List<Timeslot>? schedule,
    ProfessionalRole? role,
    bool clearRole = false,
  }) {
    return FilterData(
      search: search ?? this.search,
      city: city ?? this.city,
      districts: districts ?? this.districts,
      schedule: schedule ?? this.schedule,
      role: clearRole ? null : (role ?? this.role),
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

    final districts = location?.districts
            .map((id) => VietnamLocationData.instance.findDistrictById(id))
            .whereType<District>()
            .toSet() ??
        {};

    return FilterData(city: city, districts: districts, schedule: List.of(playtime));
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
    while (districts.length > 3) {
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

  /// `null` clears the role filter (both roles shown). Only the professional
  /// subtab reads this field.
  void setRole(ProfessionalRole? role) {
    state = role == null
        ? state.copyWith(clearRole: true)
        : state.copyWith(role: role);
  }

  /// TODO: Send filter settings to server
  Future<void> onCommit() async {
  }
}
