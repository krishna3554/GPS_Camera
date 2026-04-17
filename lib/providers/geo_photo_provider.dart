import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/geo_photo.dart';
import '../services/database_service.dart';

class GeoPhotoProvider extends ChangeNotifier {
  final List<GeoPhoto> _photos = [];

  List<GeoPhoto> get photos => List.unmodifiable(_photos);

  Future<void> loadPhotos() async {
    _photos
      ..clear()
      ..addAll(await DatabaseService.instance.getAllPhotos());
    notifyListeners();
  }

  Future<void> addPhoto(GeoPhoto photo) async {
    await DatabaseService.instance.insertPhoto(photo);
    await loadPhotos();
  }

  Future<void> deletePhoto(GeoPhoto photo) async {
    if (photo.id != null) {
      await DatabaseService.instance.deletePhoto(photo.id!);
    }
    final file = File(photo.imagePath);
    if (file.existsSync()) {
      await file.delete();
    }
    await loadPhotos();
  }

  Future<void> sharePhoto(GeoPhoto photo) async {
    final text = '''
Location: ${photo.address}
Coordinates: ${photo.latitude}, ${photo.longitude}
Captured: ${photo.timestamp.toIso8601String()}
''';

    await Share.shareXFiles(
      [XFile(photo.imagePath)],
      text: text,
      subject: 'GPS Camera Photo',
    );
  }
}
