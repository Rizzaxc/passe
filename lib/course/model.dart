/// Models for the coaching-course subsystem (`schema/course.sql`).
///
/// A **course** is the container for a coaching relationship: one coach, one
/// sport, many students, a persistent thread (on the shared messaging layer),
/// and sessions the coach approves. It replaced per-lesson coach bookings.
library;

enum CourseStatus {
  active,
  ended;

  factory CourseStatus.fromDb(String value) =>
      value == 'ended' ? ended : active;
}

enum CourseMemberStatus {
  inquiring,
  enrolled,
  left,
  removed;

  factory CourseMemberStatus.fromDb(String value) => switch (value) {
    'enrolled' => enrolled,
    'left' => left,
    'removed' => removed,
    _ => inquiring,
  };

  /// Whether this member has actually joined the course, as opposed to just
  /// having messaged the coach.
  bool get isEnrolled => this == enrolled;
}

enum ProposalStatus {
  pending,
  approved,
  rejected,
  withdrawn;

  factory ProposalStatus.fromDb(String? value) => switch (value) {
    'approved' => approved,
    'rejected' => rejected,
    'withdrawn' => withdrawn,
    _ => pending,
  };
}

/// A row in the player's course hub or the coach's course inbox.
class CourseSummary {
  final String courseId;
  final String? conversationId;

  /// Null until the first enrollment offer is accepted — an inquiry that never
  /// went anywhere has no name yet.
  final String? name;
  final CourseStatus status;
  final int sportId;

  final String? coachName;
  final String? coachAvatar;
  final String? coachUserId;
  final String? professionalId;

  /// Player side only.
  final CourseMemberStatus? memberStatus;
  final String? pendingOfferId;
  final int pendingRsvpCount;

  /// Coach side only.
  final int studentCount;
  final int inquiringCount;
  final int pendingProposalCount;
  final int pendingReportCount;

  /// Coach side only. The earliest-joined live member's username — lets the
  /// card show *who* is asking before the course has a real [name] (an
  /// inquiry that hasn't been turned into an enrollment offer yet).
  final String? studentName;
  final String? studentUserId;
  final String? studentAvatar;

  final int? targetSessionCount;
  final int heldSessionCount;
  final DateTime? nextStartTime;
  final DateTime? lastMessageAt;
  final String? lastMessageBody;

  /// 'text' | 'system' | 'payment_info' | 'poll' | null (no message yet). A
  /// system message's body is a stable code, not prose — the card localises
  /// it the same way the chat thread's own system rows do, using this plus
  /// [lastMessagePayload] as named args.
  final String? lastMessageKind;
  final Map<String, dynamic>? lastMessagePayload;
  final int unreadCount;

  const CourseSummary({
    required this.courseId,
    required this.status,
    required this.sportId,
    this.conversationId,
    this.name,
    this.coachName,
    this.coachAvatar,
    this.coachUserId,
    this.professionalId,
    this.memberStatus,
    this.pendingOfferId,
    this.pendingRsvpCount = 0,
    this.studentCount = 0,
    this.inquiringCount = 0,
    this.pendingProposalCount = 0,
    this.pendingReportCount = 0,
    this.studentName,
    this.studentUserId,
    this.studentAvatar,
    this.targetSessionCount,
    this.heldSessionCount = 0,
    this.nextStartTime,
    this.lastMessageAt,
    this.lastMessageBody,
    this.lastMessageKind,
    this.lastMessagePayload,
    this.unreadCount = 0,
  });

  /// Progress toward the coach's target, or null when no target was set.
  double? get progress {
    final target = targetSessionCount;
    if (target == null || target == 0) return null;
    return (heldSessionCount / target).clamp(0.0, 1.0);
  }

  bool get hasAction =>
      pendingOfferId != null ||
      pendingRsvpCount > 0 ||
      pendingProposalCount > 0 ||
      pendingReportCount > 0 ||
      unreadCount > 0;

  static int _int(Object? v) => int.tryParse(v?.toString() ?? '') ?? 0;

  static DateTime? _date(Object? v) =>
      v == null ? null : DateTime.parse(v.toString()).toLocal();

