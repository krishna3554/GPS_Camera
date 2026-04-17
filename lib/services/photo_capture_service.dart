import 'dart:io';

import 'package:camera/camera.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class PhotoCaptureService {
  Future<void> ensureCameraPermission() async {
    final cameraStatus = await Permission.camera.request();
    if (!cameraStatus.isGranted) {
      throw Exception('Camera permission denied');
    }
  }

  Future<List<CameraDescription>> getAvailableCameras() {
    return availableCameras();
  }

  Future<String> moveToAppFolder(XFile rawFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(appDir.path, 'geo_photos'));
    if (!photosDir.existsSync()) {
      photosDir.createSync(recursive: true);
    }

    final fileName =
        'photo_${DateTime.now().millisecondsSinceEpoch}${p.extension(rawFile.path)}';
    final targetPath = p.join(photosDir.path, fileName);
    await File(rawFile.path).copy(targetPath);
    return targetPath;
  }

  Future<void> saveDirectlyToGallery(String imagePath) async {
    final ok = await GallerySaver.saveImage(imagePath, albumName: 'GPS Camera');
    if (ok != true) {
      throw Exception('Failed to save image to gallery');
    }
  }
}
