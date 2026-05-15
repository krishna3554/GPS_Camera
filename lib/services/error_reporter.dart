import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Central crash and non-fatal error reporting.
///
/// Firebase initialization is best-effort so local/debug builds without
/// platform Firebase options still boot. Production builds with Firebase
/// configuration automatically send Flutter framework, platform dispatcher,
/// and zoned async crashes to Crashlytics with stack traces.
class ErrorReporter {
  ErrorReporter._();

  static bool _crashlyticsReady = false;

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        !kDebugMode,
      );
      _crashlyticsReady = true;
    } catch (error, stackTrace) {
      debugPrint('Crash reporting disabled: $error');
      debugPrintStack(stackTrace: stackTrace);
      _crashlyticsReady = false;
    }

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      recordFlutterFatalError(details);
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stackTrace) {
      recordError(error, stackTrace, fatal: true);
      return true;
    };
  }

  static Future<void> recordFlutterFatalError(FlutterErrorDetails details) async {
    if (_crashlyticsReady) {
      await FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      return;
    }
    debugPrint('Flutter fatal error: ${details.exceptionAsString()}');
    debugPrintStack(stackTrace: details.stack);
  }

  static Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
    String? reason,
  }) async {
    if (_crashlyticsReady) {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        fatal: fatal,
        reason: reason,
      );
      return;
    }
    debugPrint('${fatal ? 'Fatal' : 'Non-fatal'} error: $error');
    if (reason != null) debugPrint('Reason: $reason');
    debugPrintStack(stackTrace: stackTrace);
  }
}
