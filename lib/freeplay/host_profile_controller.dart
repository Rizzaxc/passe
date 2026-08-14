import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'repository.dart';

part 'host_profile_controller.g.dart';

/// Reads the self-editable Host name through the same narrow table surface
/// used for saving it. The linked-Host RPC remains the source of identity and
/// the rest of the Host profile.
@riverpod
Future<String> myHostDisplayName(Ref ref, String hostId) async {
  final response = await Supabase.instance.client
      .from('freeplay_host')
      .select('display_name')
      .eq('id', hostId)
      .single()
      .timeout(const Duration(seconds: 5));
  return response['display_name'] as String? ?? '';
}

/// Commits the Host's public name independently from their account username.
/// RLS and column privileges limit the write to the caller's own Host row and
/// to `display_name` only.
@riverpod
class HostProfileEditController extends _$HostProfileEditController {
  @override
  bool build(String hostId) => false;

  Future<void> commit({required String displayName}) async {
    final keepAlive = ref.keepAlive();
    state = true;
    try {
      await Supabase.instance.client
          .from('freeplay_host')
          .update({'display_name': displayName})
          .eq('id', hostId)
          .timeout(const Duration(seconds: 5));

      ref.invalidate(myHostDisplayNameProvider(hostId));
      ref.invalidate(freeplayHostProfileProvider(hostId));
      ref.invalidate(freeplayHostOpenProvider(hostId));
      ref.invalidate(hostFreeplayProvider(false));
      ref.invalidate(hostFreeplayProvider(true));
      ref.invalidate(myFreeplayProvider(false));
      ref.invalidate(myFreeplayProvider(true));
      ref.invalidate(freeplayFeedProvider);
    } finally {
      state = false;
      keepAlive.close();
    }
  }
}
