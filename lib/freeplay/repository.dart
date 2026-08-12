import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_controller.dart';
import '../core/model/timeslot.dart';
import '../core/state/selected_sport_state.dart';
import '../home_tab/filter_controller.dart';
import 'model.dart';

const _rpcTimeout = Duration(seconds: 5);

final freeplayFeedProvider = FutureProvider.autoDispose<List<FreeplayActivity>>(
  (ref) async {
    final filter = ref.watch(filterStateProvider);
    final sport = ref.watch(selectedSportStateProvider).value;
    if (sport == null || sport.index == 0) return const [];
    final response = await Supabase.instance.client
        .rpc(
          'home_freeplay_data',
          params: {
            'p_sport_id': sport.index,
            'p_timeslots': Timeslot.listToJson(filter.schedule),
            'p_city': filter.city.dbIndex,
            'p_districts': filter.districts
                .map((district) => district.id)
                .toList(),
            'p_search': filter.search,
            'p_page_size': 20,
            'p_page_number': 1,
          },
        )
        .timeout(_rpcTimeout);
    return (response as List)
        .map((row) => FreeplayActivity.fromJson(row as Map<String, dynamic>))
        .toList();
  },
);

final freeplayDetailProvider = FutureProvider.autoDispose
    .family<FreeplayActivity?, String>((ref, id) async {
      final response = await Supabase.instance.client
          .rpc('freeplay_activity_detail_data', params: {'p_activity_id': id})
          .timeout(_rpcTimeout);
      final rows = response as List;
      return rows.isEmpty
          ? null
          : FreeplayActivity.fromJson(rows.first as Map<String, dynamic>);
    });

final myFreeplayProvider = FutureProvider.autoDispose
    .family<List<FreeplayActivity>, bool>((ref, history) async {
      final response = await Supabase.instance.client
          .rpc('freeplay_my_data', params: {'p_history': history})
          .timeout(_rpcTimeout);
      return (response as List).map((row) {
        final json = Map<String, dynamic>.from(row as Map);
        json['id'] = json['activity_id'];
        json['male_price'] = json['price_amount'];
        json['female_price'] = json['price_amount'];
        json['my_request_id'] = json['request_id'];
        json['my_request_status'] = json['request_status'];
        return FreeplayActivity.fromJson(json);
      }).toList();
    });

final linkedFreeplayHostProvider = FutureProvider<FreeplayHost?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  final response = await Supabase.instance.client
      .rpc('my_freeplay_host')
      .timeout(_rpcTimeout);
  final rows = response as List;
  return rows.isEmpty
      ? null
      : FreeplayHost.fromJson(rows.first as Map<String, dynamic>);
});

final freeplayHostProfileProvider = FutureProvider.autoDispose
    .family<FreeplayHost?, String>((ref, id) async {
      final response = await Supabase.instance.client
          .rpc('freeplay_host_profile_data', params: {'p_host_id': id})
          .timeout(_rpcTimeout);
      final rows = response as List;
      return rows.isEmpty
          ? null
          : FreeplayHost.fromJson(rows.first as Map<String, dynamic>);
    });

final freeplayHostOpenProvider = FutureProvider.autoDispose
    .family<List<FreeplayActivity>, String>((ref, id) async {
      final response = await Supabase.instance.client
          .rpc('freeplay_host_open_data', params: {'p_host_id': id})
          .timeout(_rpcTimeout);
      return (response as List)
          .map((row) => FreeplayActivity.fromJson(row as Map<String, dynamic>))
          .toList();
    });

final hostFreeplayProvider = FutureProvider.autoDispose
    .family<List<FreeplayActivity>, bool>((ref, history) async {
      final response = await Supabase.instance.client
          .rpc('freeplay_host_management_data', params: {'p_history': history})
          .timeout(_rpcTimeout);
      return (response as List)
          .map((row) => FreeplayActivity.fromJson(row as Map<String, dynamic>))
          .toList();
    });

