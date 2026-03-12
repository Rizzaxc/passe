import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/state/selected_sport_state.dart';
import '../filter_controller.dart';

part 'feed_controller.g.dart';

@riverpod
class ProfessionalFeed extends _$ProfessionalFeed {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final filter = ref.watch(filterStateProvider);
    final sport = ref.watch(selectedSportStateProvider).value;

    if (sport == null) return [];

    // TODO: call get_professionals with sport.index, location, timeslots
    final _ = filter;
    return [];
  }
}
