import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/captured_media.dart';
import '../../../models/geo_photo_model.dart';
import '../../../models/location_info.dart';
import '../../../models/app_photo.dart';
import '../../../services/app_photo_store.dart';
import '../../../services/backup_service.dart';
import '../../../services/error_reporter.dart';
import '../../../services/image_compression_service.dart';
import '../../../services/gallery_service.dart';
import '../../../services/google_map_service.dart';
import '../../../services/image_overlay_service.dart';
import '../../../services/settings_service.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    required this.filePath,
    required this.locationInfo,
    required this.type,
    super.key,
  });

  final String filePath;
  final LocationInfo locationInfo;
  final MediaType type;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final AppPhotoStore _photoStore = const AppPhotoStore();
  final GalleryService _galleryService = const GalleryService();
  final BackupService _backupService = BackupService();
  final GoogleMapService _googleMapService = const GoogleMapService();
  final ImageOverlayService _imageOverlayService = const ImageOverlayService();
  final ImageCompressionService _imageCompressionService = const ImageCompressionService();
  final SettingsService _settingsService = const SettingsService();

  bool _showBanner = false;
  bool _processing = true;
  String? _displayFilePath;
  String? _savedGalleryPath;

  @override
  void initState() {
    super.initState();
    _displayFilePath = widget.filePath;
    _init();
  }

  Future<void> _init() async {
    try {
      _savedGalleryPath = await _generateAndSaveGeoTaggedPhoto();

      if (!mounted) return;
      if (_savedGalleryPath != null) {
        _showSavedBanner();
      } else {
        _showSaveError();
      }
    } catch (error, stackTrace) {
      await ErrorReporter.recordError(
        error,
        stackTrace,
        reason: 'Failed to initialize result screen.',
      );
      if (!mounted) return;
      _showSaveError('Failed to generate geo-tagged photo: $error');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  /// Builds the permanent overlay image, saves the final pixels to gallery,
  /// and returns the platform gallery path/content URI when available.
  Future<String?> _generateAndSaveGeoTaggedPhoto() async {
    final settings = await _settingsService.load();
    final geoPhoto = _geoPhotoFromLocationInfo(widget.locationInfo);
    final compressedCapturePath = await _imageCompressionService.compressPhotoFile(
      widget.filePath,
    );
    Uint8List? mapBytes;
    try {
      mapBytes = await _googleMapService.fetchThumbnail(
        latitude: geoPhoto.latitude,
        longitude: geoPhoto.longitude,
        zoom: settings.mapZoomLevel.round(),
        mapStyle: settings.mapStyle,
      );
    } catch (error, stackTrace) {
      // Keep saving functional if the static map request fails offline or by API quota.
      await ErrorReporter.recordError(
        error,
        stackTrace,
        reason: 'Static map thumbnail unavailable; continuing with offline fallback.',
      );
      mapBytes = null;
    }

    final finalResult = await _imageOverlayService.composeGeoTaggedImage(
      capturedImagePath: compressedCapturePath,
      geoPhoto: geoPhoto,
      mapThumbnailBytes: mapBytes,
    );

    if (mounted) setState(() => _displayFilePath = finalResult.filePath);
    final savedPath = settings.autoSaveToGallery
        ? await _galleryService.saveImageBytes(
            bytes: finalResult.bytes,
            name: 'GPS_Map_Camera_${DateTime.now().millisecondsSinceEpoch}',
          )
        : finalResult.filePath;
    final appPhoto = AppPhoto(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      filePath: finalResult.filePath,
      locationInfo: widget.locationInfo,
      capturedAt: DateTime.now(),
    );
    await _photoStore.addPhoto(appPhoto);
    await _backupService.queuePhotoForBackup(appPhoto);
    return savedPath;
  }

  GeoPhotoModel _geoPhotoFromLocationInfo(LocationInfo info) {
    return GeoPhotoModel(
      latitude: info.latitude,
      longitude: info.longitude,
      address: info.address,
      capturedAt: DateTime.now(),
      placeName: info.placeName,
      locality: info.locality,
      administrativeArea: info.administrativeArea,
      country: info.country,
      postalCode: info.postalCode,
      altitude: info.altitude,
      speedMetersPerSecond: info.speedMetersPerSecond,
      heading: info.heading,
      accuracy: info.accuracy,
      weatherLabel: 'Weather --',
      compassLabel: 'Compass --',
    );
  }

  void _showSavedBanner() {
    setState(() => _showBanner = true);
    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _showBanner = false);
    });
  }

  void _showSaveError([String? message]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(message ?? 'Failed to save — tap Share to save manually'),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _closeToCamera() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final displayFile = File(_displayFilePath ?? widget.filePath);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _closeToCamera();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.file(displayFile, fit: BoxFit.cover),
            ),
            if (_processing)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.45),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Generating geo-tagged photo...',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 44,
              left: 8,
              child: IconButton(
                onPressed: _closeToCamera,
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 400),
                  offset: _showBanner ? Offset.zero : const Offset(0, -1),
                  child: AnimatedOpacity(
                    opacity: _showBanner ? 1 : 0,
                    duration: const Duration(milliseconds: 400),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Geo-tagged photo saved',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.white,
                height: 80,
                child: Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.85,
                    height: 50,
                    child: FilledButton(
                      onPressed: _processing
                          ? null
                          : () => Share.shareXFiles(
                                [XFile(_displayFilePath ?? widget.filePath)],
                                text:
                                    '📍 ${widget.locationInfo.address}\n📅 ${widget.locationInfo.date} ${widget.locationInfo.time}\nCaptured with GPS Camera',
                              ),
                      child: Text(_processing ? 'Saving...' : 'Share now'),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
