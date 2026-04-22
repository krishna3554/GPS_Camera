import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:gps_camera/models/location_data.dart';
import 'package:gps_camera/providers/photos_provider.dart';
import 'package:gps_camera/services/camera_service.dart';
import 'package:gps_camera/services/geocoding_service.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  final CameraService _cameraService = CameraService();
  final GeocodingService _geocodingService = GeocodingService();

  bool _loading = true;
  bool _capturing = false;
  String? _error;
  LocationData? _overlayLocation;
  String _overlayAddress = '';
  String _overlayCity = '';
  String _overlayCountry = '';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _cameraService.initialize();
      await _refreshOverlay();
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
      final LocationData? location = _overlayLocation ?? await _getLocation();
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

  Future<void> _refreshOverlay() async {
    final LocationData? location = await _getLocation();
    if (location == null || !mounted) return;

    final Map<String, String> addressData = await _geocodingService
        .reverseGeocode(location.latitude, location.longitude);

    if (!mounted) return;
    setState(() {
      _overlayLocation = location;
      _overlayAddress = addressData['address'] ?? '';
      _overlayCity = addressData['city'] ?? '';
      _overlayCountry = addressData['country'] ?? '';
    });
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
            left: 0,
            right: 0,
            bottom: 150,
            child: _CaptureOverlayCard(
              location: _overlayLocation,
              address: _overlayAddress,
              city: _overlayCity,
              country: _overlayCountry,
            ),
          ),
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

class _CaptureOverlayCard extends StatelessWidget {
  const _CaptureOverlayCard({
    required this.location,
    required this.address,
    required this.city,
    required this.country,
  });

  final LocationData? location;
  final String address;
  final String city;
  final String country;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String title = [city, country]
        .where((String value) => value.trim().isNotEmpty)
        .join(', ');
    final String timestamp = DateFormat('EEE, dd MMM yyyy HH:mm:ss')
        .format((location?.timestamp ?? DateTime.now()).toLocal());

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DefaultTextStyle(
        style: theme.textTheme.bodyMedium!
            .copyWith(color: Colors.white, fontWeight: FontWeight.w600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              title.isEmpty ? 'Locating…' : title,
              style: theme.textTheme.titleLarge!
                  .copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              address.isEmpty ? 'Address unavailable' : address,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              location == null
                  ? 'Lat --, Lng --'
                  : 'Lat ${location!.latitude.toStringAsFixed(5)}, '
                      'Lng ${location!.longitude.toStringAsFixed(5)}',
            ),
            const SizedBox(height: 4),
            Text(
              '$timestamp • ${_speed(location)} • ${_heading(location)} • ${_altitude(location)}',
              style: theme.textTheme.bodySmall!.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  String _speed(LocationData? location) {
    if (location?.speed == null) return 'Speed --';
    return 'Speed ${(location!.speed! * 3.6).toStringAsFixed(1)} km/h';
  }

  String _heading(LocationData? location) {
    if (location?.heading == null) return 'Heading --';
    return 'Heading ${location!.heading!.toStringAsFixed(0)}°';
  }

  String _altitude(LocationData? location) {
    if (location?.altitude == null) return 'Alt --';
    return 'Alt ${location!.altitude!.toStringAsFixed(1)} m';
  }
}
