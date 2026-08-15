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
      .select('*, user!professional_linked_user_id_fkey(details)')
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

/// A professional's own Zalo — the same `user_contact` row they (or, for a
/// referee, presumably nobody yet) edit in user mode / pro mode, sourced by
/// a two-step lookup (`professional.linked_user_id` → `user_contact.zalo`)
/// rather than widening `home_professional_data`'s return shape. Readable
/// regardless of `zalo_public`/friendship — see
/// `schema/user_contact_professional_visibility.sql`. `null` when unlinked
/// or unset, which callers treat as "no Zalo button".
@riverpod
Future<String?> professionalZalo(Ref ref, String professionalId) async {
  final pro = await Supabase.instance.client
      .from('professional')
      .select('linked_user_id')
      .eq('id', professionalId)
      .maybeSingle()
      .timeout(const Duration(seconds: 5));
  final linkedUserId = pro?['linked_user_id'] as String?;
  if (linkedUserId == null) return null;

  final contact = await Supabase.instance.client
      .from('user_contact')
      .select('zalo')
      .eq('user_id', linkedUserId)
      .maybeSingle()
      .timeout(const Duration(seconds: 5));
  final zalo = contact?['zalo'] as String?;
  return zalo?.trim().isEmpty == true ? null : zalo;
}

/// Whether the signed-in user's linked professional profile is a **coach**
/// (as opposed to a referee). Pro mode branches on this: a coach runs courses,
/// a referee runs bookings.
@riverpod
Future<bool> isLinkedCoach(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return false;

  final response = await Supabase.instance.client
      .from('professional')
      .select('professional_role')
      .eq('linked_user_id', userId)
      .maybeSingle()
      .timeout(const Duration(seconds: 5));

  return response?['professional_role'] == 'coach';
}
