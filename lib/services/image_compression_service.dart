import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Compresses camera images to a practical storage/share size before the app
/// saves or burns overlays into the final photo.
class ImageCompressionService {
  const ImageCompressionService();

  Future<String> compressPhotoFile(
    String sourcePath, {
    int quality = 82,
    int minLongSide = 2560,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw FileSystemException('Captured photo does not exist.', sourcePath);
    }

    final tempDir = await getTemporaryDirectory();
    final targetPath = p.join(
      tempDir.path,
      'compressed_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );

    final compressed = await FlutterImageCompress.compressAndGetFile(
      source.absolute.path,
      targetPath,
      quality: quality,
      minWidth: minLongSide,
      minHeight: minLongSide,
      keepExif: true,
      format: CompressFormat.jpeg,
    );

    final compressedPath = compressed?.path;
    if (compressedPath == null) return sourcePath;

    final originalSize = await source.length();
    final compressedSize = await File(compressedPath).length();
    if (compressedSize <= 0 || compressedSize >= originalSize) {
      return sourcePath;
    }

    return compressedPath;
  }
}
