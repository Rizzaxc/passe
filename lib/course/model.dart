/// Models for the coaching-course subsystem (`schema/course.sql`).
///
/// A **course** is the container for a coaching relationship: one coach, one
/// sport, many students, a persistent thread (on the shared messaging layer),
/// and sessions the coach approves. It replaced per-lesson coach bookings.
library;

import '../core/model/enum.dart';

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

  /// Departed — either by leaving, being removed, or the coach ending the
  /// course (which marks every member `left`).
  bool get hasLeft => this == left || this == removed;
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

  /// Player side: the course is over *for this viewer* — ended outright, or
  /// they left/were removed. `my_courses_data` keeps such rows (only for
  /// students who attended a session) so they can still review the coach.
  bool get isClosedForMe =>
      status == CourseStatus.ended || (memberStatus?.hasLeft ?? false);

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

/// One person on a started session's roster (coach view only): who was in
/// the course at kickoff, what they RSVP'd, and the coach's attendance mark.
class SessionRosterEntry {
  final String userId;
  final String username;
  final String? generatedAvatar;
  final String? rsvp;

  /// The coach's own mark; null = not marked yet.
  final bool? marked;

  /// The effective answer (`fn_course_attended`): the mark when there is one,
  /// otherwise a `going` RSVP. Gates reports and the student's review.
  final bool attended;

  const SessionRosterEntry({
    required this.userId,
    required this.username,
    required this.attended,
    this.generatedAvatar,
    this.rsvp,
    this.marked,
  });

  factory SessionRosterEntry.fromJson(Map<String, dynamic> json) =>
      SessionRosterEntry(
        userId: json['user_id'].toString(),
        username: json['username']?.toString() ?? '',
        generatedAvatar: json['generated_avatar'] as String?,
        rsvp: json['rsvp'] as String?,
        marked: json['marked'] as bool?,
        attended: json['attended'] as bool? ?? false,
      );
}

/// One of the coach's listed coaching services for the course's sport.
/// Courses carry no money; this only answers "how much?" on the course page.
class CoachRate {
  final double? priceAmount;
  final ProfessionalPricingKind pricingKind;
  final int? minDurationMinutes;
  final int? maxParticipants;
  final String? description;

  const CoachRate({
    required this.pricingKind,
    this.priceAmount,
    this.minDurationMinutes,
    this.maxParticipants,
    this.description,
  });

  factory CoachRate.fromJson(Map<String, dynamic> json) => CoachRate(
    // numeric comes back as a String or a num depending on the path.
    priceAmount: double.tryParse(json['price_amount']?.toString() ?? ''),
    pricingKind: ProfessionalPricingKind.fromValue(
      json['pricing_kind'] as String?,
    ),
    minDurationMinutes: int.tryParse(
      json['min_duration_minutes']?.toString() ?? '',
    ),
    maxParticipants: int.tryParse(json['max_participants']?.toString() ?? ''),
    description: json['description'] as String?,
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

  /// Student side, once the session has started: whether they count as
  /// having attended. Null before start and for the coach.
  final bool? myAttended;

  /// Coach side, once the session has started; empty otherwise.
  final List<SessionRosterEntry> roster;

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
    this.myAttended,
    this.roster = const [],
  });

  bool get isPending => proposalStatus == ProposalStatus.pending;

  /// RSVP closes, and the session can no longer be moved or cancelled, once
  /// it starts (enforced server-side too).
  bool get hasStarted => !startTime.isAfter(DateTime.now());

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
    myAttended: json['my_attended'] as bool?,
    roster:
        (json['roster'] as List?)
            ?.map((e) => SessionRosterEntry.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
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

  /// The viewer's own pending enrollment offer, if any (student side only —
  /// null for the coach and for anyone without one waiting). This is what
  /// promotes an `inquiring` member to `enrolled` on accept.
  final String? pendingOfferId;
  final String? offerName;
  final String? offerDescription;
  final int? offerTargetSessionCount;
  final List<CoachRate> coachRates;

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
    this.pendingOfferId,
    this.offerName,
    this.offerDescription,
    this.offerTargetSessionCount,
    this.coachRates = const [],
  });

  /// Whether the viewer may act on the course — propose/schedule sessions,
  /// RSVP, see the planner and history. An inquiring (unenrolled) student
  /// has course *access* (they can read the thread) but not this — the
  /// coach hasn't accepted them yet, so there's nothing to plan or attend.
  bool get canManage => isCoach || (myMemberStatus?.isEnrolled ?? false);

  /// A departed student who attended a session — `course_detail_data` gives
  /// them a read-only view (no roster, nothing after they left) so they can
  /// look back and review the coach.
  bool get isAlumnus => myMemberStatus?.hasLeft ?? false;

  /// Mirrors `submit_course_review`'s eligibility gate; the attendance half
  /// is implied, since a departed student without it can't load the course.
  bool get canReview =>
      !isCoach &&
      myReviewRating == null &&
      (status == CourseStatus.ended || isAlumnus);

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
    pendingOfferId: json['pending_offer_id']?.toString(),
    offerName: json['offer_name'] as String?,
    offerDescription: json['offer_description'] as String?,
    offerTargetSessionCount: json['offer_target_session_count'] == null
        ? null
        : int.tryParse(json['offer_target_session_count'].toString()),
    coachRates: _list(json['coach_rates'], CoachRate.fromJson),
  );
}
