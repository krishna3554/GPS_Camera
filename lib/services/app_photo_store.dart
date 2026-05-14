import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_photo.dart';

class AppPhotoStore {
  static const _photosKey = 'app_saved_photos';

  const AppPhotoStore();

  Future<List<AppPhoto>> loadPhotos() async {
    final prefs = await SharedPreferences.getInstance();
    final rawItems = prefs.getStringList(_photosKey) ?? const <String>[];
    final photos = rawItems
        .map((raw) => AppPhoto.fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .where((photo) => File(photo.filePath).existsSync())
        .toList()
      ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));

    if (photos.length != rawItems.length) {
      await _saveAll(photos);
    }
    return photos;
  }

  Future<void> addPhoto(AppPhoto photo) async {
    final photos = await loadPhotos();
    photos.removeWhere((item) => item.filePath == photo.filePath || item.id == photo.id);
    photos.insert(0, photo);
    await _saveAll(photos);
  }

  Future<void> deletePhoto(AppPhoto photo, {bool deleteFile = true}) async {
    if (deleteFile) {
      final file = File(photo.filePath);
      if (file.existsSync()) await file.delete();
    }
    final photos = await loadPhotos();
    photos.removeWhere((item) => item.id == photo.id || item.filePath == photo.filePath);
    await _saveAll(photos);
  }

  Future<void> _saveAll(List<AppPhoto> photos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _photosKey,
      photos.map((photo) => jsonEncode(photo.toJson())).toList(),
    );
  }
}
