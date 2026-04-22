import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gps_camera/models/geo_photo.dart';
import 'package:gps_camera/services/database_service.dart';

class PhotosNotifier extends StateNotifier<List<GeoPhoto>> {
  PhotosNotifier(this._databaseService) : super(const <GeoPhoto>[]);

  final DatabaseService _databaseService;

  Future<void> loadAll() async {
    state = await _databaseService.getAll();
  }

  Future<void> addPhoto(GeoPhoto photo) async {
    state = <GeoPhoto>[photo, ...state];
  }

  Future<void> deletePhoto(int id) async {
    await _databaseService.delete(id);
    state = state.where((GeoPhoto photo) => photo.id != id).toList();
  }
}

final StateNotifierProvider<PhotosNotifier, List<GeoPhoto>> photosProvider =
    StateNotifierProvider<PhotosNotifier, List<GeoPhoto>>(
  (Ref ref) => PhotosNotifier(DatabaseService()),
);
