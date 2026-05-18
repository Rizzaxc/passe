import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/auth_controller.dart';
import '../../../core/model/activity.dart';

part 'controller.g.dart';

@riverpod
class LobbyUpcomingController extends _$LobbyUpcomingController {
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
        .gte('start_time', now.toIso8601String())
        .order('start_time', ascending: true)
        .limit(3);

    return (response as List)
        .map((e) => Activity.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