  factory CourseSummary.fromJson(Map<String, dynamic> json) => CourseSummary(
    courseId: json['course_id'].toString(),
    conversationId: json['conversation_id']?.toString(),
    name: json['name'] as String?,
    status: CourseStatus.fromDb(json['status']?.toString() ?? 'active'),
    sportId: _int(json['sport_id']),
    coachName: json['coach_name'] as String?,
    coachAvatar: json['coach_avatar'] as String?,
    coachUserId: json['coach_user_id']?.toString(),
    professionalId: json['professional_id']?.toString(),
    memberStatus: json['member_status'] == null
        ? null
        : CourseMemberStatus.fromDb(json['member_status'].toString()),
    pendingOfferId: json['pending_offer_id']?.toString(),
    pendingRsvpCount: _int(json['pending_rsvp_count']),
    studentCount: _int(json['student_count']),
    inquiringCount: _int(json['inquiring_count']),
    pendingProposalCount: _int(json['pending_proposal_count']),
    pendingReportCount: _int(json['pending_report_count']),
    studentName: json['student_name'] as String?,
    studentUserId: json['student_user_id']?.toString(),
    studentAvatar: json['student_avatar'] as String?,
    targetSessionCount: json['target_session_count'] == null
        ? null
        : _int(json['target_session_count']),
    heldSessionCount: _int(json['held_session_count']),
    nextStartTime: _date(json['next_start_time']),
    lastMessageAt: _date(json['last_message_at']),
    lastMessageBody: json['last_message_body'] as String?,
    lastMessageKind: json['last_message_kind'] as String?,
    lastMessagePayload: json['last_message_payload'] as Map<String, dynamic>?,
    unreadCount: _int(json['unread_count']),
  );
}

class CourseMember {
  final String userId;
  final String username;
  final String? generatedAvatar;
  final CourseMemberStatus status;

  const CourseMember({
    required this.userId,
    required this.username,
    required this.status,
    this.generatedAvatar,
  });

  factory CourseMember.fromJson(Map<String, dynamic> json) => CourseMember(
    userId: json['user_id'].toString(),
    username: json['username']?.toString() ?? '',
    generatedAvatar: json['generated_avatar'] as String?,
    status: CourseMemberStatus.fromDb(
      json['status']?.toString() ?? 'inquiring',
    ),
  );
}

class CourseSession {
  final String activityId;
  final DateTime startTime;
  final DateTime? endTime;
  final String? locationId;
  final String? venueName;
  final String? streetAddress;
  final String? locationStreetNumber;
  final String? locationStreetName;
  final String? locationDistrict;
  final String? locationCity;
  final double? locationLat;
  final double? locationLon;
  final String? note;
  final ProposalStatus proposalStatus;
  final String? proposedBy;

  /// The caller's own RSVP: going / maybe / out, or null if unanswered.
  final String? myAttendance;
  final int goingCount;

  const CourseSession({
    required this.activityId,
    required this.startTime,
    required this.proposalStatus,
    this.endTime,
    this.locationId,
    this.venueName,
    this.streetAddress,
    this.locationStreetNumber,
    this.locationStreetName,
    this.locationDistrict,
    this.locationCity,
    this.locationLat,
    this.locationLon,
    this.note,
    this.proposedBy,
    this.myAttendance,
    this.goingCount = 0,
  });

  bool get isPending => proposalStatus == ProposalStatus.pending;

  bool get hasFinished => (endTime ?? startTime).isBefore(DateTime.now());

  factory CourseSession.fromJson(Map<String, dynamic> json) => CourseSession(
    activityId: json['activity_id'].toString(),
    startTime: DateTime.parse(json['start_time'].toString()).toLocal(),
    endTime: json['end_time'] == null
        ? null
        : DateTime.parse(json['end_time'].toString()).toLocal(),
    locationId: json['location_id']?.toString(),
    venueName: json['venue_name'] as String?,
    streetAddress: json['street_address'] as String?,
    locationStreetNumber: json['location_street_number']?.toString(),
    locationStreetName: json['location_street_name']?.toString(),
    locationDistrict: json['location_district']?.toString(),
    locationCity: json['location_city']?.toString(),
    locationLat: (json['location_lat'] as num?)?.toDouble(),
    locationLon: (json['location_lon'] as num?)?.toDouble(),
    note: json['note'] as String?,
    proposalStatus: ProposalStatus.fromDb(json['proposal_status']?.toString()),
    proposedBy: json['proposed_by']?.toString(),
    myAttendance: json['my_attendance'] as String?,
    goingCount: int.tryParse(json['going_count']?.toString() ?? '') ?? 0,
  );
}

