import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/auth_controller.dart';
import '../../../core/model/activity.dart';

part 'controller.g.dart';

@riverpod
class LobbyHistoryController extends _$LobbyHistoryController {
  final supabase = Supabase.instance.client;

  @override
  Future<List<Activity>> build(String lobbyId) async {
    final user = ref.watch(authControllerProvider).value;
    if (user == null || user.id == null) return [];

    final now = DateTime.now().toUtc();

    final response = await supabase
        .from('activity')
        .select()
        .eq('lobby_id', lobbyId)
        .eq('user_id', user.id!)
        .lt('start_time', now.toIso8601String())
        .order('start_time', ascending: false)
        .limit(10)
        .timeout(const Duration(seconds: 5));

    return (response as List)
        .map((e) => Activity.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
