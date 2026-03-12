import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/state/selected_sport_state.dart';
import '../filter_controller.dart';

part 'feed_controller.g.dart';

@riverpod
class ChallengerFeed extends _$ChallengerFeed {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final filter = ref.watch(filterStateProvider);
    final sport = ref.watch(selectedSportStateProvider).value;

    if (sport == null) return [];

    final _ = filter;
    return [];
  }
}