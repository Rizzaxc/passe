import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:talker/talker.dart';

class PasseTalkerObserver extends TalkerObserver {
  @override
  void onError(TalkerError err) {
    Sentry.captureException(err.error, stackTrace: err.stackTrace);
    super.onError(err);
  }

  @override
  void onException(TalkerException err) {
    Sentry.captureException(err, stackTrace: err.stackTrace);
    super.onException(err);
  }

  // @override
  // void onLog(TalkerDataInterface log) {
  //   super.onLog(log);
  // }
}
