import 'package:camera/camera.dart';
import 'package:gal/gal.dart';
import 'package:gps_camera/models/geo_photo.dart';
import 'package:gps_camera/models/location_data.dart';
import 'package:gps_camera/services/database_service.dart';
import 'package:gps_camera/services/geocoding_service.dart';
import 'package:gps_camera/services/storage_service.dart';
import 'package:gps_camera/utils/exif_writer.dart';

class CameraService {
  CameraService._internal();
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;

  final StorageService _storageService = StorageService();
  final GeocodingService _geocodingService = GeocodingService();
  final DatabaseService _databaseService = DatabaseService();
  final ExifWriter _exifWriter = ExifWriter();

  CameraController? _controller;
  List<CameraDescription> _cameras = <CameraDescription>[];

  CameraController? get controller => _controller;

  Future<void> initialize() async {
    _cameras = await availableCameras();
    final CameraDescription selected = _cameras.firstWhere(
      (CameraDescription c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras.first,
    );

    _controller = CameraController(
      selected,
      ResolutionPreset.high,
      imageFormatGroup: ImageFormatGroup.jpeg,
      enableAudio: false,
    );
    await _controller!.initialize();
  }

  Future<XFile?> capturePhoto() async {
    final CameraController? c = _controller;
    if (c == null || !c.value.isInitialized || c.value.isTakingPicture) {
      return null;
    }
    return c.takePicture();
  }

  Future<GeoPhoto?> captureAndTag(
    LocationData location, {
    bool saveToGallery = true,
  }) async {
    try {
      final XFile? shot = await capturePhoto();
      if (shot == null) {
        return null;
      }

      final String imagePath = await _storageService.savePhoto(shot);
      final String thumbPath = await _storageService.generateThumbnail(imagePath);

      await _exifWriter.writeGPSToExif(
        imagePath,
        location.latitude,
        location.longitude,
        location.altitude,
      );

      final Map<String, String> addressData = await _geocodingService
          .reverseGeocode(location.latitude, location.longitude);

      final GeoPhoto draft = GeoPhoto(
        imagePath: imagePath,
        thumbPath: thumbPath,
        latitude: location.latitude,
        longitude: location.longitude,
        altitude: location.altitude,
        accuracy: location.accuracy,
        heading: location.heading,
        speed: location.speed,
        address: addressData['address'],
        city: addressData['city'],
        country: addressData['country'],
        timestamp: location.timestamp,
        createdAt: DateTime.now().toUtc(),
      );

      final int id = await _databaseService.insert(draft);
      if (saveToGallery) {
        await Gal.putImage(imagePath);
      }
      return draft.copyWith(id: id);
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _controller?.dispose();
    _controller = null;
  }
}
