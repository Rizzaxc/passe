import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../auth/auth_controller.dart';
import '../core/achievement_evaluator.dart';
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

/// Why a picked video was dropped from the selection.
enum MediaRejectReason { tooLong, tooLarge }

/// A video that failed validation right after picking — the caller surfaces
/// [reason] as a toast; the file is simply not added to the selection.
class MediaRejected {
  final XFile file;
  final MediaRejectReason reason;

  const MediaRejected(this.file, this.reason);
}

/// A picked, validated (video only) item, ready to render in the compose
/// preview and to upload on submit.
class PreparedMedia {
  final XFile file;
  final bool isVideo;

  /// Video only — read right after picking so an over-length clip can be
  /// rejected before the user gets any further into the flow.
  final Duration? duration;

  /// Video only — a small poster-frame JPEG generated at pick time
  /// (`video_thumbnail`), uploaded alongside the video on submit and used as
  /// the carousel's placeholder before playback starts.
  final Uint8List? thumbnailBytes;

  const PreparedMedia({
    required this.file,
    required this.isVideo,
    this.duration,
    this.thumbnailBytes,
  });
}

/// Uploads the picked media, then creates the post.
///
/// Images (and video thumbnails) go to `<uid>/<random>.jpg` in the public
/// `wall_post` bucket; video goes to `<uid>/<random>.<ext>` in
/// `wall_post_video` (see schema/wall_post_video.sql for why they're split).
/// Paths are user-scoped rather than post-scoped because the upload happens
/// *before* the post row exists, and the storage policy can only check the
/// first path segment against `auth.uid()`.
@riverpod
class ComposePostController extends _$ComposePostController {
  @override
  void build() {}

  static const _maxMediaItems = 4;
  static const _maxVideoDuration = Duration(seconds: 60);
  // Matches the wall_post_video bucket's file_size_limit — this is the fast,
  // pre-upload check; the bucket limit is defense-in-depth against a
  // bypassed client, not the primary gate.
  static const _maxVideoBytes = 25 * 1024 * 1024;

  /// One native picker, mixed photo/video, up to 4 total — matches the OS's
  /// own multi-select UI. Compression matters more for feed load time than
  /// any bucket or CDN choice, so `maxWidth`/`imageQuality` apply to the
  /// picked images (videos are returned as picked — no re-encoding, see the
  /// size/duration checks in [prepareMedia]).
  Future<List<XFile>> pickMedia() async {
    final picked = await ImagePicker().pickMultipleMedia(
      maxWidth: 1440,
      imageQuality: 80,
      limit: _maxMediaItems,
    );
    return picked.take(_maxMediaItems).toList();
  }

  bool isVideoFile(XFile file) {
    final mime = file.mimeType;
    if (mime != null) return mime.startsWith('video/');
    final path = file.path.toLowerCase();
    return path.endsWith('.mp4') ||
        path.endsWith('.mov') ||
        path.endsWith('.m4v') ||
        path.endsWith('.avi') ||
        path.endsWith('.3gp') ||
        path.endsWith('.webm');
  }

  /// Classifies each picked file and, for video, validates duration/size and
  /// generates a poster-frame thumbnail — everything the compose UI and
  /// submit() need, computed once right after picking rather than re-derived
  /// later.
  Future<({List<PreparedMedia> accepted, List<MediaRejected> rejected})>
      prepareMedia(List<XFile> files) async {
    final accepted = <PreparedMedia>[];
    final rejected = <MediaRejected>[];

    for (final file in files) {
      if (!isVideoFile(file)) {
        accepted.add(PreparedMedia(file: file, isVideo: false));
        continue;
      }

      final duration = await _videoDuration(file);
      if (duration == null || duration > _maxVideoDuration) {
        rejected.add(MediaRejected(file, MediaRejectReason.tooLong));
        continue;
      }
      final size = await file.length();
      if (size > _maxVideoBytes) {
        rejected.add(MediaRejected(file, MediaRejectReason.tooLarge));
        continue;
      }

      accepted.add(PreparedMedia(
        file: file,
        isVideo: true,
        duration: duration,
        thumbnailBytes: await _videoThumbnail(file.path),
      ));
    }

    return (accepted: accepted, rejected: rejected);
  }

