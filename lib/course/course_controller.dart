import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_controller.dart';
import 'model.dart';

part 'course_controller.g.dart';

const _rpcTimeout = Duration(seconds: 5);

/// The signed-in user's courses and coach inquiries (`my_courses_data`).
///
/// Includes threads where they're only `inquiring` — messaging a coach is the
/// first step of the same flow, not a separate inbox.
@riverpod
Future<List<CourseSummary>> myCourses(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final response = await Supabase.instance.client
      .rpc('my_courses_data')
      .timeout(_rpcTimeout);
  return (response as List)
      .map((row) => CourseSummary.fromJson(row as Map<String, dynamic>))
      .toList();
}

/// The coach-side inbox (`pro_courses_data`) — same rows from the other end,
/// carrying the coach's to-do counts (pending proposals, unwritten reports).
@riverpod
Future<List<CourseSummary>> proCourses(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final response = await Supabase.instance.client
      .rpc('pro_courses_data')
      .timeout(_rpcTimeout);
  return (response as List)
      .map((row) => CourseSummary.fromJson(row as Map<String, dynamic>))
      .toList();
}

/// Read-only fast path for "Nhắn tin": does the caller already have a live
/// (inquiring or enrolled) thread with this coach for this sport? Lets a
/// repeat tap skip straight to the existing course instead of reopening the
/// compose sheet. Null means no thread exists yet.
@riverpod
Future<String?> courseWithCoach(
  Ref ref,
  String professionalId,
  int sportId,
) async {
  final response = await Supabase.instance.client
      .rpc(
        'find_course_with_coach',
        params: {'p_professional_id': professionalId, 'p_sport_id': sportId},
      )
      .timeout(_rpcTimeout);
  return response as String?;
}

@riverpod
Future<CourseDetail> courseDetail(Ref ref, String courseId) async {
  final response = await Supabase.instance.client
      .rpc('course_detail_data', params: {'p_course_id': courseId})
      .timeout(_rpcTimeout);
  final rows = response as List;
  if (rows.isEmpty) throw StateError('course not found');
  return CourseDetail.fromJson(rows.first as Map<String, dynamic>);
}

/// The coach's own diary clash check, used to warn (never block) when
/// scheduling or approving. Returns times only — deliberately nothing that
/// would tell a student who else their coach teaches.
@riverpod
Future<bool> hasCourseConflict(
  Ref ref,
  String professionalId,
  DateTime start,
  DateTime end,
) async {
  final response = await Supabase.instance.client
      .rpc(
        'course_activity_conflicts',
        params: {
          'p_professional_id': professionalId,
          'p_start': start.toUtc().toIso8601String(),
          'p_end': end.toUtc().toIso8601String(),
        },
      )
      .timeout(_rpcTimeout);
  return (response as List).isNotEmpty;
}

/// Every write in the course subsystem. One controller rather than several so
/// callers only have to invalidate one thing after a mutation.
@riverpod
class CourseActionController extends _$CourseActionController {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  bool build() => false; // in-flight flag

  // Most callers (course_detail_page.dart, course_sheets.dart) `ref.watch`
  // this controller for its busy flag, which incidentally keeps it alive
  // across the mutation's async gap. `startInquiry` is called from the coach
  // profile page instead, which has no reason to watch a course-specific busy
  // state — nothing keeps this autoDispose provider alive there, so it could
  // get torn down the instant `action()` yields. The `finally` block's
  // `state = false` then throws on a disposed Ref *after* the write already
  // landed, surfacing as a spurious error toast on top of a mutation that
  // actually succeeded (same hazard as `postPersonalAction` in
  // lobby_section/activity/feed_controller.dart). `ref.keepAlive()` here
  // covers every caller uniformly rather than special-casing the one that
  // happens to lack a watcher today.
  Future<T> _run<T>(Future<T> Function() action, {String? courseId}) async {
    final keepAliveLink = ref.keepAlive();
    state = true;
    try {
      final result = await action();
      ref.invalidate(myCoursesProvider);
      ref.invalidate(proCoursesProvider);
      // Also the "do I already have a thread with this coach?" fast path.
      // Without it, `leave`/`endCourse` left a cached course id behind and the
      // coach profile's "Nhắn tin" would route straight back into the course
      // the user had just left, for as long as that provider stayed alive.
      ref.invalidate(courseWithCoachProvider);
      if (courseId != null) ref.invalidate(courseDetailProvider(courseId));
      return result;
    } finally {
      state = false;
      keepAliveLink.close();
    }
  }

  /// Actually messaging a coach: creates the course/conversation on first
  /// contact and sends the first message atomically (`message_coach`). If
  /// the student never sends anything, nothing was ever created server-side
  /// — the inquiry is ephemeral until this is called. Idempotent: a second
  /// message to the same coach posts into the existing thread rather than
  /// duplicating it.
  Future<String> messageCoach(
    String professionalId,
    int sportId,
    String body,
  ) => _run(
    () async =>
        (await _client
                .rpc(
                  'message_coach',
                  params: {
                    'p_professional_id': professionalId,
                    'p_sport_id': sportId,
                    'p_body': body,
                  },
                )
                .timeout(_rpcTimeout))
            .toString(),
  );

