/// Compile-time switches for client features that are implemented but are not
/// part of the default shipped experience yet.
abstract final class ClientFeatureFlags {
  /// Lobby-vs-lobby Challenger discovery and management.
  ///
  /// Opt in explicitly with:
  /// `--dart-define=ENABLE_CHALLENGER_FLOW=true`.
  static const challengerFlow = bool.fromEnvironment('ENABLE_CHALLENGER_FLOW');

  /// Hiring a **referee** — Home ▸ Neutrals referee results, the booking CTA on
  /// a referee's profile, referee pro mode, and the booking-request inbox.
  ///
  /// Shares the challenger define deliberately: a referee's only job in the app
  /// is officiating a challenge match, so shipping one without the other would
  /// offer users a booking with nothing to referee. Reads as its own name so
  /// call sites say what they actually gate.
  ///
  /// The schema is fully live either way — `referee_booking` and the Elo chain
  /// that depends on it are untouched by this flag (see
  /// `schema/referee_booking_rename.sql`).
  static const refereeFlow = challengerFlow;
}
