import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class AppPermissionHandler {
  static Future<bool> requestAllPermissions() async {
    final granted = <PermissionStatus>[];

    granted.add(await Permission.camera.request());
    granted.add(await Permission.microphone.request());
    granted.add(await Permission.locationAlways.request());

    if (Platform.isAndroid) {
      granted.add(await Permission.storage.request());
      granted.add(await Permission.photos.request());
      granted.add(await Permission.videos.request());
    } else if (Platform.isIOS) {
      granted.add(await Permission.photos.request());
    }

    return granted.every((status) => status.isGranted || status.isLimited);
  }

  static Future<bool> checkAndRequestCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> checkAndRequestLocation() async {
    final status = await Permission.locationAlways.request();
    return status.isGranted;
  }
}
