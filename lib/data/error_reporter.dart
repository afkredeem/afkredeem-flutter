import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class ErrorReporter {
  static report(dynamic exception, dynamic reason) {
    if (kReleaseMode) {
      FirebaseCrashlytics.instance
          .recordError(exception, StackTrace.current, reason: reason);
    } else {
      print(
          '<ErrorReporter> $exception, reason: $reason\n${StackTrace.current}');
    }
  }
}