  /// Also the invite path — offering to someone not yet in the course adds
  /// them first.
  Future<void> sendEnrollmentOffer({
    required String courseId,
    required String userId,
    required String name,
    String? description,
    int? targetSessionCount,
  }) => _run(
    () => _client
        .rpc(
          'send_enrollment_offer',
          params: {
            'p_course_id': courseId,
            'p_user_id': userId,
            'p_name': name.trim(),
            'p_description': description?.trim(),
            'p_target_session_count': targetSessionCount,
          },
        )
        .timeout(_rpcTimeout),
    courseId: courseId,
  );

  Future<void> respondToOffer(String offerId, bool accept, {String? courseId}) =>
      _run(
        () => _client
            .rpc(
              'respond_enrollment_offer',
              params: {'p_offer_id': offerId, 'p_accept': accept},
            )
            .timeout(_rpcTimeout),
        courseId: courseId,
      );

  Future<void> leave(String courseId) => _run(
    () => _client
        .rpc('leave_course', params: {'p_course_id': courseId})
        .timeout(_rpcTimeout),
    courseId: courseId,
  );

  Future<void> removeMember(String courseId, String userId) => _run(
    () => _client
        .rpc(
          'remove_course_member',
          params: {'p_course_id': courseId, 'p_user_id': userId},
        )
        .timeout(_rpcTimeout),
    courseId: courseId,
  );

  Future<void> endCourse(String courseId) => _run(
    () => _client
        .rpc('end_course', params: {'p_course_id': courseId})
        .timeout(_rpcTimeout),
    courseId: courseId,
  );

  /// A coach's proposal is born approved; a student's starts pending.
  Future<void> proposeSession({
    required String courseId,
    required DateTime start,
    required DateTime end,
    String? locationId,
    String? note,
  }) => _run(
    () => _client
        .rpc(
          'propose_course_activity',
          params: {
            'p_course_id': courseId,
            'p_start': start.toUtc().toIso8601String(),
            'p_end': end.toUtc().toIso8601String(),
            'p_location_id': locationId,
            'p_note': note?.trim(),
          },
        )
        .timeout(_rpcTimeout),
    courseId: courseId,
  );

  Future<void> respondToProposal(
    String activityId,
    bool approve, {
    String? courseId,
  }) => _run(
    () => _client
        .rpc(
          'respond_course_proposal',
          params: {'p_activity_id': activityId, 'p_approve': approve},
        )
        .timeout(_rpcTimeout),
    courseId: courseId,
  );

  Future<void> withdrawProposal(String activityId, {String? courseId}) => _run(
    () => _client
        .rpc('withdraw_course_proposal', params: {'p_activity_id': activityId})
        .timeout(_rpcTimeout),
    courseId: courseId,
  );

  /// Rescheduling clears every RSVP server-side — "going" answered a
  /// different question.
  Future<void> reschedule({
    required String activityId,
    required DateTime start,
    required DateTime end,
    String? locationId,
    String? courseId,
  }) => _run(
    () => _client
        .rpc(
          'reschedule_course_activity',
          params: {
            'p_activity_id': activityId,
            'p_start': start.toUtc().toIso8601String(),
            'p_end': end.toUtc().toIso8601String(),
            'p_location_id': locationId,
          },
        )
        .timeout(_rpcTimeout),
    courseId: courseId,
  );

  Future<void> cancelSession(String activityId, {String? courseId}) => _run(
    () => _client
        .rpc('cancel_course_activity', params: {'p_activity_id': activityId})
        .timeout(_rpcTimeout),
    courseId: courseId,
  );

  /// RSVP. No quorum on a course session — this is attendance intent only.
  Future<void> rsvp(String activityId, String attendance, {String? courseId}) =>
      _run(() async {
        final userId = ref.read(currentUserIdProvider);
        if (userId == null) return;
        await _client
            .from('activity_confirmation')
            .upsert({
              'activity_id': activityId,
              'user_id': userId,
              'attendance': attendance,
            })
            .timeout(_rpcTimeout);
      }, courseId: courseId);

  /// Final on submission: no edit, no delete.
  Future<void> submitReport({
    required String activityId,
    required String studentId,
    required String body,
    String? courseId,
  }) => _run(
    () => _client
        .rpc(
          'submit_session_report',
          params: {
            'p_activity_id': activityId,
            'p_student_id': studentId,
            'p_body': body.trim(),
          },
        )
        .timeout(_rpcTimeout),
    courseId: courseId,
  );

  /// Also final. Requires an ended course (or having left) plus at least one
  /// attended session — both enforced server-side.
  Future<void> submitReview({
    required String courseId,
    required int rating,
    String? comment,
  }) => _run(
    () => _client
        .rpc(
          'submit_course_review',
          params: {
            'p_course_id': courseId,
            'p_rating': rating,
            'p_comment': comment?.trim(),
          },
        )
        .timeout(_rpcTimeout),
    courseId: courseId,
  );
}
