/// Client mirror of the Postgres `notification_kind` enum
/// (see schema/push_notifications.sql). The `value` is the canonical DB string
/// and is what arrives in the FCM `data.kind` field — keep the two in lockstep.
enum NotificationKind {
  activityConfirmed('activity_confirmed'),
  proSessionReminder('pro_session_reminder'),
  challengerConfirmed('challenger_confirmed'),
  challengeReceived('challenge_received'),
  challengeDeclined('challenge_declined'),
  lobbyInvite('lobby_invite'),
  professionalBookingRequested('professional_booking_requested'),
  professionalBookingConfirmed('professional_booking_confirmed'),
  professionalBookingRejected('professional_booking_rejected'),
  friendRequest('friend_request'),
  friendAccepted('friend_accepted');

  const NotificationKind(this.value);

  /// The DB / wire value (matches `data.kind` on every push).
  final String value;

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
