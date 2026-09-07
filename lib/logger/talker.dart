import 'package:talker_flutter/talker_flutter.dart';

import 'observer.dart';

/// The app's single Talker instance. Log through this everywhere — never
/// construct a bare `Talker()`, which builds a disconnected instance with no
/// observer, so its `.handle()`/`.error()`/etc. calls never reach Sentry (this
/// shipped broken across most of the codebase: dozens of call sites each
/// created their own throwaway instance instead of using this one).
/// `main.dart` calls [Talker.configure] on this exact instance once `.env` is
/// loaded, to apply the env-dependent log level — that does not replace it,
/// so anything logged here before or after configuration is the same
/// Sentry-wired instance.
final talker = Talker(observer: PasseTalkerObserver());
