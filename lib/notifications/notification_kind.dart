/// Client mirror of the Postgres `notification_kind` enum
/// (see schema/push_notifications.sql). The `value` is the canonical DB string
/// and is what arrives in the FCM `data.kind` field — keep the two in lockstep.
enum NotificationKind {
  activityScheduled('activity_scheduled'),
  activityConfirmed('activity_confirmed'),
  proSessionReminder('pro_session_reminder'),
  challengerConfirmed('challenger_confirmed'),
  challengeReceived('challenge_received'),
  challengeDeclined('challenge_declined'),
  challengeScheduled('challenge_scheduled'),
  challengeLapsed('challenge_lapsed'),
  matchResultRecorded('match_result_recorded'),
  lobbyInvite('lobby_invite'),
  lobbyJoinRequest('lobby_join_request'),
  lobbyJoinRequestApproved('lobby_join_request_approved'),
  lobbyJoinRequestDenied('lobby_join_request_denied'),
  memberKicked('member_kicked'),
  // Referee bookings only — the coach half of the booking system was replaced
  // by courses. Server-side these are disabled in `enabled_notification_kind`
  // while refereeing is iced (see ClientFeatureFlags.refereeFlow).
  professionalBookingRequested('professional_booking_requested'),
  professionalBookingConfirmed('professional_booking_confirmed'),
  professionalBookingRejected('professional_booking_rejected'),
  courseMessage('course_message'),
  courseEnrollmentOffer('course_enrollment_offer'),
  courseEnrollmentAccepted('course_enrollment_accepted'),
  courseActivityProposed('course_activity_proposed'),
  courseActivityApproved('course_activity_approved'),
  courseActivityChanged('course_activity_changed'),
  courseSessionReport('course_session_report'),
  courseEnded('course_ended'),
  courseMemberRemoved('course_member_removed'),
  friendRequest('friend_request'),
  friendAccepted('friend_accepted'),
  paymentRequested('payment_requested'),
  debtCollected('debt_collected'),
  freeplayRequestReceived('freeplay_request_received'),
  freeplayRequestAccepted('freeplay_request_accepted'),
  freeplayRequestDeclined('freeplay_request_declined'),
  freeplayRequestCancelled('freeplay_request_cancelled'),
  freeplayActivityCancelled('freeplay_activity_cancelled'),
  freeplayChatMessage('freeplay_chat_message'),
  activityAtRiskOrganizer('activity_at_risk_organizer'),
  activityAtRiskMember('activity_at_risk_member'),
  activityCancelledLowTurnout('activity_cancelled_low_turnout');

  const NotificationKind(this.value);

  /// The DB / wire value (matches `data.kind` on every push).
  final String value;

  static const challengerFlowValues = <String>[
    'challenger_confirmed',
    'challenge_received',
    'challenge_declined',
    'challenge_scheduled',
    'challenge_lapsed',
    'match_result_recorded',
  ];

  /// Referee-hiring pushes, gated by the same define as the challenger flow.
  bool get isRefereeFlow => switch (this) {
    professionalBookingRequested ||
    professionalBookingConfirmed ||
    professionalBookingRejected => true,
    _ => false,
  };

  bool get isCourseFlow => switch (this) {
    courseMessage ||
    courseEnrollmentOffer ||
    courseEnrollmentAccepted ||
    courseActivityProposed ||
    courseActivityApproved ||
    courseActivityChanged ||
    courseSessionReport ||
    courseEnded ||
    courseMemberRemoved => true,
    _ => false,
  };

  bool get isChallengerFlow => switch (this) {
    challengerConfirmed ||
    challengeReceived ||
    challengeDeclined ||
    challengeScheduled ||
    challengeLapsed ||
    matchResultRecorded => true,
    _ => false,
  };

  /// Resolve a wire value to a kind, or null if unknown (forward-compat: a new
  /// server kind the installed app doesn't know yet is ignored, not crashed on).
  static NotificationKind? fromValue(String? value) {
    if (value == null) return null;
    for (final kind in NotificationKind.values) {
      if (kind.value == value) return kind;
    }
    return null;
  }
}
