import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/model/professional_feed_item.dart';
import '../../core/state/selected_sport_state.dart';
import '../filter_controller.dart';

part 'feed_controller.g.dart';

@riverpod
class ProfessionalFeed extends _$ProfessionalFeed {
  @override
  Future<List<ProfessionalFeedItem>> build() async {
    final sport = ref.watch(selectedSportStateProvider.select((v) => v.value));
    ref.watch(filterStateProvider); // rebuild when filter changes
    if (sport == null) return [];

    final response = await Supabase.instance.client
        .from('professional')
        .select()
        .contains('sports', [sport.index])
        .order('average_rating', ascending: false)
        .timeout(const Duration(seconds: 5));

    return (response as List)
        .map((e) => ProfessionalFeedItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
