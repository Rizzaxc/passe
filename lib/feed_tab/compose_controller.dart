import 'dart:math';

import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_controller.dart';
import '../core/model/wall_post.dart';
import 'feed_controller.dart';

part 'compose_controller.g.dart';

/// Sessions the caller may hook a post to: lobby activities from the last 7
/// days they RSVP'd `going` to, plus their coach lessons in the same window.
/// Comes straight from `postable_activities()` so the picker can never offer
/// something `create_wall_post` would then reject.
@riverpod
Future<List<PostableSession>> postableSessions(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];

  final rows = await Supabase.instance.client
      .rpc('postable_activities')
      .timeout(const Duration(seconds: 5));

  return (rows as List)
      .map((r) => PostableSession.fromJson(r as Map<String, dynamic>))
      .toList();
}

/// Someone the composer may tag — the session's attendees and lobby members
/// (attendees first). Mirrors the server-side tag guard.
class TaggableUser {
  final String userId;
  final String username;
  final String tagNumber;
  final String? generatedAvatar;

  /// True when they RSVP'd `going`; false when they're only a lobby member.
  /// Tagging absentees is intentional, so both are offered — this just orders
  /// and labels them.
  final bool attended;

  const TaggableUser({
    required this.userId,
    required this.username,
    required this.tagNumber,
    required this.attended,
    this.generatedAvatar,
  });

  factory TaggableUser.fromJson(Map<String, dynamic> json) {
    final details = json['details'] as Map<String, dynamic>?;
    return TaggableUser(
      userId: json['user_id'] as String,
      username: json['username'] as String? ?? '',
      tagNumber: json['tag_number'] as String? ?? '0000',
      generatedAvatar: details?['generatedAvatar'] as String?,
      attended: json['attended'] as bool? ?? false,
    );
  }
}

@riverpod
Future<List<TaggableUser>> taggableUsers(
  Ref ref, {
  String? activityId,
  String? bookingId,
}) async {
  final rows = await Supabase.instance.client.rpc('taggable_users', params: {
    'p_activity_id': activityId,
    'p_booking_id': bookingId,
  }).timeout(const Duration(seconds: 5));

  return (rows as List)
      .map((r) => TaggableUser.fromJson(r as Map<String, dynamic>))
      .toList();
}

/// Uploads the picked images, then creates the post.
///
/// Images go to `<uid>/<random>.jpg` in the public `wall_post` bucket — the
/// path is user-scoped rather than post-scoped because the upload happens
/// *before* the post row exists, and the storage policy can only check the
/// first path segment against `auth.uid()`.
@riverpod
class ComposePostController extends _$ComposePostController {
  @override
  void build() {}

  static const _maxImages = 4;

  /// Compression matters more for feed load time than any bucket or CDN
  /// choice, so this is where the real win is — a 12MP phone photo is ~4MB
  /// raw and ~250KB at these settings.
  Future<List<XFile>> pickImages() async {
    final picked = await ImagePicker().pickMultiImage(
      maxWidth: 1440,
      imageQuality: 80,
      limit: _maxImages,
    );
    return picked.take(_maxImages).toList();
  }

  Future<String> submit({
    String? activityId,
    String? bookingId,
    required List<XFile> images,
    String? caption,
    required int ttlDays,
    required List<String> taggedUserIds,
  }) async {
    final supabase = Supabase.instance.client;
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) throw StateError('not signed in');
    if (images.isEmpty || images.length > _maxImages) {
      throw ArgumentError('a post needs 1-4 images');
    }

    final random = Random();
    final paths = <String>[];

    for (final image in images) {
      final bytes = await image.readAsBytes();
      final name =
          '${DateTime.now().microsecondsSinceEpoch}_${random.nextInt(1 << 32)}.jpg';
      final path = '$userId/$name';

      await supabase.storage
          .from('wall_post')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          )
          .timeout(const Duration(seconds: 5));

      paths.add(path);
    }

    try {
      final id = await supabase.rpc('create_wall_post', params: {
        'p_activity_id': activityId,
        'p_booking_id': bookingId,
        'p_image_paths': paths,
        'p_caption': caption,
        'p_ttl_days': ttlDays,
        'p_tagged_users': taggedUserIds,
      }).timeout(const Duration(seconds: 5));

      ref.invalidate(wallFeedControllerProvider);
      ref.invalidate(postableSessionsProvider);
      return id as String;
    } catch (_) {
      // The images are already in the bucket but no post owns them. Queue them
      // for the same GC pass the TTL sweep uses rather than leaving orphans
      // nothing will ever collect.
      await _abandonUploads(paths);
      rethrow;
    }
  }

  Future<void> _abandonUploads(List<String> paths) async {
    try {
      await Supabase.instance.client.storage
          .from('wall_post')
          .remove(paths)
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Best effort — a failed cleanup must not mask the original error.
    }
  }
}
