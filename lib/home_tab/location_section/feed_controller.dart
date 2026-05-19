import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/model/enum.dart';
import '../../core/model/location.dart';
import '../filter_controller.dart';

part 'feed_controller.g.dart';

@riverpod
class LocationFeed extends _$LocationFeed {
  @override
  Future<List<Location>> build() async {
    final filter = ref.watch(filterStateProvider);

    if (filter.search.isNotEmpty) {
      final response = await Supabase.instance.client
          .rpc('search_locations', params: {'search_term': filter.search})
          .timeout(const Duration(seconds: 5));
      return (response as List)
          .map((e) => Location.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    var query = Supabase.instance.client.from('location').select();

    if (filter.city != City.none) {
      query = query.eq('city_cluster', filter.city.dbIndex);
    }

    final response = await query.limit(40).timeout(const Duration(seconds: 5));
    return (response as List)
        .map((e) => Location.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
