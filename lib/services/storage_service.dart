import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class StorageService {
  Future<String> savePhoto(XFile photo) async {
    final Directory root = await getApplicationDocumentsDirectory();
    final Directory photosDir = Directory(p.join(root.path, 'photos'));
    if (!photosDir.existsSync()) {
      photosDir.createSync(recursive: true);
    }

    final String filename =
        'IMG_${DateTime.now().toUtc().millisecondsSinceEpoch}.jpg';
    final String targetPath = p.join(photosDir.path, filename);
    final File saved = await File(photo.path).copy(targetPath);
    return saved.path;
  }

  Future<String> generateThumbnail(String imagePath) async {
    final File source = File(imagePath);
    final Uint8List bytes = await source.readAsBytes();
    final img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw StateError('Unable to decode image for thumbnail generation.');
    }

    final img.Image thumb = img.copyResize(decoded, width: 128, height: 128);
    final Directory root = await getApplicationDocumentsDirectory();
    final Directory thumbsDir = Directory(p.join(root.path, 'thumbnails'));
    if (!thumbsDir.existsSync()) {
      thumbsDir.createSync(recursive: true);
    }

    final String filename =
        'THUMB_${DateTime.now().toUtc().millisecondsSinceEpoch}.jpg';
    final String thumbPath = p.join(thumbsDir.path, filename);
    await File(thumbPath).writeAsBytes(img.encodeJpg(thumb, quality: 85));
    return thumbPath;
  }

  Future<void> deletePhoto(String imagePath) async {
    final File file = File(imagePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
