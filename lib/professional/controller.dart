import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_controller.dart';
import '../core/model/professional_feed_item.dart';

part 'controller.g.dart';

/// Fetches a single professional by id from the `professional` table.
///
/// Used by [ProfessionalDetailPage] when navigation arrives without a
/// preloaded [ProfessionalFeedItem] (e.g. a deep-link, a push notif, or
/// a place that hasn't fetched the row yet). Callers that already have
/// the model should pass it as `$extra` to skip this round-trip.
@riverpod
Future<ProfessionalFeedItem> professionalById(Ref ref, String id) async {
  final response = await Supabase.instance.client
      .from('professional')
      .select()
      .eq('id', id)
      .single()
      .timeout(const Duration(seconds: 5));

  return ProfessionalFeedItem.fromJson(response);
}

/// The signed-in user's own `professional.id`, if their account is linked
/// (`professional.linked_user_id = auth.uid()`) — `null` for a regular
/// player. Set out-of-app (admin/DB-direct), never self-registered. Gates
/// whether the pro-mode toggle appears at all, and scopes every pro-mode
/// query.
@riverpod
Future<String?> linkedProfessionalId(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final response = await Supabase.instance.client
      .from('professional')
      .select('id')
      .eq('linked_user_id', userId)
      .maybeSingle()
      .timeout(const Duration(seconds: 5));

  return response?['id'] as String?;
}
