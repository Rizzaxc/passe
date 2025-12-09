import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:talker/talker.dart';

class PuboxTalkerObserver extends TalkerObserver {
  PuboxTalkerObserver(this.env);
  final String env;
  @override
  void onError(TalkerError err) {
    if (env != 'local') {
      Sentry.captureMessage(err.message, level: SentryLevel.error);
    }
    super.onError(err);
  }

  @override
  void onException(TalkerException err) {
    if (env != 'local') {
      Sentry.captureException(err, stackTrace: err.stackTrace);
    }
    super.onException(err);
  }

  // @override
  // void onLog(TalkerDataInterface log) {
  //   super.onLog(log);
  // }
}
