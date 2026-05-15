import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/utils/permission_handler.dart';
import 'services/error_reporter.dart';

Future<void> main() async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await ErrorReporter.initialize();
      await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      final granted = await AppPermissionHandler.requestAllPermissions();
      runApp(MyApp(permissionsGranted: granted));
    },
    (error, stackTrace) => ErrorReporter.recordError(
      error,
      stackTrace,
      fatal: true,
      reason: 'Uncaught zoned async error',
    ),
  );
}
