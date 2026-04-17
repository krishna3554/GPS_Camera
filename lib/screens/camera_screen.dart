import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/geo_photo.dart';
import '../providers/geo_photo_provider.dart';
import '../services/location_service.dart';
import '../services/photo_capture_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final _captureService = PhotoCaptureService();
  final _locationService = LocationService();

  CameraController? _controller;
  bool _loading = true;
  String _status = 'Initializing camera...';

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      await _captureService.ensureCameraPermission();
      final cameras = await _captureService.getAvailableCameras();
      _controller = CameraController(cameras.first, ResolutionPreset.medium);
      await _controller!.initialize();
      setState(() {
        _loading = false;
        _status = 'Ready';
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _status = e.toString();
      });
    }
  }

  Future<void> _captureAndSave() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    setState(() => _status = 'Capturing...');

    try {
      final rawPhoto = await _controller!.takePicture();
      final storedPath = await _captureService.moveToAppFolder(rawPhoto);

      final pos = await _locationService.getCurrentPosition();
      final address =
          await _locationService.reverseGeocode(pos.latitude, pos.longitude);

      await _captureService.saveDirectlyToGallery(storedPath);

      final geoPhoto = GeoPhoto(
        imagePath: storedPath,
        latitude: pos.latitude,
        longitude: pos.longitude,
        address: address,
        timestamp: DateTime.now(),
        altitude: pos.altitude,
        accuracy: pos.accuracy,
      );

      if (!mounted) return;
      await context.read<GeoPhotoProvider>().addPhoto(geoPhoto);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved with GPS + gallery copy.')),
      );
      setState(() => _status = 'Ready');
    } catch (e) {
      setState(() => _status = 'Failed: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GPS Camera')),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? Center(child: Text(_status))
                : CameraPreview(_controller!),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(_status),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _captureAndSave,
                  icon: const Icon(Icons.camera),
                  label: const Text('Capture + Save to Gallery'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