final freeplayRequestsProvider = FutureProvider.autoDispose
    .family<List<FreeplayRequestItem>, String>((ref, id) async {
      final response = await Supabase.instance.client
          .rpc('freeplay_activity_requests', params: {'p_activity_id': id})
          .timeout(_rpcTimeout);
      return (response as List)
          .map(
            (row) => FreeplayRequestItem.fromJson(row as Map<String, dynamic>),
          )
          .toList();
    });

final freeplayChatProvider = FutureProvider.autoDispose
    .family<List<FreeplayChatMessage>, String>((ref, requestId) async {
      final response = await Supabase.instance.client
          .rpc('freeplay_chat_data', params: {'p_request_id': requestId})
          .timeout(_rpcTimeout);
      return (response as List)
          .map(
            (row) => FreeplayChatMessage.fromJson(row as Map<String, dynamic>),
          )
          .toList();
    });

final freeplayChatCounterpartZaloProvider = FutureProvider.autoDispose
    .family<String?, String>((ref, requestId) async {
      final response = await Supabase.instance.client
          .rpc(
            'freeplay_chat_counterpart_data',
            params: {'p_request_id': requestId},
          )
          .timeout(_rpcTimeout);
      final rows = response as List;
      if (rows.isEmpty) return null;
      final counterpartId =
          (rows.first as Map<String, dynamic>)['counterpart_id'] as String?;
      if (counterpartId == null) return null;
      // Whether this returns a row at all is governed by user_contact's own
      // RLS (friends-only, freeplay hosts public) — not re-checked here.
      final contact = await Supabase.instance.client
          .from('user_contact')
          .select('zalo')
          .eq('user_id', counterpartId)
          .maybeSingle()
          .timeout(_rpcTimeout);
      final zalo = contact?['zalo'] as String?;
      return zalo?.trim().isEmpty == true ? null : zalo;
    });

class FreeplayRepository {
  const FreeplayRepository();
  SupabaseClient get _client => Supabase.instance.client;

  Future<String> requestSeat(String activityId, {String? message}) async =>
      (await _client
              .rpc(
                'request_freeplay_seat',
                params: {
                  'p_activity_id': activityId,
                  'p_message': message?.trim().isEmpty == true
                      ? null
                      : message?.trim(),
                },
              )
              .timeout(_rpcTimeout))
          .toString();

  Future<void> cancelRequest(String requestId) => _client
      .rpc('cancel_freeplay_request', params: {'p_request_id': requestId})
      .timeout(_rpcTimeout);

  Future<void> respond(String requestId, bool accept) => _client
      .rpc(
        'respond_freeplay_request',
        params: {'p_request_id': requestId, 'p_accept': accept},
      )
      .timeout(_rpcTimeout);

  Future<void> sendMessage(String requestId, String body) => _client
      .rpc(
        'send_freeplay_message',
        params: {'p_request_id': requestId, 'p_body': body.trim()},
      )
      .timeout(_rpcTimeout);

  Future<void> sharePaymentInfo(String requestId) => _client
      .rpc('share_freeplay_payment_info', params: {'p_request_id': requestId})
      .timeout(_rpcTimeout);

  Future<String> create(Map<String, dynamic> params) async =>
      (await _client
              .rpc('create_freeplay_activity', params: params)
              .timeout(_rpcTimeout))
          .toString();

  Future<void> update(
    String activityId, {
    required int capacity,
    required String description,
    required List<String> skills,
  }) => _client
      .rpc(
        'edit_freeplay_listing',
        params: {
          'p_activity_id': activityId,
          'p_capacity': capacity,
          'p_description': description,
          'p_recommended_skills': skills,
        },
      )
      .timeout(_rpcTimeout);

  Future<void> setIntake(String activityId, bool closed) => _client
      .rpc(
        'set_freeplay_intake',
        params: {'p_activity_id': activityId, 'p_closed': closed},
      )
      .timeout(_rpcTimeout);

  Future<void> cancelActivity(String activityId) => _client
      .rpc('cancel_freeplay_activity', params: {'p_activity_id': activityId})
      .timeout(_rpcTimeout);
}

final freeplayRepositoryProvider = Provider<FreeplayRepository>(
  (ref) => const FreeplayRepository(),
);
