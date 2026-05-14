import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class AppPermissionHandler {
  static Future<bool> requestAllPermissions() async {
    final cameraStatus = await Permission.camera.request();

    await Permission.microphone.request();
    await Permission.locationWhenInUse.request();

    if (Platform.isAndroid) {
      await Permission.photos.request();
      await Permission.videos.request();
    } else if (Platform.isIOS) {
      await Permission.photos.request();
    }

    return cameraStatus.isGranted;
  }

  static Future<bool> hasCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  static Future<bool> checkAndRequestCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> checkAndRequestLocation() async {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }
}
