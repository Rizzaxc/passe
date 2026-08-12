/// Compile-time switches for client features that are implemented but are not
/// part of the default shipped experience yet.
abstract final class ClientFeatureFlags {
  /// Lobby-vs-lobby Challenger discovery and management.
  ///
  /// Opt in explicitly with:
  /// `--dart-define=ENABLE_CHALLENGER_FLOW=true`.
  static const challengerFlow = bool.fromEnvironment('ENABLE_CHALLENGER_FLOW');
}