/// A coach's private write-up of one student's session. Immutable, and
/// readable only by its student and the coach — the RPC filters accordingly,
/// so anything present here is legitimately visible.
class SessionReport {
  final String activityId;
  final String studentId;
  final String body;
  final DateTime createdAt;

  const SessionReport({
    required this.activityId,
    required this.studentId,
    required this.body,
    required this.createdAt,
  });

  factory SessionReport.fromJson(Map<String, dynamic> json) => SessionReport(
    activityId: json['activity_id'].toString(),
    studentId: json['student_id'].toString(),
    body: json['body']?.toString() ?? '',
    createdAt: DateTime.parse(json['created_at'].toString()).toLocal(),
  );
}

class CourseDetail {
  final String courseId;
  final String? conversationId;
  final String? name;
  final String? description;
  final CourseStatus status;
  final int sportId;
  final String professionalId;
  final String? coachName;
  final String? coachUserId;
  final bool isCoach;

  /// The viewer's own membership status, or null for the coach (who isn't a
  /// `course_member` row at all).
  final CourseMemberStatus? myMemberStatus;
  final int? targetSessionCount;
  final int heldSessionCount;
  final List<CourseMember> members;
  final List<CourseSession> sessions;
  final List<SessionReport> reports;
  final int? myReviewRating;

  const CourseDetail({
    required this.courseId,
    required this.status,
    required this.sportId,
    required this.professionalId,
    required this.isCoach,
    this.myMemberStatus,
    this.conversationId,
    this.name,
    this.description,
    this.coachName,
    this.coachUserId,
    this.targetSessionCount,
    this.heldSessionCount = 0,
    this.members = const [],
    this.sessions = const [],
    this.reports = const [],
    this.myReviewRating,
  });

  /// Whether the viewer may act on the course — propose/schedule sessions,
  /// RSVP, see the planner and history. An inquiring (unenrolled) student
  /// has course *access* (they can read the thread) but not this — the
  /// coach hasn't accepted them yet, so there's nothing to plan or attend.
  bool get canManage => isCoach || (myMemberStatus?.isEnrolled ?? false);

  List<CourseSession> get upcoming => sessions
      .where(
        (s) => !s.hasFinished && s.proposalStatus == ProposalStatus.approved,
      )
      .toList();

  List<CourseSession> get pendingProposals =>
      sessions.where((s) => s.isPending).toList();

  List<CourseSession> get past => sessions
      .where(
        (s) => s.hasFinished && s.proposalStatus == ProposalStatus.approved,
      )
      .toList()
      .reversed
      .toList();

  static List<T> _list<T>(
    Object? raw,
    T Function(Map<String, dynamic>) parse,
  ) =>
      (raw as List?)?.map((e) => parse(e as Map<String, dynamic>)).toList() ??
      const [];

  factory CourseDetail.fromJson(Map<String, dynamic> json) => CourseDetail(
    courseId: json['course_id'].toString(),
    conversationId: json['conversation_id']?.toString(),
    name: json['name'] as String?,
    description: json['description'] as String?,
    status: CourseStatus.fromDb(json['status']?.toString() ?? 'active'),
    sportId: int.tryParse(json['sport_id']?.toString() ?? '') ?? 0,
    professionalId: json['professional_id'].toString(),
    coachName: json['coach_name'] as String?,
    coachUserId: json['coach_user_id']?.toString(),
    isCoach: json['is_coach'] as bool? ?? false,
    myMemberStatus: json['my_member_status'] == null
        ? null
        : CourseMemberStatus.fromDb(json['my_member_status'].toString()),
    targetSessionCount: json['target_session_count'] == null
        ? null
        : int.tryParse(json['target_session_count'].toString()),
    heldSessionCount:
        int.tryParse(json['held_session_count']?.toString() ?? '') ?? 0,
    members: _list(json['members'], CourseMember.fromJson),
    sessions: _list(json['sessions'], CourseSession.fromJson),
    reports: _list(json['reports'], SessionReport.fromJson),
    myReviewRating: json['my_review_rating'] == null
        ? null
        : int.tryParse(json['my_review_rating'].toString()),
  );
}
