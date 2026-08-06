/// A wall post as returned by `wall_feed_data` / `user_wall_data`.
///
/// Plain class with a manual `fromJson`, matching the sibling feed models
/// (`LobbyFeedItem`, `ProfessionalFeedItem`) rather than freezed — these are
/// read-only projections of an RPC row shape, never persisted or copied, so
/// codegen buys nothing here.
///
/// Note what is **not** a foreign key: [sourceLabel], [sourceStartTime] and
/// [sourceVenueName] are snapshotted onto the post at creation. The activity
/// this post came from may have been deleted since (`expire_past_activities()`
/// sweeps past unconfirmed ones); the card still renders correctly because it
/// never reads the activity.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

class WallPostTag {
  final String userId;
  final String username;
  final String tagNumber;

  const WallPostTag({
    required this.userId,
    required this.username,
    required this.tagNumber,
  });

  factory WallPostTag.fromJson(Map<String, dynamic> json) => WallPostTag(
        userId: json['user_id'] as String,
        username: json['username'] as String? ?? '',
        tagNumber: json['tag_number'] as String? ?? '0000',
      );
}

enum WallPostMediaType {
  image,
  video;

  static WallPostMediaType fromJson(String value) =>
      value == 'video' ? WallPostMediaType.video : WallPostMediaType.image;

  String toJson() => name;
}

/// One image or video in a post's carousel (1-4 per post, mixed freely,
/// order = display order). Mirrors the `media` jsonb shape enforced
/// server-side by `fn_valid_wall_post_media` (schema/wall_post_video.sql) —
/// change one, change both.
class WallPostMedia {
  final WallPostMediaType type;
  final String path;

  /// Video only. Self-reported by the client at pick time — nothing
  /// server-side actually probes the file (see fn_valid_wall_post_media).
  final int? durationMs;

  /// Video only. A small poster-frame JPEG uploaded alongside the video,
  /// generated client-side at compose time (`video_thumbnail`). Lives in the
  /// `wall_post` bucket like a regular photo, not `wall_post_video`.
  final String? thumbnailPath;

  const WallPostMedia({
    required this.type,
    required this.path,
    this.durationMs,
    this.thumbnailPath,
  });

  bool get isVideo => type == WallPostMediaType.video;

  /// Public URL for the media itself. Images and video thumbnails live in
  /// the `wall_post` bucket; video files live in `wall_post_video` — both
  /// buckets are public with unguessable UUID paths (see schema/wall_post.sql
  /// and schema/wall_post_video.sql for why).
  String get url => Supabase.instance.client.storage
      .from(isVideo ? 'wall_post_video' : 'wall_post')
      .getPublicUrl(path);

  String? get thumbnailUrl => thumbnailPath == null
      ? null
      : Supabase.instance.client.storage
          .from('wall_post')
          .getPublicUrl(thumbnailPath!);

  factory WallPostMedia.fromJson(Map<String, dynamic> json) => WallPostMedia(
        type: WallPostMediaType.fromJson(json['type'] as String? ?? 'image'),
        path: json['path'] as String? ?? '',
        durationMs: (json['duration_ms'] as num?)?.toInt(),
        thumbnailPath: json['thumbnail_path'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'type': type.toJson(),
        'path': path,
        if (durationMs != null) 'duration_ms': durationMs,
        if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
      };
}

class WallPost {
  final String id;
  final String authorId;
  final String authorUsername;
  final String authorTagNumber;
  final String? authorGeneratedAvatar;

  final int sportId;
  final String? lobbyId;

  /// The lobby's name, or the coach's display name for a lesson.
  final String? sourceLabel;
  final DateTime sourceStartTime;
  final String? sourceVenueName;

  final String? caption;
  final List<WallPostMedia> media;
  final DateTime createdAt;
  final DateTime expiresAt;

  final List<WallPostTag> tags;

  /// emoji → count.
  final Map<String, int> reactions;

  /// The viewer's own reaction, if any.
  final String? myReaction;

  const WallPost({
    required this.id,
    required this.authorId,
    required this.authorUsername,
    required this.authorTagNumber,
    required this.sportId,
    required this.sourceStartTime,
    required this.media,
    required this.createdAt,
    required this.expiresAt,
    required this.tags,
    required this.reactions,
    this.authorGeneratedAvatar,
    this.lobbyId,
    this.sourceLabel,
    this.sourceVenueName,
    this.caption,
    this.myReaction,
  });

  String get authorHandle => '$authorUsername#$authorTagNumber';

  factory WallPost.fromJson(Map<String, dynamic> json) {
    final details = json['author_details'] as Map<String, dynamic>?;
    final rawReactions = json['reactions'] as Map<String, dynamic>? ?? const {};

    return WallPost(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      authorUsername: json['author_username'] as String? ?? '',
      authorTagNumber: json['author_tag_number'] as String? ?? '0000',
      authorGeneratedAvatar: details?['generatedAvatar'] as String?,
      sportId: (json['sport_id'] as num?)?.toInt() ?? 0,
      lobbyId: json['lobby_id'] as String?,
      sourceLabel: json['source_label'] as String?,
      sourceStartTime:
          DateTime.tryParse(json['source_start_time'] as String? ?? '')
                  ?.toLocal() ??
              DateTime.now(),
      sourceVenueName: json['source_venue_name'] as String?,
      caption: json['caption'] as String?,
      media: (json['media'] as List?)
              ?.map((e) => WallPostMedia.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
      expiresAt:
          DateTime.tryParse(json['expires_at'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
      tags: (json['tags'] as List?)
              ?.map((e) => WallPostTag.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      reactions: {
        for (final e in rawReactions.entries)
          e.key: (e.value as num?)?.toInt() ?? 0,
      },
      myReaction: json['my_reaction'] as String?,
    );
  }
}

/// A session the composer is allowed to hook a post to (`postable_activities`).
class PostableSession {
  final String? activityId;
  final String? bookingId;
  final int sportId;
  final String? lobbyId;
  final String? sourceLabel;
  final DateTime startTime;
  final String? venueName;
  final bool alreadyPosted;

  const PostableSession({
    required this.sportId,
    required this.startTime,
    required this.alreadyPosted,
    this.activityId,
    this.bookingId,
    this.lobbyId,
    this.sourceLabel,
    this.venueName,
  });

  bool get isLesson => bookingId != null;

  factory PostableSession.fromJson(Map<String, dynamic> json) =>
      PostableSession(
        activityId: json['activity_id'] as String?,
        bookingId: json['booking_id'] as String?,
        sportId: (json['sport_id'] as num?)?.toInt() ?? 0,
        lobbyId: json['lobby_id'] as String?,
        sourceLabel: json['source_label'] as String?,
        startTime:
            DateTime.tryParse(json['start_time'] as String? ?? '')?.toLocal() ??
                DateTime.now(),
        venueName: json['venue_name'] as String?,
        alreadyPosted: json['already_posted'] as bool? ?? false,
      );
}