  Future<Duration?> _videoDuration(XFile file) async {
    final controller = VideoPlayerController.file(File(file.path));
    try {
      await controller.initialize().timeout(const Duration(seconds: 5));
      return controller.value.duration;
    } catch (_) {
      return null;
    } finally {
      await controller.dispose();
    }
  }

  Future<Uint8List?> _videoThumbnail(String path) async {
    try {
      return await VideoThumbnail.thumbnailData(
        video: path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 480,
        quality: 60,
      ).timeout(const Duration(seconds: 5));
    } catch (_) {
      return null;
    }
  }

  /// Video keeps its picked container format (no re-encoding — see
  /// compose_controller's header) so the upload's declared content-type has
  /// to match what the bytes actually are, unlike images which are always
  /// re-compressed to JPEG by the picker's `imageQuality` option above.
  (String ext, String contentType) _videoFormat(XFile file) {
    final mime = file.mimeType;
    if (mime == 'video/quicktime') return ('mov', 'video/quicktime');
    if (mime == 'video/mp4') return ('mp4', 'video/mp4');
    if (file.path.toLowerCase().endsWith('.mov')) {
      return ('mov', 'video/quicktime');
    }
    return ('mp4', 'video/mp4');
  }

  Future<String> submit({
    String? activityId,
    String? bookingId,
    required List<PreparedMedia> media,
    String? caption,
    required int ttlDays,
    required List<String> taggedUserIds,
  }) async {
    final supabase = Supabase.instance.client;
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) throw StateError('not signed in');
    if (media.isEmpty || media.length > _maxMediaItems) {
      throw ArgumentError('a post needs 1-4 media items');
    }

    final random = Random();
    final uploaded = <(String bucket, String path)>[];

    Future<String> upload(
      String bucket,
      Uint8List bytes,
      String ext,
      String contentType,
    ) async {
      final name =
          '${DateTime.now().microsecondsSinceEpoch}_${random.nextInt(1 << 32)}.$ext';
      final path = '$userId/$name';
      await supabase.storage
          .from(bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: contentType),
          )
          .timeout(const Duration(seconds: 5));
      uploaded.add((bucket, path));
      return path;
    }

    try {
      final mediaJson = <Map<String, dynamic>>[];
      for (final item in media) {
        if (item.isVideo) {
          final (ext, contentType) = _videoFormat(item.file);
          final videoPath = await upload(
            'wall_post_video',
            await item.file.readAsBytes(),
            ext,
            contentType,
          );
          final thumbBytes = item.thumbnailBytes;
          final thumbPath = thumbBytes == null
              ? null
              : await upload('wall_post', thumbBytes, 'jpg', 'image/jpeg');
          mediaJson.add(WallPostMedia(
            type: WallPostMediaType.video,
            path: videoPath,
            durationMs: item.duration?.inMilliseconds,
            thumbnailPath: thumbPath,
          ).toJson());
        } else {
          final path = await upload(
            'wall_post',
            await item.file.readAsBytes(),
            'jpg',
            'image/jpeg',
          );
          mediaJson.add(
            WallPostMedia(type: WallPostMediaType.image, path: path).toJson(),
          );
        }
      }

      final id = await supabase.rpc('create_wall_post', params: {
        'p_activity_id': activityId,
        'p_booking_id': bookingId,
        'p_media': mediaJson,
        'p_caption': caption,
        'p_ttl_days': ttlDays,
        'p_tagged_users': taggedUserIds,
      }).timeout(const Duration(seconds: 5));

      ref.invalidate(wallFeedControllerProvider);
      ref.invalidate(postableSessionsProvider);
      await evaluateAchievements(ref, userId);
      return id as String;
    } catch (_) {
      // The files are already in their buckets but no post owns them. Queue
      // them for the same GC pass the TTL sweep uses rather than leaving
      // orphans nothing will ever collect.
      await _abandonUploads(uploaded);
      rethrow;
    }
  }

  Future<void> _abandonUploads(List<(String bucket, String path)> uploaded) async {
    final byBucket = <String, List<String>>{};
    for (final (bucket, path) in uploaded) {
      byBucket.putIfAbsent(bucket, () => []).add(path);
    }
    for (final entry in byBucket.entries) {
      try {
        await Supabase.instance.client.storage
            .from(entry.key)
            .remove(entry.value)
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        // Best effort — a failed cleanup must not mask the original error.
      }
    }
  }
}
