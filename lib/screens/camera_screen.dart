import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gps_camera/models/location_data.dart';
import 'package:gps_camera/providers/photos_provider.dart';
import 'package:gps_camera/services/camera_service.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  final CameraService _cameraService = CameraService();

  bool _loading = true;
  bool _capturing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _cameraService.initialize();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<LocationData?> _getLocation() async {
    final LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      final LocationPermission requested = await Geolocator.requestPermission();
      if (requested == LocationPermission.denied ||
          requested == LocationPermission.deniedForever) {
        return null;
      }
    }

    final Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return LocationData(
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      accuracy: position.accuracy,
      heading: position.heading,
      speed: position.speed,
      timestamp: position.timestamp.toUtc(),
    );
  }

  Future<void> _onCapturePressed() async {
    if (_capturing) return;

    setState(() {
      _capturing = true;
    });

    try {
      final LocationData? location = await _getLocation();
      if (location == null) {
        _showSnack('Location permission is required.');
        return;
      }

      final photo = await _cameraService.captureAndTag(location);
      if (photo == null) {
        _showSnack('Failed to capture photo.');
        return;
      }

      await ref.read(photosProvider.notifier).loadAll();
      _showSnack('Captured and saved with GPS tag.');
    } catch (e) {
      _showSnack('Capture error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _capturing = false;
        });
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(body: Center(child: Text(_error!)));
    }

    final CameraController? controller = _cameraService.controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Scaffold(body: Center(child: Text('Camera not initialized.')));
    }

    return Scaffold(
      body: Stack(
        children: <Widget>[
          Positioned.fill(child: CameraPreview(controller)),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton.large(
                onPressed: _capturing ? null : _onCapturePressed,
                child: _capturing
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : const Icon(Icons.camera_alt),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
