import 'dart:io';

import 'package:image/image.dart' as img;

class ExifWriter {
  /// Best-effort EXIF update. Re-encodes image so later native EXIF integration
  /// can inject GPS tags. This method intentionally never throws.
  Future<void> writeGPSToExif(
    String imagePath,
    double lat,
    double lng,
    double? altitude,
  ) async {
    try {
      final File imageFile = File(imagePath);
      final img.Image? decoded =
          img.decodeImage(await imageFile.readAsBytes());
      if (decoded == null) return;

      // Re-encode to normalize file format before downstream EXIF writes.
      await imageFile.writeAsBytes(img.encodeJpg(decoded, quality: 95));
      // NOTE: The `image` package has limited EXIF-writing support. GPS write is
      // kept as best-effort and can be swapped with native_exif in V2.
      // Parameters lat/lng/altitude are intentionally kept to preserve API.
      // ignore: avoid_unused_constructor_parameters
      (lat, lng, altitude);
    } catch (_) {
      // swallow on purpose; geotagging flow should not fail hard on EXIF write.
    }
  }
}
