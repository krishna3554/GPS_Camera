import 'dart:io';
import 'dart:typed_data';

import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Persists generated media into the platform gallery and returns the saved URI/path.
class GalleryService {
  const GalleryService();

  Future<String?> saveImageBytes({
    required Uint8List bytes,
    required String name,
    int quality = 95,
  }) async {
    await _ensureGalleryPermission();
    final result = await ImageGallerySaverPlus.saveImage(
      bytes,
      quality: quality,
      name: name,
    );
    if (result is Map && result['isSuccess'] == true) {
      return (result['filePath'] ?? result['filepath'] ?? result['path'])?.toString();
    }
    return null;
  }

  Future<String?> saveFile(String filePath) async {
    await _ensureGalleryPermission();
    final result = await ImageGallerySaverPlus.saveFile(filePath);
    if (result is Map && result['isSuccess'] == true) {
      return (result['filePath'] ?? result['filepath'] ?? result['path'] ?? filePath)?.toString();
    }
    return null;
  }

  Future<void> _ensureGalleryPermission() async {
    if (Platform.isAndroid) {
      final photos = await Permission.photos.request();
      if (photos.isGranted || photos.isLimited) return;

      final storage = await Permission.storage.request();
      if (storage.isGranted || storage.isLimited) return;
    }
  }
}
