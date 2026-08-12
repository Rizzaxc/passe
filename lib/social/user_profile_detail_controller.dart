import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../core/model/enum.dart';
import '../core/model/network.dart';
import '../core/model/sport_profile.dart';
import '../core/model/user_contact.dart';

part 'user_profile_detail_controller.g.dart';

/// Networks, industries, contact info, and the current context sport's
/// profile for another user — the data the Overview tab on `/user/:id` shows
/// read-only. Networks/industries/sport-profile tables carry `USING (true)`
/// SELECT policies, so those are just the same queries
/// `NetworkController`/`IndustryController`/`Soccer/…ProfileController`
/// already run for `auth.uid()` in `lib/profile_tab/`, parameterized by
/// whichever user is being viewed. [contact] is gated by `user_contact`'s own
/// RLS (friends / public / freeplay-host), so an empty result here just means
/// "not visible to me", not "not set" — never fetched from `auth.uid()`'s own
/// row, it's whatever the *viewed* [userId] is willing to expose. [sportProfile]
/// is `SoccerProfile` / `BasketballProfile` / `BadmintonProfile` /
/// `TennisProfile` / `PickleballProfile` depending on [Sport], or `null` for
/// `Sport.others` or when the user has no row for that sport yet.
class UserProfileDetail {
  final List<Network> networks;
  final List<Industry> industries;
  final UserContact contact;
  final Object? sportProfile;

  const UserProfileDetail({
    required this.networks,
    required this.industries,
    required this.contact,
    this.sportProfile,
  });
}

Future<List<Network>> _fetchNetworks(
  SupabaseClient supabase,
  String userId,
) async {
  final response = await supabase
      .from('user_network')
      .select('alumni, network(id, name, category, city)')
      .eq('user_id', userId)
      .timeout(const Duration(seconds: 5));

  return (response as List).map((data) {
    final networkData = data['network'] as Map<String, dynamic>;
    return Network(
      id: networkData['id'] as int,
      name: networkData['name'] as String,
      isAlumni: data['alumni'] as bool,
      category: NetworkCategory.fromString(networkData['category'] as String?),
      city: networkData['city'] != null
          ? City.values[networkData['city'] as int]
          : null,
    );
  }).toList();
}

Future<List<Industry>> _fetchIndustries(
  SupabaseClient supabase,
  String userId,
) async {
  final response = await supabase
      .from('user_industry')
      .select('industry_id')
      .eq('user_id', userId)
      .timeout(const Duration(seconds: 5));

  return (response as List)
      .map((data) => Industry.values[data['industry_id'] as int])
      .toList();
}

Future<UserContact> _fetchContact(
  SupabaseClient supabase,
  String userId,
) async {
  final response = await supabase
      .from('user_contact')
      .select('zalo, zalo_public')
      .eq('user_id', userId)
      .maybeSingle()
      .timeout(const Duration(seconds: 5));
  return response == null ? const UserContact() : UserContact.fromJson(response);
}

Future<Object?> _fetchSportProfile(
  SupabaseClient supabase,
  String userId,
  Sport sport,
) async {
  final table = switch (sport) {
    Sport.soccer => 'soccer_profile',
    Sport.basketball => 'basketball_profile',
    Sport.badminton => 'badminton_profile',
    Sport.tennis => 'tennis_profile',
    Sport.pickleball => 'pickleball_profile',
    Sport.others => null,
  };
  if (table == null) return null;

  final row = await supabase
      .from(table)
      .select()
      .eq('user_id', userId)
      .maybeSingle()
      .timeout(const Duration(seconds: 5));
  if (row == null) return null;

  return switch (sport) {
    Sport.soccer => SoccerProfile.fromJson(row),
    Sport.basketball => BasketballProfile.fromJson(row),
    Sport.badminton => BadmintonProfile.fromJson(row),
    Sport.tennis => TennisProfile.fromJson(row),
    Sport.pickleball => PickleballProfile.fromJson(row),
    Sport.others => null,
  };
}

@riverpod
Future<UserProfileDetail> userProfileDetail(
  Ref ref,
  String userId,
  Sport sport,
) async {
  final supabase = Supabase.instance.client;
  try {
    final results = await Future.wait([
      _fetchNetworks(supabase, userId),
      _fetchIndustries(supabase, userId),
      _fetchContact(supabase, userId),
      _fetchSportProfile(supabase, userId, sport),
    ]);
    return UserProfileDetail(
      networks: results[0] as List<Network>,
      industries: results[1] as List<Industry>,
      contact: results[2] as UserContact,
      sportProfile: results[3],
    );
  } catch (e, st) {
    Talker().handle(e, st, 'Error fetching user profile detail');
    rethrow;
  }
}
