import 'dart:convert';
import 'dart:io';

import 'package:exif/exif.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../models/location_info.dart';

class MediaSaver {
  static Future<bool> savePhoto({
    required String filePath,
    required LocationInfo locationInfo,
  }) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final result = await ImageGallerySaverPlus.saveImage(bytes);
      await File('$filePath.gps.json')
          .writeAsString(jsonEncode(locationInfo.toJson()));
      return result['isSuccess'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> saveVideo({
    required String filePath,
    required LocationInfo locationInfo,
  }) async {
    try {
      final result = await ImageGallerySaverPlus.saveFile(filePath);
      await File('$filePath.gps.json')
          .writeAsString(jsonEncode(locationInfo.toJson()));
      return result['isSuccess'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<LocationInfo?> loadMetadataForAsset(AssetEntity asset) async {
    try {
      final title = asset.title;
      final rel = asset.relativePath;
      if (title == null || rel == null) return null;
      final candidate = File('/storage/emulated/0/$rel/$title.gps.json');
      if (await candidate.exists()) {
        final json = jsonDecode(await candidate.readAsString());
        return LocationInfo.fromJson(json as Map<String, dynamic>);
      }

      final file = await asset.file;
      if (file == null) return null;
      final exif = await readExifFromBytes(await file.readAsBytes());
      if (exif.containsKey('GPS GPSLatitude') &&
          exif.containsKey('GPS GPSLongitude')) {
        return const LocationInfo(
          address: 'Location metadata found',
          date: '',
          time: '',
          latitude: 0,
          longitude: 0,
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
