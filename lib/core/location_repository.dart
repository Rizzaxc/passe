import 'package:supabase_flutter/supabase_flutter.dart';

import 'model/location.dart';

/// Resolves a location field's current draft into a real `location_id`.
///
/// If [pickedId] is set (the user selected an existing location), it's
/// returned as-is. Otherwise, if [freeAddress] carries a non-empty name (the
/// user typed a manual entry instead), this silently creates a shared,
/// unverified `location` row via the `create_location` RPC and returns its
/// id — no toast, no "you added a location" messaging, indistinguishable
/// from picking an existing one. Returns null if neither is set.
Future<String?> resolveLocationId({
  String? pickedId,
  Map<String, String?>? freeAddress,
}) async {
  if (pickedId != null && pickedId.isNotEmpty) return pickedId;

  final name = freeAddress?['locationName']?.trim();
  if (name == null || name.isEmpty) return null;

  final response = await Supabase.instance.client
      .rpc(
        'create_location',
        params: {
          'p_name': name,
          'p_street_number': freeAddress?['streetNumber'],
          'p_street_name': freeAddress?['streetName'],
          'p_district': freeAddress?['district'],
          'p_city': freeAddress?['city'],
          'p_city_cluster': freeAddress?['cityCluster'] == null
              ? null
              : int.tryParse(freeAddress!['cityCluster']!),
        },
      )
      .timeout(const Duration(seconds: 5));

  return Location.fromJson(response as Map<String, dynamic>).id;
}
